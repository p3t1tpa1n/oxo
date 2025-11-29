-- Vérifier la structure de la table companies
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'companies'
ORDER BY ordinal_position;

-- Vérifier aussi les autres tables qui référencent company_id
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND column_name = 'company_id'
ORDER BY table_name;


