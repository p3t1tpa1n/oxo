-- Corriger la structure de la table timesheet_entries
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure actuelle de timesheet_entries
SELECT 'STRUCTURE ACTUELLE timesheet_entries' as test;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
ORDER BY ordinal_position;

-- 2. Créer la table timesheet_entries avec la structure complète si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.timesheet_entries (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID NOT NULL,
    task_id UUID, -- Peut être UUID ou BIGINT selon votre structure
    date DATE NOT NULL,
    hours DECIMAL(5,2) NOT NULL DEFAULT 0,
    description TEXT,
    status VARCHAR(50) DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Ajouter les colonnes manquantes si elles n'existent pas
ALTER TABLE public.timesheet_entries 
ADD COLUMN IF NOT EXISTS hours DECIMAL(5,2) NOT NULL DEFAULT 0;

ALTER TABLE public.timesheet_entries 
ADD COLUMN IF NOT EXISTS description TEXT;

ALTER TABLE public.timesheet_entries 
ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'pending';

ALTER TABLE public.timesheet_entries 
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT NOW();

ALTER TABLE public.timesheet_entries 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- 4. Vérifier le type de task_id et l'adapter si nécessaire
DO $$
DECLARE
    task_id_type text;
    tasks_id_type text;
BEGIN
    -- Vérifier le type de task_id dans timesheet_entries
    SELECT data_type INTO task_id_type
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'timesheet_entries'
    AND column_name = 'task_id';
    
    -- Vérifier le type de id dans tasks
    SELECT data_type INTO tasks_id_type
    FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tasks'
    AND column_name = 'id';
    
    RAISE NOTICE 'Type task_id dans timesheet_entries: %', task_id_type;
    RAISE NOTICE 'Type id dans tasks: %', tasks_id_type;
    
    -- Si les types ne correspondent pas, corriger
    IF task_id_type IS NOT NULL AND tasks_id_type IS NOT NULL AND task_id_type != tasks_id_type THEN
        RAISE NOTICE 'Types incompatibles, correction en cours...';
        
        -- Supprimer la contrainte FK existante
        ALTER TABLE public.timesheet_entries 
        DROP CONSTRAINT IF EXISTS timesheet_entries_task_id_fkey;
        
        -- Modifier le type selon le type de tasks.id
        IF tasks_id_type = 'uuid' THEN
            ALTER TABLE public.timesheet_entries 
            ALTER COLUMN task_id TYPE UUID USING task_id::text::uuid;
        ELSIF tasks_id_type = 'bigint' THEN
            ALTER TABLE public.timesheet_entries 
            ALTER COLUMN task_id TYPE BIGINT USING task_id::text::bigint;
        END IF;
        
        RAISE NOTICE 'Type task_id corrigé vers %', tasks_id_type;
    END IF;
END $$;

-- 5. Ajouter ou recréer les contraintes de clés étrangères
ALTER TABLE public.timesheet_entries 
DROP CONSTRAINT IF EXISTS timesheet_entries_user_id_fkey;

ALTER TABLE public.timesheet_entries 
DROP CONSTRAINT IF EXISTS timesheet_entries_task_id_fkey;

-- Contrainte user_id -> auth.users
ALTER TABLE public.timesheet_entries 
ADD CONSTRAINT timesheet_entries_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- Contrainte task_id -> tasks.id
ALTER TABLE public.timesheet_entries 
ADD CONSTRAINT timesheet_entries_task_id_fkey 
FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;

-- 6. Créer les index pour les performances
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_user_id ON public.timesheet_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_task_id ON public.timesheet_entries(task_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_date ON public.timesheet_entries(date);

-- 7. Activer RLS (Row Level Security)
ALTER TABLE public.timesheet_entries ENABLE ROW LEVEL SECURITY;

-- 8. Créer les politiques de sécurité
DROP POLICY IF EXISTS "timesheet_entries_select_policy" ON public.timesheet_entries;
CREATE POLICY "timesheet_entries_select_policy" ON public.timesheet_entries
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "timesheet_entries_insert_policy" ON public.timesheet_entries;
CREATE POLICY "timesheet_entries_insert_policy" ON public.timesheet_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "timesheet_entries_update_policy" ON public.timesheet_entries;
CREATE POLICY "timesheet_entries_update_policy" ON public.timesheet_entries
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "timesheet_entries_delete_policy" ON public.timesheet_entries;
CREATE POLICY "timesheet_entries_delete_policy" ON public.timesheet_entries
    FOR DELETE USING (auth.uid() = user_id);

-- 9. Trigger pour mettre à jour automatiquement updated_at
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

-- 10. Vérification finale de la structure
SELECT 'STRUCTURE FINALE timesheet_entries' as test;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
ORDER BY ordinal_position;

-- 11. Test d'insertion pour vérifier que tout fonctionne
SELECT 'TEST DE STRUCTURE COMPLÈTE' as test;
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'timesheet_entries' 
            AND column_name = 'hours'
        ) THEN '✅ Colonne hours existe'
        ELSE '❌ Colonne hours manquante'
    END as hours_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'timesheet_entries' 
            AND column_name = 'description'
        ) THEN '✅ Colonne description existe'
        ELSE '❌ Colonne description manquante'
    END as description_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'timesheet_entries' 
            AND column_name = 'status'
        ) THEN '✅ Colonne status existe'
        ELSE '❌ Colonne status manquante'
    END as status_status; 