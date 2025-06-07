-- Correction ultra-rapide du problème d'enum status
-- À exécuter dans l'éditeur SQL de Supabase

-- Supprimer l'enum problématique s'il existe
DROP TYPE IF EXISTS status_type CASCADE;

-- Modifier les colonnes status pour être des VARCHAR flexibles
-- Table tasks
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tasks') THEN
        -- Supprimer les contraintes existantes
        ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_status_check;
        
        -- Modifier le type de colonne
        ALTER TABLE public.tasks ALTER COLUMN status TYPE VARCHAR(50);
        ALTER TABLE public.tasks ALTER COLUMN status SET DEFAULT 'todo';
        
        -- Ajouter une contrainte flexible
        ALTER TABLE public.tasks 
        ADD CONSTRAINT tasks_status_check 
        CHECK (status IN ('todo', 'in_progress', 'done', 'active', 'completed', 'en_cours', 'termine', 'à_faire'));
    END IF;
END $$;

-- Table projects
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'projects') THEN
        -- Supprimer les contraintes existantes
        ALTER TABLE public.projects DROP CONSTRAINT IF EXISTS projects_status_check;
        
        -- Modifier le type de colonne
        ALTER TABLE public.projects ALTER COLUMN status TYPE VARCHAR(50);
        ALTER TABLE public.projects ALTER COLUMN status SET DEFAULT 'active';
        
        -- Ajouter une contrainte flexible
        ALTER TABLE public.projects 
        ADD CONSTRAINT projects_status_check 
        CHECK (status IN ('active', 'inactive', 'completed', 'en_cours', 'termine', 'actif', 'inactif'));
    END IF;
END $$;

-- Normaliser les données existantes
UPDATE public.tasks 
SET status = CASE 
    WHEN status = 'en_cours' THEN 'in_progress'
    WHEN status = 'termine' THEN 'done'
    WHEN status = 'à_faire' THEN 'todo'
    ELSE status
END
WHERE status IN ('en_cours', 'termine', 'à_faire');

UPDATE public.projects 
SET status = CASE 
    WHEN status = 'en_cours' THEN 'active'
    WHEN status = 'termine' THEN 'completed'
    ELSE status
END
WHERE status IN ('en_cours', 'termine');

-- Message de confirmation
SELECT '✅ Problème d''enum résolu - Création de tâches maintenant possible !' as status; 