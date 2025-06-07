-- Corriger les problèmes d'enum status pour accepter les valeurs françaises et anglaises
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Supprimer les contraintes CHECK existantes sur status qui pourraient poser problème
DO $$
DECLARE
    constraint_rec RECORD;
BEGIN
    FOR constraint_rec IN 
        SELECT tc.constraint_name, tc.table_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
        WHERE tc.constraint_type = 'CHECK' 
        AND ccu.column_name = 'status'
        AND tc.table_schema = 'public'
        AND tc.table_name IN ('tasks', 'projects', 'timesheet_entries')
    LOOP
        EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', 
                      constraint_rec.table_name, constraint_rec.constraint_name);
    END LOOP;
END $$;

-- 2. Supprimer l'enum status_type s'il existe
DROP TYPE IF EXISTS status_type CASCADE;

-- 3. Modifier la colonne status dans tasks pour accepter toutes les valeurs
ALTER TABLE public.tasks ALTER COLUMN status TYPE VARCHAR(50);
ALTER TABLE public.tasks ALTER COLUMN status SET DEFAULT 'todo';

-- 4. Ajouter une nouvelle contrainte CHECK flexible pour tasks
ALTER TABLE public.tasks 
ADD CONSTRAINT tasks_status_check 
CHECK (status IN (
    'todo', 'à_faire', 'a_faire',
    'in_progress', 'en_cours', 'en cours', 'in progress',
    'done', 'terminé', 'termine', 'completed', 'fini'
));

-- 5. Faire de même pour projects si la table existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'projects') THEN
        ALTER TABLE public.projects ALTER COLUMN status TYPE VARCHAR(50);
        ALTER TABLE public.projects ALTER COLUMN status SET DEFAULT 'active';
        
        ALTER TABLE public.projects 
        ADD CONSTRAINT projects_status_check 
        CHECK (status IN (
            'active', 'actif',
            'inactive', 'inactif', 
            'completed', 'terminé', 'termine', 'fini'
        ));
    END IF;
END $$;

-- 6. Faire de même pour timesheet_entries si nécessaire
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'timesheet_entries') THEN
        ALTER TABLE public.timesheet_entries ALTER COLUMN status TYPE VARCHAR(50);
        ALTER TABLE public.timesheet_entries ALTER COLUMN status SET DEFAULT 'pending';
        
        ALTER TABLE public.timesheet_entries 
        ADD CONSTRAINT timesheet_entries_status_check 
        CHECK (status IN (
            'pending', 'en_attente', 'en attente',
            'approved', 'approuvé', 'approve', 'validé', 'valide',
            'rejected', 'rejeté', 'rejete', 'refusé', 'refuse'
        ));
    END IF;
END $$;

-- 7. Normaliser les données existantes si nécessaire
UPDATE public.tasks 
SET status = CASE 
    WHEN status IN ('à_faire', 'a_faire', 'à faire', 'a faire') THEN 'todo'
    WHEN status IN ('en_cours', 'en cours', 'in progress') THEN 'in_progress'
    WHEN status IN ('terminé', 'termine', 'completed', 'fini') THEN 'done'
    ELSE status
END;

-- 8. Vérification finale
SELECT 
    table_name,
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND column_name = 'status'
AND table_name IN ('tasks', 'projects', 'timesheet_entries')
ORDER BY table_name;

-- Message final
SELECT '✅ Problème d''enum résolu - Valeurs françaises et anglaises acceptées !' as status; 