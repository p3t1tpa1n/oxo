-- Vérifier la structure des tables projects et tasks
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Structure de la table projects
SELECT 
    'PROJECTS - Structure' as table_info,
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'id' AND data_type = 'uuid' THEN '🔴 PROBLÈME: ID est UUID mais code attend INT'
        WHEN column_name = 'id' AND data_type = 'bigint' THEN '✅ ID est BIGINT comme attendu'
        WHEN column_name = 'id' THEN '⚠️ Type ID inattendu'
        ELSE 'Normal'
    END as status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'projects'
ORDER BY ordinal_position;

-- 2. Structure de la table tasks
SELECT 
    'TASKS - Structure' as table_info,
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'id' AND data_type = 'uuid' THEN '🔴 PROBLÈME: ID est UUID mais code attend INT'
        WHEN column_name = 'id' AND data_type = 'bigint' THEN '✅ ID est BIGINT comme attendu'
        WHEN column_name = 'project_id' AND data_type = 'uuid' THEN '🔴 PROBLÈME: project_id est UUID mais code attend INT'
        WHEN column_name = 'project_id' AND data_type = 'bigint' THEN '✅ project_id est BIGINT comme attendu'
        WHEN column_name IN ('id', 'project_id') THEN '⚠️ Type inattendu'
        ELSE 'Normal'
    END as status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tasks'
ORDER BY ordinal_position;

-- 3. Vérifier les contraintes FK
SELECT 
    'CONTRAINTES FK' as info,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name IN ('tasks', 'projects')
ORDER BY tc.table_name, tc.constraint_name;

-- 4. Échantillon de données
SELECT 'ÉCHANTILLON PROJECTS' as info, id, name FROM public.projects LIMIT 3;
SELECT 'ÉCHANTILLON TASKS' as info, id, title, project_id FROM public.tasks LIMIT 3;

-- 5. Diagnostic final
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'projects' 
            AND column_name = 'id' 
            AND data_type = 'uuid'
        ) THEN '🔴 PROBLÈME IDENTIFIÉ: projects.id est UUID mais code Flutter utilise int.parse()'
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'projects' 
            AND column_name = 'id' 
            AND data_type = 'bigint'
        ) THEN '✅ Structure correcte: projects.id est BIGINT'
        ELSE '⚠️ Table projects introuvable ou structure inattendue'
    END as diagnostic; 