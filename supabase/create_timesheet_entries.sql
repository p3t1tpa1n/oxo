-- Créer la table timesheet_entries pour le chronomètre
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Créer la table timesheet_entries
CREATE TABLE IF NOT EXISTS public.timesheet_entries (
    id BIGSERIAL PRIMARY KEY,
    task_id BIGINT NOT NULL,
    user_id UUID NOT NULL,
    hours DECIMAL(8,2) NOT NULL DEFAULT 0.00,
    date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    description TEXT,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Créer les contraintes de clés étrangères
ALTER TABLE public.timesheet_entries 
DROP CONSTRAINT IF EXISTS timesheet_entries_task_id_fkey;

ALTER TABLE public.timesheet_entries 
DROP CONSTRAINT IF EXISTS timesheet_entries_user_id_fkey;

-- Ajouter les contraintes
ALTER TABLE public.timesheet_entries 
ADD CONSTRAINT timesheet_entries_task_id_fkey 
FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;

ALTER TABLE public.timesheet_entries 
ADD CONSTRAINT timesheet_entries_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 3. Créer des index pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_task_id ON public.timesheet_entries(task_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_user_id ON public.timesheet_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_date ON public.timesheet_entries(date);

-- 4. Activer RLS
ALTER TABLE public.timesheet_entries ENABLE ROW LEVEL SECURITY;

-- 5. Créer des politiques RLS simples (sans récursion)
DROP POLICY IF EXISTS "timesheet_entries_access" ON public.timesheet_entries;

CREATE POLICY "timesheet_entries_access"
ON public.timesheet_entries
FOR ALL TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- 6. Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_timesheet_entries_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_timesheet_entries_updated_at ON public.timesheet_entries;
CREATE TRIGGER update_timesheet_entries_updated_at
    BEFORE UPDATE ON public.timesheet_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_timesheet_entries_updated_at();

-- 7. Créer la table projects si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.projects (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'completed')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Activer RLS sur projects
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Politique simple pour projects
DROP POLICY IF EXISTS "projects_access" ON public.projects;
CREATE POLICY "projects_access"
ON public.projects
FOR ALL TO authenticated
USING (true)
WITH CHECK (true);

-- 8. Vérification finale
SELECT 
    table_name,
    CASE 
        WHEN table_name = 'timesheet_entries' THEN '🔥 CRITIQUE - Chronomètre'
        WHEN table_name = 'tasks' THEN '✅ Missions'
        WHEN table_name = 'projects' THEN '🏢 Entreprises'
    END as purpose
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('timesheet_entries', 'tasks', 'projects')
ORDER BY table_name;

-- Message final
SELECT '✅ Tables créées pour le système de chronomètre - Timesheet prêt !' as status; 