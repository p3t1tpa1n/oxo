-- Créer les profils manquants pour les utilisateurs existants
INSERT INTO public.profiles (user_id, email, role, status, created_at, updated_at)
SELECT 
  au.id,
  au.email,
  'client',
  'actif',
  au.created_at,
  au.created_at
FROM auth.users au
LEFT JOIN public.profiles p ON p.user_id = au.id
WHERE p.id IS NULL
AND au.deleted_at IS NULL;

-- Vérifier qu'il n'y a plus d'utilisateurs sans profil
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM auth.users au
    LEFT JOIN public.profiles p ON p.user_id = au.id
    WHERE p.id IS NULL
    AND au.deleted_at IS NULL
  ) THEN
    RAISE WARNING 'Il reste des utilisateurs sans profil';
  END IF;
END $$; 