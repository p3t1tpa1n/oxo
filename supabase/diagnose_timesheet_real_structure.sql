-- Diagnostiquer la structure réelle de timesheet_entries
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure complète actuelle
SELECT 'STRUCTURE COMPLÈTE ACTUELLE' as test;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN is_nullable = 'NO' AND column_default IS NULL THEN '🔴 NOT NULL sans défaut'
        WHEN is_nullable = 'NO' AND column_default IS NOT NULL THEN '🟡 NOT NULL avec défaut'
        ELSE '✅ NULL autorisé'
    END as constraint_status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes problématiques
SELECT 'CONTRAINTES PROBLÉMATIQUES' as test;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
AND is_nullable = 'NO'
AND column_default IS NULL
AND column_name NOT IN ('id', 'user_id', 'task_id') -- Exclure les clés
ORDER BY ordinal_position;

-- 3. Identifier ce que le code Flutter essaie d'insérer
SELECT 'ANALYSE DES BESOINS FLUTTER' as test;
SELECT 
    'Le code Flutter insère: user_id, task_id, hours, date, description, status' as flutter_fields,
    'Colonnes NOT NULL trouvées: ' || string_agg(column_name, ', ') as required_columns
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
AND is_nullable = 'NO'
AND column_default IS NULL
AND column_name NOT IN ('id');

-- 4. Correction adaptative de la structure
DO $$
DECLARE
    col_record record;
BEGIN
    RAISE NOTICE 'Début de la correction adaptative...';
    
    -- Parcourir toutes les colonnes problématiques et les corriger
    FOR col_record IN 
        SELECT column_name, data_type
        FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'timesheet_entries'
        AND is_nullable = 'NO'
        AND column_default IS NULL
        AND column_name NOT IN ('id', 'user_id', 'task_id', 'date', 'hours') -- Garder les essentielles
    LOOP
        RAISE NOTICE 'Correction de la colonne: %', col_record.column_name;
        
        -- Selon le nom de la colonne, appliquer la correction appropriée
        CASE col_record.column_name
            WHEN 'start_time' THEN
                -- Pour start_time, permettre NULL ou mettre une valeur par défaut
                ALTER TABLE public.timesheet_entries 
                ALTER COLUMN start_time DROP NOT NULL;
                RAISE NOTICE 'start_time: NOT NULL supprimé';
                
            WHEN 'end_time' THEN
                -- Pour end_time, permettre NULL
                ALTER TABLE public.timesheet_entries 
                ALTER COLUMN end_time DROP NOT NULL;
                RAISE NOTICE 'end_time: NOT NULL supprimé';
                
            WHEN 'description' THEN
                -- Pour description, ajouter une valeur par défaut
                ALTER TABLE public.timesheet_entries 
                ALTER COLUMN description SET DEFAULT '';
                ALTER TABLE public.timesheet_entries 
                ALTER COLUMN description DROP NOT NULL;
                RAISE NOTICE 'description: Default ajouté et NOT NULL supprimé';
                
            WHEN 'status' THEN
                -- Pour status, ajouter une valeur par défaut
                ALTER TABLE public.timesheet_entries 
                ALTER COLUMN status SET DEFAULT 'pending';
                RAISE NOTICE 'status: Default pending ajouté';
                
            WHEN 'created_at' THEN
                -- Pour created_at, ajouter NOW() par défaut
                ALTER TABLE public.timesheet_entries 
                ALTER COLUMN created_at SET DEFAULT NOW();
                RAISE NOTICE 'created_at: Default NOW() ajouté';
                
            WHEN 'updated_at' THEN
                -- Pour updated_at, ajouter NOW() par défaut
                ALTER TABLE public.timesheet_entries 
                ALTER COLUMN updated_at SET DEFAULT NOW();
                RAISE NOTICE 'updated_at: Default NOW() ajouté';
                
            ELSE
                -- Pour les autres colonnes, simplement supprimer NOT NULL
                EXECUTE format('ALTER TABLE public.timesheet_entries ALTER COLUMN %I DROP NOT NULL', col_record.column_name);
                RAISE NOTICE 'Colonne %: NOT NULL supprimé', col_record.column_name;
        END CASE;
    END LOOP;
    
    RAISE NOTICE 'Correction adaptative terminée';
END $$;

-- 5. Ajouter les colonnes essentielles si elles manquent
DO $$
BEGIN
    -- Vérifier et ajouter hours si manquante
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'timesheet_entries' AND column_name = 'hours'
    ) THEN
        ALTER TABLE public.timesheet_entries 
        ADD COLUMN hours DECIMAL(5,2) DEFAULT 0;
        RAISE NOTICE 'Colonne hours ajoutée';
    END IF;
    
    -- Vérifier et ajouter description si manquante
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'timesheet_entries' AND column_name = 'description'
    ) THEN
        ALTER TABLE public.timesheet_entries 
        ADD COLUMN description TEXT;
        RAISE NOTICE 'Colonne description ajoutée';
    END IF;
    
    -- Vérifier et ajouter status si manquante
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'timesheet_entries' AND column_name = 'status'
    ) THEN
        ALTER TABLE public.timesheet_entries 
        ADD COLUMN status VARCHAR(50) DEFAULT 'pending';
        RAISE NOTICE 'Colonne status ajoutée';
    END IF;
END $$;

-- 6. Vérification finale après correction
SELECT 'STRUCTURE CORRIGÉE' as test;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN is_nullable = 'NO' AND column_default IS NULL AND column_name NOT IN ('id', 'user_id', 'task_id', 'date') 
        THEN '🔴 ENCORE PROBLÉMATIQUE'
        WHEN is_nullable = 'NO' AND column_default IS NOT NULL THEN '🟡 NOT NULL avec défaut (OK)'
        WHEN is_nullable = 'YES' THEN '✅ NULL autorisé (OK)'
        ELSE '✅ OK'
    END as status_final
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
ORDER BY ordinal_position;

-- 7. Test d'insertion simulé
SELECT 'TEST DE COMPATIBILITÉ FLUTTER' as test;
SELECT 
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'timesheet_entries'
            AND is_nullable = 'NO' AND column_default IS NULL
            AND column_name NOT IN ('id', 'user_id', 'task_id', 'date', 'hours')
        ) THEN '✅ Structure compatible avec Flutter'
        ELSE '❌ Il reste des colonnes NOT NULL sans défaut'
    END as compatibility_status;

-- 8. Colonnes que Flutter doit insérer
SELECT 'COLONNES REQUISES POUR FLUTTER' as test;
SELECT string_agg(column_name, ', ' ORDER BY ordinal_position) as required_columns
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
AND (
    (is_nullable = 'NO' AND column_default IS NULL) OR
    column_name IN ('user_id', 'task_id', 'hours', 'date', 'description', 'status')
)
AND column_name != 'id'; 