-- Vérifier si les tables timesheet existent déjà
SELECT 
  table_name,
  'EXISTS' as status
FROM information_schema.tables
WHERE table_schema = 'public'
  AND (table_name LIKE '%timesheet%' OR table_name LIKE '%partner_rate%' OR table_name LIKE '%operator%');

-- Vérifier la structure de timesheet_entries si elle existe
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'timesheet_entries'
ORDER BY ordinal_position;

-- Vérifier les vues existantes
SELECT 
  viewname,
  'EXISTS' as status
FROM pg_views
WHERE schemaname = 'public'
  AND viewname LIKE '%timesheet%';



