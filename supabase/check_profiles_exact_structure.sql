-- Vérifier la structure EXACTE de la table profiles
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
ORDER BY ordinal_position;

-- Afficher aussi un exemple de données
SELECT * FROM profiles LIMIT 3;


