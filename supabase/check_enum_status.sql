-- Diagnostiquer les problèmes d'enum status
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier tous les types enum existants
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value,
    e.enumsortorder as sort_order
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname LIKE '%status%'
ORDER BY t.typname, e.enumsortorder;

-- 2. Vérifier les contraintes CHECK sur les colonnes status
SELECT 
    table_name,
    column_name,
    data_type,
    check_clause
FROM information_schema.check_constraints cc
JOIN information_schema.constraint_column_usage ccu ON cc.constraint_name = ccu.constraint_name
WHERE column_name LIKE '%status%'
AND table_schema = 'public';

-- 3. Vérifier les colonnes status dans toutes les tables
SELECT 
    table_name,
    column_name,
    data_type,
    udt_name,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public'
AND column_name LIKE '%status%'
ORDER BY table_name;

-- 4. Vérifier spécifiquement la table tasks
SELECT 
    column_name,
    data_type,
    udt_name,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
AND table_name = 'tasks'
AND column_name = 'status';

-- 5. Identifier le problème
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_type t 
            JOIN pg_enum e ON t.oid = e.enumtypid  
            WHERE t.typname = 'status_type' AND e.enumlabel = 'en_cours'
        ) THEN '✅ Enum status_type accepte "en_cours"'
        WHEN EXISTS (
            SELECT 1 FROM pg_type t 
            WHERE t.typname = 'status_type'
        ) THEN '❌ PROBLÈME: Enum status_type existe mais ne contient pas "en_cours"'
        ELSE '⚠️ Aucun enum status_type trouvé - utilisation de CHECK constraints'
    END as diagnostic; 