-- Ajout des colonnes manquantes à la table tasks
ALTER TABLE tasks
ADD COLUMN IF NOT EXISTS created_by uuid REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS updated_by uuid REFERENCES auth.users(id),
ADD COLUMN IF NOT EXISTS partner_id uuid REFERENCES auth.users(id);

-- Mise à jour des politiques de sécurité
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON tasks;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON tasks;
DROP POLICY IF EXISTS "Enable update for task owners" ON tasks;
DROP POLICY IF EXISTS "Enable delete for task owners" ON tasks;

-- Nouvelles politiques
CREATE POLICY "Enable read access for authenticated users"
ON tasks FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id OR
  auth.uid() = partner_id OR
  auth.uid() = assigned_to OR
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'associe')
  )
);

CREATE POLICY "Enable insert for authenticated users"
ON tasks FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id OR
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'associe' OR profiles.role = 'partenaire')
  )
);

CREATE POLICY "Enable update for task owners and admins"
ON tasks FOR UPDATE
TO authenticated
USING (
  auth.uid() = user_id OR
  auth.uid() = partner_id OR
  auth.uid() = assigned_to OR
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'associe')
  )
)
WITH CHECK (
  auth.uid() = user_id OR
  auth.uid() = partner_id OR
  auth.uid() = assigned_to OR
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'associe')
  )
);

CREATE POLICY "Enable delete for task owners and admins"
ON tasks FOR DELETE
TO authenticated
USING (
  auth.uid() = user_id OR
  EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.user_id = auth.uid()
    AND (profiles.role = 'admin' OR profiles.role = 'associe')
  )
);

-- Trigger pour mettre à jour created_by et updated_by
CREATE OR REPLACE FUNCTION update_task_metadata()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    NEW.created_by := auth.uid();
  END IF;
  NEW.updated_by := auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS tasks_metadata_trigger ON tasks;
CREATE TRIGGER tasks_metadata_trigger
  BEFORE INSERT OR UPDATE ON tasks
  FOR EACH ROW
  EXECUTE FUNCTION update_task_metadata(); 