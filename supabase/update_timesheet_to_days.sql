-- ============================================================================
-- MODIFICATION : Heures → Journées/Demi-journées
-- ============================================================================
-- Ce script modifie le module timesheet pour utiliser des journées
-- au lieu d'heures (0.5 = demi-journée, 1 = journée complète)
-- ============================================================================

-- 1. Supprimer la vue existante (dépend de la colonne hours)
-- ============================================================================
DROP VIEW IF EXISTS timesheet_entries_detailed CASCADE;

-- 2. Modifier la table timesheet_entries
-- ============================================================================

-- Renommer la colonne hours en days
ALTER TABLE timesheet_entries 
  RENAME COLUMN hours TO days;

-- Modifier la contrainte pour accepter 0.5 ou 1
ALTER TABLE timesheet_entries 
  DROP CONSTRAINT IF EXISTS timesheet_entries_hours_check;

ALTER TABLE timesheet_entries 
  ADD CONSTRAINT timesheet_entries_days_check 
  CHECK (days IN (0.5, 1.0));

-- Modifier le commentaire
COMMENT ON COLUMN timesheet_entries.days IS 'Nombre de jours travaillés (0.5 = demi-journée, 1.0 = journée complète)';

-- 3. Recréer la vue avec la nouvelle colonne
-- ============================================================================
CREATE OR REPLACE VIEW timesheet_entries_detailed AS
SELECT 
  te.id,
  te.partner_id,
  u.email as partner_email,
  p.first_name || ' ' || p.last_name as partner_name,
  te.client_id,
  c.name as client_name,
  te.entry_date,
  CASE EXTRACT(DOW FROM te.entry_date)
    WHEN 0 THEN 'Dimanche'
    WHEN 1 THEN 'Lundi'
    WHEN 2 THEN 'Mardi'
    WHEN 3 THEN 'Mercredi'
    WHEN 4 THEN 'Jeudi'
    WHEN 5 THEN 'Vendredi'
    WHEN 6 THEN 'Samedi'
  END as day_name,
  te.days,
  te.comment,
  te.daily_rate,
  te.amount,
  te.is_weekend,
  te.status,
  te.company_id,
  te.created_at,
  te.updated_at
FROM timesheet_entries te
LEFT JOIN auth.users u ON te.partner_id = u.id
LEFT JOIN profiles p ON te.partner_id = p.user_id
LEFT JOIN clients c ON te.client_id = c.id;

-- Commentaire sur la vue
COMMENT ON VIEW timesheet_entries_detailed IS 'Vue détaillée des saisies avec jours (0.5 ou 1.0)';

-- 4. Supprimer et recréer la fonction de statistiques mensuelles
-- ============================================================================

-- Supprimer toutes les versions de la fonction
DROP FUNCTION IF EXISTS get_partner_monthly_stats(UUID, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_partner_monthly_stats CASCADE;

-- Recréer avec les nouveaux types
CREATE OR REPLACE FUNCTION get_partner_monthly_stats(
  p_partner_id UUID,
  p_year INTEGER,
  p_month INTEGER
)
RETURNS TABLE (
  total_days NUMERIC,
  total_amount NUMERIC,
  days_submitted NUMERIC,
  days_approved NUMERIC,
  days_draft NUMERIC
) LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(te.days), 0) as total_days,
    COALESCE(SUM(te.amount), 0) as total_amount,
    COALESCE(SUM(CASE WHEN te.status = 'submitted' THEN te.days ELSE 0 END), 0) as days_submitted,
    COALESCE(SUM(CASE WHEN te.status = 'approved' THEN te.days ELSE 0 END), 0) as days_approved,
    COALESCE(SUM(CASE WHEN te.status = 'draft' THEN te.days ELSE 0 END), 0) as days_draft
  FROM timesheet_entries te
  WHERE te.partner_id = p_partner_id
    AND EXTRACT(YEAR FROM te.entry_date) = p_year
    AND EXTRACT(MONTH FROM te.entry_date) = p_month;
END;
$$;

COMMENT ON FUNCTION get_partner_monthly_stats IS 'Statistiques mensuelles en jours pour un partenaire';

-- 5. Supprimer et recréer la fonction de rapport par client
-- ============================================================================

-- Supprimer toutes les versions de la fonction
DROP FUNCTION IF EXISTS get_timesheet_report_by_client(INTEGER, INTEGER, BIGINT) CASCADE;
DROP FUNCTION IF EXISTS get_timesheet_report_by_client(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_timesheet_report_by_client CASCADE;

-- Recréer avec les nouveaux types
CREATE OR REPLACE FUNCTION get_timesheet_report_by_client(
  p_year INTEGER,
  p_month INTEGER,
  p_company_id BIGINT DEFAULT NULL
)
RETURNS TABLE (
  client_id UUID,
  client_name TEXT,
  total_days NUMERIC,
  total_amount NUMERIC,
  partner_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as client_id,
    c.name as client_name,
    COALESCE(SUM(te.days), 0) as total_days,
    COALESCE(SUM(te.amount), 0) as total_amount,
    COUNT(DISTINCT te.partner_id) as partner_count
  FROM clients c
  LEFT JOIN timesheet_entries te ON c.id = te.client_id
    AND EXTRACT(YEAR FROM te.entry_date) = p_year
    AND EXTRACT(MONTH FROM te.entry_date) = p_month
    AND (p_company_id IS NULL OR te.company_id = p_company_id)
  GROUP BY c.id, c.name
  HAVING SUM(te.days) > 0
  ORDER BY total_amount DESC;
END;
$$;

COMMENT ON FUNCTION get_timesheet_report_by_client IS 'Rapport mensuel par client en jours';

-- 6. Supprimer et recréer la fonction de rapport par partenaire
-- ============================================================================

-- Supprimer toutes les versions de la fonction
DROP FUNCTION IF EXISTS get_timesheet_report_by_partner(INTEGER, INTEGER, BIGINT) CASCADE;
DROP FUNCTION IF EXISTS get_timesheet_report_by_partner(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_timesheet_report_by_partner CASCADE;

-- Recréer avec les nouveaux types
CREATE OR REPLACE FUNCTION get_timesheet_report_by_partner(
  p_year INTEGER,
  p_month INTEGER,
  p_company_id BIGINT DEFAULT NULL
)
RETURNS TABLE (
  partner_id UUID,
  partner_name TEXT,
  partner_email TEXT,
  total_days NUMERIC,
  total_amount NUMERIC,
  client_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id as partner_id,
    COALESCE(p.first_name || ' ' || p.last_name, u.email)::TEXT as partner_name,
    u.email::TEXT as partner_email,
    COALESCE(SUM(te.days), 0) as total_days,
    COALESCE(SUM(te.amount), 0) as total_amount,
    COUNT(DISTINCT te.client_id) as client_count
  FROM auth.users u
  LEFT JOIN profiles p ON u.id = p.user_id
  LEFT JOIN timesheet_entries te ON u.id = te.partner_id
    AND EXTRACT(YEAR FROM te.entry_date) = p_year
    AND EXTRACT(MONTH FROM te.entry_date) = p_month
    AND (p_company_id IS NULL OR te.company_id = p_company_id)
  GROUP BY u.id, p.first_name, p.last_name, u.email
  HAVING SUM(te.days) > 0
  ORDER BY total_amount DESC;
END;
$$;

COMMENT ON FUNCTION get_timesheet_report_by_partner IS 'Rapport mensuel par partenaire en jours';

-- ============================================================================
-- VÉRIFICATION
-- ============================================================================

-- Vérifier la structure modifiée
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'timesheet_entries'
  AND column_name = 'days';

-- Vérifier les contraintes
SELECT 
  constraint_name,
  check_clause
FROM information_schema.check_constraints
WHERE constraint_schema = 'public'
  AND constraint_name LIKE '%timesheet_entries%';

-- Message de succès
DO $$
BEGIN
  RAISE NOTICE '✅ Module timesheet modifié avec succès !';
  RAISE NOTICE '📊 Nouvelle unité : Jours (0.5 ou 1.0)';
  RAISE NOTICE '🔄 Vue et fonctions mises à jour';
END $$;

