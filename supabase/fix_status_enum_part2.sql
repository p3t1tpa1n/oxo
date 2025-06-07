-- PARTIE 2 : Utiliser les nouvelles valeurs pour mettre à jour les données
-- À exécuter APRÈS fix_status_enum_part1.sql dans l'éditeur SQL de Supabase

-- 1. Vérifier que la table tasks utilise bien l'enum status_type
DO $$
DECLARE
    status_column_info RECORD;
BEGIN
    SELECT 
        column_name,
        data_type,
        udt_name
    INTO status_column_info
    FROM information_schema.columns
    WHERE table_schema = 'public' 
    AND table_name = 'tasks'
    AND column_name IN ('status', 'statut', 'state', 'etat');
    
    IF FOUND THEN
        RAISE NOTICE 'Colonne de statut dans tasks: % (type: %, udt: %)', 
                     status_column_info.column_name, 
                     status_column_info.data_type, 
                     status_column_info.udt_name;
                     
        -- Si ce n'est pas déjà un enum, le convertir
        IF status_column_info.data_type != 'USER-DEFINED' OR status_column_info.udt_name != 'status_type' THEN
            EXECUTE format('ALTER TABLE public.tasks ALTER COLUMN %I TYPE status_type USING %I::status_type', 
                          status_column_info.column_name, 
                          status_column_info.column_name);
            RAISE NOTICE 'Converti la colonne % en status_type', status_column_info.column_name;
        END IF;
    ELSE
        RAISE NOTICE 'Aucune colonne de statut trouvée dans tasks';
    END IF;
END $$;

-- 2. Mettre à jour les données existantes pour mapper les anciennes valeurs
UPDATE public.tasks 
SET status = CASE 
    WHEN status = 'actif' THEN 'in_progress'::status_type
    WHEN status = 'inactif' THEN 'done'::status_type
    WHEN status = 'en_attente' THEN 'todo'::status_type
    WHEN status = 'archive' THEN 'done'::status_type
    -- Garder les nouvelles valeurs si elles existent déjà
    WHEN status::text IN ('todo', 'a_faire', 'en_cours', 'in_progress', 'done', 'termine', 'completed') THEN status
    ELSE 'todo'::status_type -- valeur par défaut
END
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tasks' 
    AND column_name = 'status'
);

-- 3. Faire de même pour la table projects si elle utilise status_type
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'projects' 
        AND column_name IN ('status', 'statut')
        AND udt_name = 'status_type'
    ) THEN
        UPDATE public.projects 
        SET status = CASE 
            WHEN status = 'en_attente' THEN 'todo'::status_type
            WHEN status = 'actif' THEN 'in_progress'::status_type
            WHEN status = 'inactif' THEN 'done'::status_type
            WHEN status = 'archive' THEN 'done'::status_type
            ELSE status
        END;
        
        RAISE NOTICE 'Mis à jour les statuts dans projects';
    END IF;
END $$;

-- 4. Mettre à jour timesheet_entries si nécessaire
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'timesheet_entries' 
        AND column_name = 'status'
        AND udt_name = 'status_type'
    ) THEN
        UPDATE public.timesheet_entries 
        SET status = CASE 
            WHEN status = 'en_attente' THEN 'todo'::status_type
            WHEN status = 'actif' THEN 'in_progress'::status_type
            WHEN status = 'inactif' THEN 'done'::status_type
            WHEN status = 'archive' THEN 'done'::status_type
            ELSE status
        END;
        
        RAISE NOTICE 'Mis à jour les statuts dans timesheet_entries';
    END IF;
END $$;

-- 5. Vérifier les colonnes qui utilisent status_type
SELECT 
    table_name,
    column_name,
    data_type,
    udt_name,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND udt_name = 'status_type'
ORDER BY table_name, column_name;

-- 6. Afficher l'enum status_type final
SELECT 
    'status_type' as enum_name,
    enumlabel as enum_value,
    enumsortorder as sort_order
FROM pg_enum e
JOIN pg_type t ON e.enumtypid = t.oid
WHERE t.typname = 'status_type'
ORDER BY enumsortorder;

-- Message final
SELECT '✅ CORRECTION TERMINÉE - Enum status_type mis à jour et données migrées !' as message; 