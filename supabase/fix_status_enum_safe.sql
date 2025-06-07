-- Corriger les problèmes d'enum status - Version sécurisée
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Supprimer les contraintes CHECK existantes sur toutes les colonnes de statut possibles
DO $$
DECLARE
    constraint_rec RECORD;
    possible_columns TEXT[] := ARRAY['status', 'state', 'statut', 'etat', 'task_status'];
    col TEXT;
BEGIN
    FOREACH col IN ARRAY possible_columns
    LOOP
        FOR constraint_rec IN 
            SELECT tc.constraint_name, tc.table_name
            FROM information_schema.table_constraints tc
            JOIN information_schema.constraint_column_usage ccu ON tc.constraint_name = ccu.constraint_name
            WHERE tc.constraint_type = 'CHECK' 
            AND ccu.column_name = col
            AND tc.table_schema = 'public'
            AND tc.table_name IN ('tasks', 'projects', 'timesheet_entries')
        LOOP
            EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I', 
                          constraint_rec.table_name, constraint_rec.constraint_name);
            RAISE NOTICE 'Supprimé contrainte % sur table %', constraint_rec.constraint_name, constraint_rec.table_name;
        END LOOP;
    END LOOP;
END $$;

-- 2. Supprimer l'enum status_type s'il existe
DROP TYPE IF EXISTS status_type CASCADE;

-- 3. Corriger la table tasks - recherche automatique de la colonne de statut
DO $$
DECLARE
    status_column TEXT;
    possible_columns TEXT[] := ARRAY['status', 'state', 'statut', 'etat', 'task_status'];
    col TEXT;
BEGIN
    -- Chercher quelle colonne de statut existe dans tasks
    FOREACH col IN ARRAY possible_columns
    LOOP
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'tasks' 
            AND column_name = col
        ) THEN
            status_column := col;
            EXIT;
        END IF;
    END LOOP;
    
    IF status_column IS NOT NULL THEN
        RAISE NOTICE 'Colonne de statut trouvée dans tasks: %', status_column;
        
        -- Modifier le type de la colonne
        EXECUTE format('ALTER TABLE public.tasks ALTER COLUMN %I TYPE VARCHAR(50)', status_column);
        EXECUTE format('ALTER TABLE public.tasks ALTER COLUMN %I SET DEFAULT ''todo''', status_column);
        
        -- Ajouter une nouvelle contrainte CHECK flexible
        EXECUTE format('ALTER TABLE public.tasks ADD CONSTRAINT tasks_%s_check CHECK (%I IN (
            ''todo'', ''à_faire'', ''a_faire'',
            ''in_progress'', ''en_cours'', ''en cours'', ''in progress'',
            ''done'', ''terminé'', ''termine'', ''completed'', ''fini''
        ))', status_column, status_column);
        
        -- Normaliser les données existantes
        EXECUTE format('UPDATE public.tasks SET %I = CASE 
            WHEN %I IN (''à_faire'', ''a_faire'', ''à faire'', ''a faire'') THEN ''todo''
            WHEN %I IN (''en_cours'', ''en cours'', ''in progress'') THEN ''in_progress''
            WHEN %I IN (''terminé'', ''termine'', ''completed'', ''fini'') THEN ''done''
            ELSE %I
        END', status_column, status_column, status_column, status_column, status_column);
        
    ELSE
        RAISE NOTICE 'Aucune colonne de statut trouvée dans tasks - vérification manuelle nécessaire';
    END IF;
END $$;

-- 4. Corriger la table projects de manière similaire
DO $$
DECLARE
    status_column TEXT;
    possible_columns TEXT[] := ARRAY['status', 'state', 'statut', 'etat', 'project_status'];
    col TEXT;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'projects') THEN
        -- Chercher quelle colonne de statut existe dans projects
        FOREACH col IN ARRAY possible_columns
        LOOP
            IF EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = 'projects' 
                AND column_name = col
            ) THEN
                status_column := col;
                EXIT;
            END IF;
        END LOOP;
        
        IF status_column IS NOT NULL THEN
            RAISE NOTICE 'Colonne de statut trouvée dans projects: %', status_column;
            
            EXECUTE format('ALTER TABLE public.projects ALTER COLUMN %I TYPE VARCHAR(50)', status_column);
            EXECUTE format('ALTER TABLE public.projects ALTER COLUMN %I SET DEFAULT ''active''', status_column);
            
            EXECUTE format('ALTER TABLE public.projects ADD CONSTRAINT projects_%s_check CHECK (%I IN (
                ''active'', ''actif'',
                ''inactive'', ''inactif'', 
                ''completed'', ''terminé'', ''termine'', ''fini''
            ))', status_column, status_column);
        END IF;
    END IF;
END $$;

-- 5. Corriger timesheet_entries de manière similaire
DO $$
DECLARE
    status_column TEXT;
    possible_columns TEXT[] := ARRAY['status', 'state', 'statut', 'etat'];
    col TEXT;
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'timesheet_entries') THEN
        -- Chercher quelle colonne de statut existe dans timesheet_entries
        FOREACH col IN ARRAY possible_columns
        LOOP
            IF EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = 'timesheet_entries' 
                AND column_name = col
            ) THEN
                status_column := col;
                EXIT;
            END IF;
        END LOOP;
        
        IF status_column IS NOT NULL THEN
            RAISE NOTICE 'Colonne de statut trouvée dans timesheet_entries: %', status_column;
            
            EXECUTE format('ALTER TABLE public.timesheet_entries ALTER COLUMN %I TYPE VARCHAR(50)', status_column);
            EXECUTE format('ALTER TABLE public.timesheet_entries ALTER COLUMN %I SET DEFAULT ''pending''', status_column);
            
            EXECUTE format('ALTER TABLE public.timesheet_entries ADD CONSTRAINT timesheet_entries_%s_check CHECK (%I IN (
                ''pending'', ''en_attente'', ''en attente'',
                ''approved'', ''approuvé'', ''approve'', ''validé'', ''valide'',
                ''rejected'', ''rejeté'', ''rejete'', ''refusé'', ''refuse''
            ))', status_column, status_column);
        END IF;
    END IF;
END $$;

-- 6. Vérification finale
SELECT 
    '✅ Structure corrigée' as message,
    table_name,
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND column_name IN ('status', 'state', 'statut', 'etat', 'task_status', 'project_status')
AND table_name IN ('tasks', 'projects', 'timesheet_entries')
ORDER BY table_name, column_name; 