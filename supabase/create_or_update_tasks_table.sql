-- Créer ou mettre à jour la table tasks avec toutes les colonnes nécessaires
-- À exécuter dans l'éditeur SQL de Supabase

-- Créer la table tasks si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.tasks (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done')),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    due_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    project_id BIGINT,
    user_id UUID,
    assigned_to UUID,
    partner_id UUID,
    created_by UUID,
    updated_by UUID
);

-- Ajouter les colonnes manquantes si elles n'existent pas
ALTER TABLE public.tasks 
ADD COLUMN IF NOT EXISTS user_id UUID,
ADD COLUMN IF NOT EXISTS assigned_to UUID,
ADD COLUMN IF NOT EXISTS partner_id UUID,
ADD COLUMN IF NOT EXISTS created_by UUID,
ADD COLUMN IF NOT EXISTS updated_by UUID,
ADD COLUMN IF NOT EXISTS project_id BIGINT,
ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'done'));

-- Supprimer les contraintes existantes qui pourraient être incorrectes
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_assigned_to_fkey;
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_created_by_fkey;
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_project_id_fkey;
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_user_id_fkey;
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_partner_id_fkey;
ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_updated_by_fkey;

-- Créer les contraintes de clés étrangères
-- Note: On référence auth.users au lieu de profiles pour plus de simplicité
ALTER TABLE public.tasks 
ADD CONSTRAINT tasks_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.tasks 
ADD CONSTRAINT tasks_assigned_to_fkey 
FOREIGN KEY (assigned_to) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.tasks 
ADD CONSTRAINT tasks_partner_id_fkey 
FOREIGN KEY (partner_id) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.tasks 
ADD CONSTRAINT tasks_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.tasks 
ADD CONSTRAINT tasks_updated_by_fkey 
FOREIGN KEY (updated_by) REFERENCES auth.users(id) ON DELETE SET NULL;

-- Contrainte pour project_id (si la table projects existe)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'projects') THEN
        ALTER TABLE public.tasks 
        ADD CONSTRAINT tasks_project_id_fkey 
        FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Activer RLS sur la table
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Supprimer toutes les politiques existantes sur tasks
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.tasks;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.tasks;
DROP POLICY IF EXISTS "Enable update for task owners and admins" ON public.tasks;
DROP POLICY IF EXISTS "Enable delete for task owners and admins" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select_policy" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert_policy" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update_policy" ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete_policy" ON public.tasks;

-- Créer des politiques simplifiées pour tasks (SANS dépendance sur profiles pour éviter la récursion)
CREATE POLICY "tasks_select_policy"
ON public.tasks FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id OR
  auth.uid() = partner_id OR
  auth.uid() = assigned_to OR
  auth.uid() = created_by
);

CREATE POLICY "tasks_insert_policy"
ON public.tasks FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id OR
  auth.uid() = created_by
);

CREATE POLICY "tasks_update_policy"
ON public.tasks FOR UPDATE
TO authenticated
USING (
  auth.uid() = user_id OR
  auth.uid() = partner_id OR
  auth.uid() = assigned_to OR
  auth.uid() = created_by
)
WITH CHECK (
  auth.uid() = user_id OR
  auth.uid() = partner_id OR
  auth.uid() = assigned_to OR
  auth.uid() = created_by
);

CREATE POLICY "tasks_delete_policy"
ON public.tasks FOR DELETE
TO authenticated
USING (
  auth.uid() = user_id OR
  auth.uid() = created_by
);

-- Trigger pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_tasks_updated_at ON public.tasks;
CREATE TRIGGER update_tasks_updated_at
    BEFORE UPDATE ON public.tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Vérifier la structure finale
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tasks'
ORDER BY ordinal_position; 