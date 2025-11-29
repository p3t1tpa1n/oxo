-- ============================================================================
-- 🧹 NETTOYAGE PRÉALABLE - Avant la refonte
-- ============================================================================
-- Ce script supprime les vues et colonnes existantes qui pourraient causer
-- des conflits avant d'exécuter refonte_clients_hierarchie.sql
-- ============================================================================

-- Supprimer les vues qui dépendent de company_id
DROP VIEW IF EXISTS mission_with_context CASCADE;
DROP VIEW IF EXISTS timesheet_entry_with_context CASCADE;
DROP VIEW IF EXISTS company_with_group CASCADE;

-- Supprimer les fonctions qui pourraient utiliser ces vues
DROP FUNCTION IF EXISTS get_missions_by_partner(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_available_missions_for_timesheet(UUID, DATE) CASCADE;
DROP FUNCTION IF EXISTS get_timesheet_report_by_group(INT, INT, INT) CASCADE;

-- Note: On ne supprime PAS la colonne company_id de missions ici
-- car le script principal va gérer sa conversion de type
-- Si vous avez une colonne company_id en UUID qui pose problème,
-- vous pouvez la supprimer manuellement avec:
-- ALTER TABLE missions DROP COLUMN IF EXISTS company_id;

-- Supprimer les index liés (seront recréés par le script principal)
DROP INDEX IF EXISTS idx_missions_company_id;

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Nettoyage préalable terminé. Vous pouvez maintenant exécuter refonte_clients_hierarchie.sql';
END $$;






