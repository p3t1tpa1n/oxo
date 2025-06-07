-- Correction de l'enum status_type existant pour supporter le workflow des tasks
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Ajouter les valeurs manquantes à l'enum status_type existant
DO $$
DECLARE
    enum_values TEXT[] := ARRAY['todo', 'a_faire', 'en_cours', 'in_progress', 'done', 'termine', 'completed'];
    val TEXT;
BEGIN
    FOREACH val IN ARRAY enum_values
    LOOP
        BEGIN
            -- Tenter d'ajouter chaque valeur à l'enum
            EXECUTE format('ALTER TYPE status_type ADD VALUE IF NOT EXISTS %L', val);
            RAISE NOTICE 'Ajouté valeur % à status_type', val;
        EXCEPTION 
            WHEN duplicate_object THEN
                RAISE NOTICE 'Valeur % existe déjà dans status_type', val;
            WHEN OTHERS THEN
                RAISE NOTICE 'Erreur lors de l''ajout de % : %', val, SQLERRM;
        END;
    END LOOP;
END $$;

-- 2. Vérifier que la table tasks utilise bien l'enum status_type
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

-- 3. Mettre à jour les données existantes pour mapper les anciennes valeurs
UPDATE public.tasks 
SET status = CASE 
    WHEN status = 'actif' THEN 'in_progress'
    WHEN status = 'inactif' THEN 'done'
    WHEN status = 'en_attente' THEN 'todo'
    WHEN status = 'archive' THEN 'done'
    -- Garder les nouvelles valeurs si elles existent déjà
    WHEN status IN ('todo', 'a_faire', 'en_cours', 'in_progress', 'done', 'termine', 'completed') THEN status
    ELSE 'todo' -- valeur par défaut
END::status_type
WHERE EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'tasks' 
    AND column_name = 'status'
);

-- 4. Faire de même pour la table projects si elle utilise status_type
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
            WHEN status = 'en_attente' THEN 'todo'
            WHEN status = 'actif' THEN 'in_progress'
            WHEN status = 'inactif' THEN 'done'
            WHEN status = 'archive' THEN 'done'
            ELSE status
        END::status_type;
        
        RAISE NOTICE 'Mis à jour les statuts dans projects';
    END IF;
END $$;

-- 5. Afficher l'enum status_type mis à jour
SELECT 
    'status_type' as enum_name,
    enumlabel as enum_value,
    enumsortorder as sort_order
FROM pg_enum e
JOIN pg_type t ON e.enumtypid = t.oid
WHERE t.typname = 'status_type'
ORDER BY enumsortorder;

-- 6. Vérifier les colonnes qui utilisent status_type
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

-- Message final
SELECT '✅ Enum status_type mis à jour avec support complet des valeurs françaises/anglaises !' as message; 