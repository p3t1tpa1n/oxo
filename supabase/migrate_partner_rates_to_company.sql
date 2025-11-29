-- ============================================================================
-- MIGRATION : partner_rates de clients vers company
-- ============================================================================
-- Ce script migre la table partner_rates pour utiliser company_id au lieu de client_id

-- 1. Ajouter la colonne company_id (BIGINT) à la table partner_rates
-- ============================================================================
ALTER TABLE partner_rates 
ADD COLUMN IF NOT EXISTS company_id BIGINT;

-- 2. Migrer les données existantes (si nécessaire)
-- ============================================================================
-- Si vous avez des données existantes liées à clients, vous devrez les mapper manuellement
-- ou créer une relation clients -> company. Pour l'instant, on laisse company_id NULL
-- pour les anciennes données.

-- 3. Supprimer l'ancienne contrainte NOT NULL et index sur client_id
-- ============================================================================
-- D'abord, permettre NULL sur client_id pour la transition
ALTER TABLE partner_rates 
ALTER COLUMN client_id DROP NOT NULL;

-- Supprimer la contrainte de clé étrangère
ALTER TABLE partner_rates 
DROP CONSTRAINT IF EXISTS partner_rates_client_id_fkey;

DROP INDEX IF EXISTS idx_partner_rates_client;

-- 4. Ajouter la nouvelle contrainte et index sur company_id
-- ============================================================================
ALTER TABLE partner_rates 
ADD CONSTRAINT partner_rates_company_id_fkey 
FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_partner_rates_company ON partner_rates(company_id);

-- 5. Modifier la contrainte UNIQUE pour utiliser company_id au lieu de client_id
-- ============================================================================
ALTER TABLE partner_rates 
DROP CONSTRAINT IF EXISTS partner_rates_partner_id_client_id_key;

ALTER TABLE partner_rates 
ADD CONSTRAINT partner_rates_partner_id_company_id_key 
UNIQUE(partner_id, company_id);

-- 6. Supprimer l'ancienne colonne client_id (optionnel - à faire après vérification)
-- ============================================================================
-- ATTENTION: Ne décommentez cette ligne que si vous êtes sûr que toutes les données
-- ont été migrées vers company_id
-- ALTER TABLE partner_rates DROP COLUMN IF EXISTS client_id;

-- 7. Supprimer toutes les versions existantes de get_partner_daily_rate
-- ============================================================================
DROP FUNCTION IF EXISTS get_partner_daily_rate(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS get_partner_daily_rate(UUID, BIGINT) CASCADE;
DROP FUNCTION IF EXISTS get_partner_daily_rate CASCADE;

-- 8. Créer la nouvelle fonction get_partner_daily_rate pour utiliser company_id
-- ============================================================================
CREATE OR REPLACE FUNCTION get_partner_daily_rate(
  p_partner_id UUID,
  p_company_id BIGINT
)
RETURNS NUMERIC AS $$
DECLARE
  v_rate NUMERIC;
BEGIN
  SELECT daily_rate INTO v_rate
  FROM partner_rates
  WHERE partner_id = p_partner_id
    AND company_id = p_company_id;
  
  RETURN COALESCE(v_rate, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_partner_daily_rate(UUID, BIGINT) IS 'Retourne le tarif journalier d''un partenaire pour une company donnée';

-- 9. Mettre à jour la vue pour afficher les companies au lieu des clients
-- ============================================================================
-- Note: Cette vue peut nécessiter des ajustements selon votre structure
CREATE OR REPLACE VIEW partner_rates_detailed AS
SELECT 
  pr.id,
  pr.partner_id,
  pr.company_id,
  pr.daily_rate,
  pr.created_at,
  pr.updated_at,
  u.email as partner_email,
  COALESCE(p.first_name || ' ' || p.last_name, u.email) as partner_name,
  c.name as company_name
FROM partner_rates pr
LEFT JOIN auth.users u ON pr.partner_id = u.id
LEFT JOIN profiles p ON u.id = p.user_id
LEFT JOIN company c ON pr.company_id = c.id;

COMMENT ON VIEW partner_rates_detailed IS 'Vue enrichie des tarifs avec noms partenaire et company';

