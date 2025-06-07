-- Mise à jour des données existantes
UPDATE profiles p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
AND p.user_id IS NULL;

-- Vérification des enregistrements non migrés
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM profiles
    WHERE user_id IS NULL
  ) THEN
    RAISE WARNING 'Certains profils n''ont pas pu être migrés. Vérifiez les enregistrements avec user_id NULL.';
  END IF;
END $$; 