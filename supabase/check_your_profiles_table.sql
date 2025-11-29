-- Vérifier si la table profiles existe et sa structure
SELECT 
  table_name,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;

-- Si aucun résultat, essayez avec 'user_profiles' ou autre nom
SELECT 
  table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name LIKE '%profile%'
  OR table_name LIKE '%user%';



