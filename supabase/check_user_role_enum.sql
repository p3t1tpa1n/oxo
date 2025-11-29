-- Vérifier les valeurs de l'enum user_role
SELECT 
  enumlabel as role_value,
  enumsortorder as sort_order
FROM pg_enum
WHERE enumtypid = (
  SELECT oid 
  FROM pg_type 
  WHERE typname = 'user_role'
)
ORDER BY enumsortorder;

-- Vérifier aussi les rôles utilisés dans la table profiles
SELECT DISTINCT user_role
FROM profiles
ORDER BY user_role;


