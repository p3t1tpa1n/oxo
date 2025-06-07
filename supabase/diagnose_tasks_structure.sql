-- Diagnostic complet de la structure de la table tasks
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier si la table tasks existe
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tasks')
        THEN '✅ Table tasks existe'
        ELSE '❌ Table tasks n''existe pas'
    END as table_status;

-- 2. Afficher toutes les colonnes de la table tasks
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'tasks'
ORDER BY ordinal_position;

-- 3. Rechercher toutes les colonnes qui pourraient contenir un statut
SELECT 
    table_name,
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'tasks'
AND (
    column_name ILIKE '%status%' OR 
    column_name ILIKE '%state%' OR 
    column_name ILIKE '%statut%' OR
    column_name ILIKE '%etat%'
)
ORDER BY table_name, column_name;

-- 4. Afficher les contraintes existantes sur la table tasks
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    ccu.column_name,
    cc.check_clause
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
LEFT JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_schema = 'public' 
AND tc.table_name = 'tasks'
ORDER BY tc.constraint_type, tc.constraint_name;

-- 5. Rechercher les types enum utilisés dans la base
SELECT 
    typname as enum_name,
    enumlabel as enum_value
FROM pg_enum e
JOIN pg_type t ON e.enumtypid = t.oid
ORDER BY typname, enumsortorder;

-- 6. Échantillon de données de la table tasks (3 premières lignes)
SELECT * FROM public.tasks LIMIT 3; 