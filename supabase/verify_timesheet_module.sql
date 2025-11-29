-- ============================================================================
-- Script de vérification du module OXO TIME SHEETS
-- ============================================================================
-- Exécutez ce script APRÈS avoir exécuté create_oxo_timesheets_module.sql
-- pour vérifier que tout a été créé correctement.
-- ============================================================================

-- 1. Vérifier les tables
SELECT 
  'Tables créées' as verification,
  COUNT(*) as count,
  STRING_AGG(tablename, ', ') as tables
FROM pg_tables 
WHERE schemaname = 'public' 
  AND (tablename LIKE '%partner%' OR tablename LIKE '%timesheet%')
  AND tablename IN ('partner_rates', 'partner_client_permissions', 'timesheet_entries');

-- 2. Vérifier les vues
SELECT 
  'Vues créées' as verification,
  COUNT(*) as count,
  STRING_AGG(viewname, ', ') as views
FROM pg_views 
WHERE schemaname = 'public' 
  AND viewname = 'timesheet_entries_detailed';

-- 3. Vérifier les fonctions
SELECT 
  'Fonctions créées' as verification,
  COUNT(*) as count,
  STRING_AGG(routine_name, ', ') as functions
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN (
    'get_partner_daily_rate',
    'check_partner_client_access',
    'get_authorized_clients_for_partner',
    'generate_month_calendar',
    'get_partner_monthly_stats',
    'get_timesheet_report_by_client',
    'get_timesheet_report_by_partner'
  );

-- 4. Vérifier les index
SELECT 
  'Index créés' as verification,
  COUNT(*) as count,
  STRING_AGG(indexname, ', ') as indexes
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND (indexname LIKE '%partner%' OR indexname LIKE '%timesheet%');

-- 5. Vérifier les politiques RLS
SELECT 
  'Politiques RLS' as verification,
  tablename,
  policyname,
  cmd as command,
  roles
FROM pg_policies 
WHERE schemaname = 'public' 
  AND tablename IN ('partner_rates', 'partner_client_permissions', 'timesheet_entries')
ORDER BY tablename, policyname;

-- 6. Vérifier que RLS est activé
SELECT 
  'RLS activé' as verification,
  tablename,
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('partner_rates', 'partner_client_permissions', 'timesheet_entries');

-- 7. Vérifier les triggers
SELECT 
  'Triggers créés' as verification,
  COUNT(*) as count,
  STRING_AGG(trigger_name, ', ') as triggers
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
  AND event_object_table IN ('partner_rates', 'partner_client_permissions', 'timesheet_entries');

-- 8. Tester une fonction simple
SELECT 
  'Test fonction generate_month_calendar' as verification,
  COUNT(*) as days_in_november_2025
FROM generate_month_calendar(2025, 11);

-- ============================================================================
-- Résultat attendu :
-- ============================================================================
-- Tables créées: 3 (partner_rates, partner_client_permissions, timesheet_entries)
-- Vues créées: 1 (timesheet_entries_detailed)
-- Fonctions créées: 7
-- Index créés: 6+
-- Politiques RLS: 6+ (2 par table minimum)
-- RLS activé: true pour les 3 tables
-- Triggers créés: 3 (1 par table)
-- Test fonction: 30 (jours en novembre 2025)
-- ============================================================================



