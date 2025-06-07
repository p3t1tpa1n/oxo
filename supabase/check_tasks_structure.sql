-- Vérifier la structure de la table tasks
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier si la table tasks existe
SELECT EXISTS (
   SELECT FROM information_schema.tables 
   WHERE table_schema = 'public'
   AND table_name = 'tasks'
);

-- 2. Lister toutes les colonnes de la table tasks
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tasks'
ORDER BY ordinal_position;

-- 3. Vérifier les contraintes existantes
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'tasks' AND tc.constraint_type = 'FOREIGN KEY'
ORDER BY tc.constraint_name; 