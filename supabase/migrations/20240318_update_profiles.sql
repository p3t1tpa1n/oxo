-- Ajout de la colonne user_id à la table profiles
ALTER TABLE profiles
ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES auth.users(id);

-- Mise à jour des politiques de sécurité pour profiles
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON profiles;
DROP POLICY IF EXISTS "Enable update for profile owners" ON profiles;

-- Nouvelles politiques
CREATE POLICY "Enable read access for authenticated users"
ON profiles FOR SELECT
TO authenticated
USING (true);

CREATE POLICY "Enable insert for authenticated users"
ON profiles FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id OR
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

CREATE POLICY "Enable update for profile owners and admins"
ON profiles FOR UPDATE
TO authenticated
USING (
  auth.uid() = user_id OR
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
)
WITH CHECK (
  auth.uid() = user_id OR
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND profiles.role = 'admin'
  )
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS profiles_user_id_idx ON profiles(user_id);

-- Trigger pour vérifier l'unicité du user_id
CREATE OR REPLACE FUNCTION check_profile_uniqueness()
RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM profiles
    WHERE user_id = NEW.user_id
    AND id != NEW.id
  ) THEN
    RAISE EXCEPTION 'Un profil existe déjà pour cet utilisateur';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS ensure_profile_uniqueness ON profiles;
CREATE TRIGGER ensure_profile_uniqueness
  BEFORE INSERT OR UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION check_profile_uniqueness(); 