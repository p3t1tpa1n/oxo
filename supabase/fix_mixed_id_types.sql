-- Correction des types d'ID mixtes (UUID vs BIGINT)
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier les types actuels
SELECT 
    'DIAGNOSTIC - Types d''ID actuels' as info,
    table_name,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('projects', 'tasks', 'timesheet_entries')
AND column_name IN ('id', 'project_id', 'task_id')
ORDER BY table_name, column_name;

-- 2. Option A: Si projects.id est UUID, adapter timesheet_entries.task_id
DO $$
BEGIN
    -- Vérifier si projects.id est UUID
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'projects' 
        AND column_name = 'id' 
        AND data_type = 'uuid'
    ) THEN
        RAISE NOTICE 'DÉTECTÉ: projects.id est UUID';
        
        -- Vérifier si tasks.id est aussi UUID
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'tasks' 
            AND column_name = 'id' 
            AND data_type = 'uuid'
        ) THEN
            RAISE NOTICE 'DÉTECTÉ: tasks.id est UUID';
            
            -- Adapter timesheet_entries.task_id pour UUID
            IF EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_schema = 'public' 
                AND table_name = 'timesheet_entries' 
                AND column_name = 'task_id' 
                AND data_type = 'bigint'
            ) THEN
                RAISE NOTICE 'CORRECTION: Conversion de timesheet_entries.task_id en UUID';
                
                -- Supprimer la contrainte FK existante
                ALTER TABLE public.timesheet_entries 
                DROP CONSTRAINT IF EXISTS timesheet_entries_task_id_fkey;
                
                -- Modifier le type de colonne
                ALTER TABLE public.timesheet_entries 
                ALTER COLUMN task_id TYPE UUID USING task_id::text::uuid;
                
                -- Recréer la contrainte FK
                ALTER TABLE public.timesheet_entries 
                ADD CONSTRAINT timesheet_entries_task_id_fkey 
                FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;
                
                RAISE NOTICE '✅ timesheet_entries.task_id converti en UUID';
            END IF;
            
        ELSE
            RAISE NOTICE 'INFO: tasks.id est BIGINT - pas de changement nécessaire';
        END IF;
        
    ELSE
        RAISE NOTICE 'INFO: projects.id est BIGINT - configuration standard';
    END IF;
END $$;

-- 3. Option B: Si on veut forcer tout en BIGINT (plus simple)
-- DÉCOMMENTEZ cette section si vous préférez tout en BIGINT

/*
DO $$
BEGIN
    -- Convertir projects.id en BIGINT si c'est UUID
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'projects' 
        AND column_name = 'id' 
        AND data_type = 'uuid'
    ) THEN
        RAISE NOTICE 'CONVERSION: projects.id UUID -> BIGINT';
        
        -- Supprimer les contraintes FK
        ALTER TABLE public.tasks DROP CONSTRAINT IF EXISTS tasks_project_id_fkey;
        
        -- Convertir projects.id en BIGINT
        ALTER TABLE public.projects 
        ALTER COLUMN id TYPE BIGINT USING abs(hashtext(id::text));
        
        -- Convertir tasks.project_id pour correspondre
        ALTER TABLE public.tasks 
        ALTER COLUMN project_id TYPE BIGINT USING abs(hashtext(project_id::text));
        
        -- Recréer la contrainte FK
        ALTER TABLE public.tasks 
        ADD CONSTRAINT tasks_project_id_fkey 
        FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE;
        
        RAISE NOTICE '✅ Conversion BIGINT terminée';
    END IF;
END $$;
*/

-- 4. Vérification finale
SELECT 
    '✅ RÉSULTAT FINAL' as info,
    table_name,
    column_name,
    data_type,
    udt_name,
    CASE 
        WHEN table_name = 'projects' AND column_name = 'id' AND data_type = 'uuid' THEN 'UUID - Compatible avec code corrigé'
        WHEN table_name = 'projects' AND column_name = 'id' AND data_type = 'bigint' THEN 'BIGINT - Compatible avec code corrigé'
        WHEN table_name = 'tasks' AND column_name = 'id' AND data_type = 'uuid' THEN 'UUID - Compatible avec code corrigé'
        WHEN table_name = 'tasks' AND column_name = 'id' AND data_type = 'bigint' THEN 'BIGINT - Compatible avec code corrigé'
        WHEN table_name = 'timesheet_entries' AND column_name = 'task_id' THEN 'Référence task - doit correspondre à tasks.id'
        ELSE 'Autre colonne'
    END as status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('projects', 'tasks', 'timesheet_entries')
AND column_name IN ('id', 'project_id', 'task_id')
ORDER BY table_name, column_name;

-- Message final
SELECT '🎯 Code Flutter corrigé pour gérer UUID et BIGINT automatiquement !' as message; 