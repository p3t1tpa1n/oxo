-- Fonction pour créer un profil automatiquement
CREATE OR REPLACE FUNCTION public.create_profile_on_signup()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO public.profiles (user_id, email, role, status, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.email,
    'client',
    'actif',
    NOW(),
    NOW()
  );
  RETURN NEW;
END;
$$;

-- Supprimer le trigger s'il existe
DROP TRIGGER IF EXISTS create_profile_on_signup ON auth.users;

-- Créer le trigger
CREATE TRIGGER create_profile_on_signup
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.create_profile_on_signup(); 