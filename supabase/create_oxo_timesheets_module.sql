-- ============================================================================
-- MODULE OXO TIME SHEETS - Schéma de base de données complet
-- ============================================================================
-- Ce script crée toutes les tables nécessaires pour le module de gestion
-- du temps de travail, des tarifs et des permissions.
-- 
-- NOTE: company_id utilise BIGINT pour correspondre à votre table companies
-- ============================================================================

-- 1. Table des tarifs journaliers par partenaire et client
-- ============================================================================
CREATE TABLE IF NOT EXISTS partner_rates (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  daily_rate NUMERIC(10, 2) NOT NULL CHECK (daily_rate >= 0),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(partner_id, client_id)
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_partner_rates_partner ON partner_rates(partner_id);
CREATE INDEX IF NOT EXISTS idx_partner_rates_client ON partner_rates(client_id);

-- Commentaires
COMMENT ON TABLE partner_rates IS 'Tarifs journaliers par partenaire et client (équivalent ENTRÉES TARIFS)';
COMMENT ON COLUMN partner_rates.daily_rate IS 'Tarif journalier en euros';

-- ============================================================================
-- 2. Table des permissions partenaire-client
-- ============================================================================
CREATE TABLE IF NOT EXISTS partner_client_permissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  allowed BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(partner_id, client_id)
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_partner_client_permissions_partner ON partner_client_permissions(partner_id);
CREATE INDEX IF NOT EXISTS idx_partner_client_permissions_client ON partner_client_permissions(client_id);

-- Commentaires
COMMENT ON TABLE partner_client_permissions IS 'Permissions d''accès partenaire-client (équivalent CALCUL 2)';
COMMENT ON COLUMN partner_client_permissions.allowed IS 'TRUE si le partenaire peut travailler pour ce client';

-- ============================================================================
-- 3. Table des saisies de temps (time entries)
-- ============================================================================
CREATE TABLE IF NOT EXISTS timesheet_entries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
  entry_date DATE NOT NULL,
  hours NUMERIC(4, 2) NOT NULL CHECK (hours > 0 AND hours <= 24),
  comment TEXT,
  daily_rate NUMERIC(10, 2) NOT NULL,
  amount NUMERIC(10, 2) GENERATED ALWAYS AS (hours * daily_rate) STORED,
  is_weekend BOOLEAN DEFAULT false,
  status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'approved', 'rejected')),
  company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(partner_id, entry_date, client_id)
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_partner ON timesheet_entries(partner_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_client ON timesheet_entries(client_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_date ON timesheet_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_company ON timesheet_entries(company_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_status ON timesheet_entries(status);

-- Commentaires
COMMENT ON TABLE timesheet_entries IS 'Saisies de temps de travail (équivalent Time sheet)';
COMMENT ON COLUMN timesheet_entries.hours IS 'Nombre d''heures travaillées (max 24h/jour)';
COMMENT ON COLUMN timesheet_entries.amount IS 'Montant calculé automatiquement (heures × tarif)';
COMMENT ON COLUMN timesheet_entries.is_weekend IS 'TRUE si le jour est un week-end';
COMMENT ON COLUMN timesheet_entries.status IS 'Statut de la saisie (brouillon, soumis, approuvé, rejeté)';

-- ============================================================================
-- 4. Vue pour faciliter les requêtes avec toutes les informations
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
  te.hours,
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

COMMENT ON VIEW timesheet_entries_detailed IS 'Vue enrichie des saisies de temps avec noms partenaire/client';

-- ============================================================================
-- 5. Fonction pour obtenir le tarif journalier d'un partenaire pour un client
-- ============================================================================
CREATE OR REPLACE FUNCTION get_partner_daily_rate(
  p_partner_id UUID,
  p_client_id UUID
)
RETURNS NUMERIC AS $$
DECLARE
  v_rate NUMERIC;
BEGIN
  SELECT daily_rate INTO v_rate
  FROM partner_rates
  WHERE partner_id = p_partner_id
    AND client_id = p_client_id;
  
  RETURN COALESCE(v_rate, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_partner_daily_rate IS 'Retourne le tarif journalier d''un partenaire pour un client donné';

-- ============================================================================
-- 6. Fonction pour vérifier si un partenaire a accès à un client
-- ============================================================================
CREATE OR REPLACE FUNCTION check_partner_client_access(
  p_partner_id UUID,
  p_client_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
  v_allowed BOOLEAN;
BEGIN
  SELECT allowed INTO v_allowed
  FROM partner_client_permissions
  WHERE partner_id = p_partner_id
    AND client_id = p_client_id;
  
  -- Si aucune permission n'est définie, on autorise par défaut
  RETURN COALESCE(v_allowed, true);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION check_partner_client_access IS 'Vérifie si un partenaire a accès à un client';

-- ============================================================================
-- 7. Fonction pour obtenir les clients autorisés pour un partenaire
-- ============================================================================
CREATE OR REPLACE FUNCTION get_authorized_clients_for_partner(
  p_partner_id UUID
)
RETURNS TABLE (
  client_id UUID,
  client_name TEXT,
  daily_rate NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id,
    c.name,
    COALESCE(or_table.daily_rate, 0) as daily_rate
  FROM clients c
  LEFT JOIN partner_client_permissions ocp 
    ON c.id = ocp.client_id AND ocp.partner_id = p_partner_id
  LEFT JOIN partner_rates or_table 
    ON c.id = or_table.client_id AND or_table.partner_id = p_partner_id
  WHERE COALESCE(ocp.allowed, true) = true
  ORDER BY c.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_authorized_clients_for_partner IS 'Retourne la liste des clients autorisés pour un partenaire avec leurs tarifs';

-- ============================================================================
-- 8. Fonction pour générer le calendrier d'un mois
-- ============================================================================
CREATE OR REPLACE FUNCTION generate_month_calendar(
  p_year INTEGER,
  p_month INTEGER
)
RETURNS TABLE (
  entry_date DATE,
  day_name TEXT,
  day_number INTEGER,
  is_weekend BOOLEAN,
  week_number INTEGER
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    d::DATE as entry_date,
    CASE EXTRACT(DOW FROM d)
      WHEN 0 THEN 'Dimanche'
      WHEN 1 THEN 'Lundi'
      WHEN 2 THEN 'Mardi'
      WHEN 3 THEN 'Mercredi'
      WHEN 4 THEN 'Jeudi'
      WHEN 5 THEN 'Vendredi'
      WHEN 6 THEN 'Samedi'
    END as day_name,
    EXTRACT(DAY FROM d)::INTEGER as day_number,
    EXTRACT(DOW FROM d) IN (0, 6) as is_weekend,
    EXTRACT(WEEK FROM d)::INTEGER as week_number
  FROM generate_series(
    make_date(p_year, p_month, 1),
    (make_date(p_year, p_month, 1) + INTERVAL '1 month - 1 day')::DATE,
    '1 day'::INTERVAL
  ) d
  ORDER BY d;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION generate_month_calendar IS 'Génère le calendrier complet d''un mois (équivalent Feuil1)';

-- ============================================================================
-- 9. Fonction pour obtenir les statistiques mensuelles d'un partenaire
-- ============================================================================
CREATE OR REPLACE FUNCTION get_partner_monthly_stats(
  p_partner_id UUID,
  p_year INTEGER,
  p_month INTEGER
)
RETURNS TABLE (
  total_hours NUMERIC,
  total_amount NUMERIC,
  total_days INTEGER,
  total_entries INTEGER,
  avg_hours_per_day NUMERIC
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(SUM(hours), 0) as total_hours,
    COALESCE(SUM(amount), 0) as total_amount,
    COUNT(DISTINCT entry_date)::INTEGER as total_days,
    COUNT(*)::INTEGER as total_entries,
    CASE 
      WHEN COUNT(DISTINCT entry_date) > 0 
      THEN ROUND(SUM(hours) / COUNT(DISTINCT entry_date), 2)
      ELSE 0 
    END as avg_hours_per_day
  FROM timesheet_entries
  WHERE partner_id = p_partner_id
    AND EXTRACT(YEAR FROM entry_date) = p_year
    AND EXTRACT(MONTH FROM entry_date) = p_month;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_partner_monthly_stats IS 'Retourne les statistiques mensuelles d''un partenaire';

-- ============================================================================
-- 10. Fonction pour obtenir le rapport consolidé par client
-- ============================================================================
CREATE OR REPLACE FUNCTION get_timesheet_report_by_client(
  p_year INTEGER,
  p_month INTEGER,
  p_company_id UUID DEFAULT NULL
)
RETURNS TABLE (
  client_id UUID,
  client_name TEXT,
  total_hours NUMERIC,
  total_amount NUMERIC,
    partner_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as client_id,
    c.name as client_name,
    COALESCE(SUM(te.hours), 0) as total_hours,
    COALESCE(SUM(te.amount), 0) as total_amount,
    COUNT(DISTINCT te.partner_id) as partner_count
  FROM clients c
  LEFT JOIN timesheet_entries te ON c.id = te.client_id
    AND EXTRACT(YEAR FROM te.entry_date) = p_year
    AND EXTRACT(MONTH FROM te.entry_date) = p_month
    AND (p_company_id IS NULL OR te.company_id = p_company_id)
  GROUP BY c.id, c.name
  HAVING SUM(te.hours) > 0
  ORDER BY total_amount DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_timesheet_report_by_client IS 'Rapport consolidé par client pour un mois donné';

-- ============================================================================
-- 11. Fonction pour obtenir le rapport consolidé par partenaire
-- ============================================================================
CREATE OR REPLACE FUNCTION get_timesheet_report_by_partner(
  p_year INTEGER,
  p_month INTEGER,
  p_company_id UUID DEFAULT NULL
)
RETURNS TABLE (
  partner_id UUID,
  partner_name TEXT,
  partner_email TEXT,
  total_hours NUMERIC,
  total_amount NUMERIC,
  client_count BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id as partner_id,
    COALESCE(p.first_name || ' ' || p.last_name, u.email) as partner_name,
    u.email as partner_email,
    COALESCE(SUM(te.hours), 0) as total_hours,
    COALESCE(SUM(te.amount), 0) as total_amount,
    COUNT(DISTINCT te.client_id) as client_count
  FROM auth.users u
  LEFT JOIN profiles p ON u.id = p.user_id
  LEFT JOIN timesheet_entries te ON u.id = te.partner_id
    AND EXTRACT(YEAR FROM te.entry_date) = p_year
    AND EXTRACT(MONTH FROM te.entry_date) = p_month
    AND (p_company_id IS NULL OR te.company_id = p_company_id)
  GROUP BY u.id, p.first_name, p.last_name, u.email
  HAVING SUM(te.hours) > 0
  ORDER BY total_amount DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_timesheet_report_by_partner IS 'Rapport consolidé par partenaire pour un mois donné';

-- ============================================================================
-- 12. Trigger pour mettre à jour updated_at automatiquement
-- ============================================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Appliquer le trigger aux tables
DROP TRIGGER IF EXISTS update_partner_rates_updated_at ON partner_rates;
CREATE TRIGGER update_partner_rates_updated_at
  BEFORE UPDATE ON partner_rates
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_partner_client_permissions_updated_at ON partner_client_permissions;
CREATE TRIGGER update_partner_client_permissions_updated_at
  BEFORE UPDATE ON partner_client_permissions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_timesheet_entries_updated_at ON timesheet_entries;
CREATE TRIGGER update_timesheet_entries_updated_at
  BEFORE UPDATE ON timesheet_entries
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 13. Politiques RLS (Row Level Security)
-- ============================================================================

-- Activer RLS sur toutes les tables
ALTER TABLE partner_rates ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_client_permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE timesheet_entries ENABLE ROW LEVEL SECURITY;

-- Politiques pour partner_rates
DROP POLICY IF EXISTS "Associés peuvent tout voir sur partner_rates" ON partner_rates;
CREATE POLICY "Associés peuvent tout voir sur partner_rates"
  ON partner_rates FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'associe'
    )
  );

DROP POLICY IF EXISTS "Associés peuvent tout modifier sur partner_rates" ON partner_rates;
CREATE POLICY "Associés peuvent tout modifier sur partner_rates"
  ON partner_rates FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'associe'
    )
  );

DROP POLICY IF EXISTS "Partenaires peuvent voir leurs propres tarifs" ON partner_rates;
CREATE POLICY "Partenaires peuvent voir leurs propres tarifs"
  ON partner_rates FOR SELECT
  TO authenticated
  USING (partner_id = auth.uid());

-- Politiques pour partner_client_permissions
DROP POLICY IF EXISTS "Associés peuvent tout voir sur permissions" ON partner_client_permissions;
CREATE POLICY "Associés peuvent tout voir sur permissions"
  ON partner_client_permissions FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'associe'
    )
  );

DROP POLICY IF EXISTS "Associés peuvent tout modifier sur permissions" ON partner_client_permissions;
CREATE POLICY "Associés peuvent tout modifier sur permissions"
  ON partner_client_permissions FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'associe'
    )
  );

DROP POLICY IF EXISTS "Partenaires peuvent voir leurs propres permissions" ON partner_client_permissions;
CREATE POLICY "Partenaires peuvent voir leurs propres permissions"
  ON partner_client_permissions FOR SELECT
  TO authenticated
  USING (partner_id = auth.uid());

-- Politiques pour timesheet_entries
DROP POLICY IF EXISTS "Associés peuvent tout voir sur timesheet_entries" ON timesheet_entries;
CREATE POLICY "Associés peuvent tout voir sur timesheet_entries"
  ON timesheet_entries FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'associe'
    )
  );

DROP POLICY IF EXISTS "Associés peuvent tout modifier sur timesheet_entries" ON timesheet_entries;
CREATE POLICY "Associés peuvent tout modifier sur timesheet_entries"
  ON timesheet_entries FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'associe'
    )
  );

DROP POLICY IF EXISTS "Partenaires peuvent voir leurs propres saisies" ON timesheet_entries;
CREATE POLICY "Partenaires peuvent voir leurs propres saisies"
  ON timesheet_entries FOR SELECT
  TO authenticated
  USING (partner_id = auth.uid());

DROP POLICY IF EXISTS "Partenaires peuvent créer leurs propres saisies" ON timesheet_entries;
CREATE POLICY "Partenaires peuvent créer leurs propres saisies"
  ON timesheet_entries FOR INSERT
  TO authenticated
  WITH CHECK (partner_id = auth.uid());

DROP POLICY IF EXISTS "Partenaires peuvent modifier leurs propres saisies en brouillon" ON timesheet_entries;
CREATE POLICY "Partenaires peuvent modifier leurs propres saisies en brouillon"
  ON timesheet_entries FOR UPDATE
  TO authenticated
  USING (partner_id = auth.uid() AND status = 'draft')
  WITH CHECK (partner_id = auth.uid());

DROP POLICY IF EXISTS "Partenaires peuvent supprimer leurs propres saisies en brouillon" ON timesheet_entries;
CREATE POLICY "Partenaires peuvent supprimer leurs propres saisies en brouillon"
  ON timesheet_entries FOR DELETE
  TO authenticated
  USING (partner_id = auth.uid() AND status = 'draft');

-- ============================================================================
-- 14. Données de test (optionnel - à commenter en production)
-- ============================================================================

-- Exemple de tarifs
-- INSERT INTO partner_rates (partner_id, client_id, daily_rate) VALUES
-- ('uuid-operateur-1', 'uuid-client-1', 500.00),
-- ('uuid-operateur-1', 'uuid-client-2', 450.00);

-- Exemple de permissions
-- INSERT INTO partner_client_permissions (partner_id, client_id, allowed) VALUES
-- ('uuid-operateur-1', 'uuid-client-1', true),
-- ('uuid-operateur-1', 'uuid-client-2', true),
-- ('uuid-operateur-2', 'uuid-client-1', false);

-- ============================================================================
-- FIN DU SCRIPT
-- ============================================================================

-- Afficher un message de confirmation
DO $$
BEGIN
  RAISE NOTICE '✅ Module OXO TIME SHEETS créé avec succès !';
  RAISE NOTICE '📊 Tables créées : partner_rates, partner_client_permissions, timesheet_entries';
  RAISE NOTICE '🔧 Fonctions créées : 8 fonctions utilitaires';
  RAISE NOTICE '🔒 Politiques RLS activées pour tous les rôles';
END $$;

