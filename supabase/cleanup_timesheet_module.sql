-- ============================================================================
-- NETTOYAGE DU MODULE TIMESHEET
-- ============================================================================
-- Exécutez ce script AVANT create_oxo_timesheets_module.sql
-- pour supprimer les anciennes versions des tables/vues/fonctions
-- ============================================================================

-- 1. Supprimer la vue (doit être supprimée avant les tables)
-- ============================================================================
DROP VIEW IF EXISTS timesheet_entries_detailed CASCADE;

-- 2. Supprimer les anciennes fonctions (avec operator)
-- ============================================================================
DROP FUNCTION IF EXISTS get_operator_daily_rate(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS check_operator_client_access(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS get_authorized_clients_for_operator(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_operator_monthly_stats(UUID, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_timesheet_report_by_operator(INTEGER, INTEGER, UUID) CASCADE;

-- 3. Supprimer les nouvelles fonctions (avec partner)
-- ============================================================================
DROP FUNCTION IF EXISTS get_partner_daily_rate(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS check_partner_client_access(UUID, UUID) CASCADE;
DROP FUNCTION IF EXISTS get_authorized_clients_for_partner(UUID) CASCADE;
DROP FUNCTION IF EXISTS generate_month_calendar(INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_partner_monthly_stats(UUID, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS get_timesheet_report_by_client(INTEGER, INTEGER, UUID) CASCADE;
DROP FUNCTION IF EXISTS get_timesheet_report_by_partner(INTEGER, INTEGER, UUID) CASCADE;

-- 4. Supprimer les tables (dans l'ordre inverse des dépendances)
-- ============================================================================
DROP TABLE IF EXISTS timesheet_entries CASCADE;
DROP TABLE IF EXISTS partner_client_permissions CASCADE;
DROP TABLE IF EXISTS partner_rates CASCADE;

-- 5. Supprimer les anciennes tables (avec operator si elles existent)
-- ============================================================================
DROP TABLE IF EXISTS operator_client_permissions CASCADE;
DROP TABLE IF EXISTS operator_rates CASCADE;

-- ============================================================================
-- VÉRIFICATION
-- ============================================================================
-- Vérifier que tout est supprimé
SELECT 
  'Tables restantes' as check_type,
  COUNT(*) as count
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%timesheet%' 
    OR table_name LIKE '%partner_rate%' 
    OR table_name LIKE '%operator%')

UNION ALL

SELECT 
  'Vues restantes' as check_type,
  COUNT(*) as count
FROM pg_views
WHERE schemaname = 'public'
  AND viewname LIKE '%timesheet%'

UNION ALL

SELECT 
  'Fonctions restantes' as check_type,
  COUNT(*) as count
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND (routine_name LIKE '%timesheet%' 
    OR routine_name LIKE '%partner%' 
    OR routine_name LIKE '%operator%');

-- Si tous les counts sont à 0, vous pouvez exécuter create_oxo_timesheets_module.sql



