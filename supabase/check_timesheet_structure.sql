-- Vérifier si les tables nécessaires au timesheet existent
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier l'existence des tables nécessaires
SELECT 
    table_name,
    CASE 
        WHEN table_name = 'tasks' THEN 'Missions/Tâches'
        WHEN table_name = 'timesheet_entries' THEN 'Entrées de temps (REQUIS pour chronomètre)'
        WHEN table_name = 'projects' THEN 'Projets/Entreprises'
        WHEN table_name = 'profiles' THEN 'Profils utilisateurs'
    END as description,
    CASE 
        WHEN table_name IN ('tasks', 'timesheet_entries', 'projects', 'profiles') THEN '✅ Trouvée'
        ELSE '❌ Autre table'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('tasks', 'timesheet_entries', 'projects', 'profiles')
ORDER BY table_name;

-- 2. Vérifier la structure de la table tasks
SELECT 
    'TASKS - Structure' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name IN ('id', 'title', 'description', 'status', 'due_date', 'project_id', 'user_id', 'partner_id', 'assigned_to') 
        THEN '✅ Requis'
        ELSE '📝 Optionnel'
    END as importance
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'tasks'
ORDER BY ordinal_position;

-- 3. Vérifier la structure de timesheet_entries (table critique)
SELECT 
    'TIMESHEET_ENTRIES - Structure' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name IN ('id', 'task_id', 'user_id', 'hours', 'date', 'status') 
        THEN '✅ Requis'
        ELSE '📝 Optionnel'
    END as importance
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
ORDER BY ordinal_position;

-- 4. Vérifier la structure de projects
SELECT 
    'PROJECTS - Structure' as table_info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name IN ('id', 'name', 'description') 
        THEN '✅ Requis'
        ELSE '📝 Optionnel'
    END as importance
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'projects'
ORDER BY ordinal_position;

-- 5. Vérifier les contraintes de clés étrangères critiques
SELECT 
    'CONTRAINTES CRITIQUES' as info,
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    CASE 
        WHEN tc.constraint_name LIKE '%timesheet_entries%' THEN '🔥 CRITIQUE pour chronomètre'
        WHEN tc.constraint_name LIKE '%tasks%' THEN '✅ Important'
        ELSE '📝 Autre'
    END as priority
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_name IN ('tasks', 'timesheet_entries', 'projects')
ORDER BY tc.table_name, tc.constraint_name;

-- 6. Message de résumé
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'timesheet_entries') = 0 
        THEN '❌ PROBLÈME: Table timesheet_entries manquante - REQUIS pour le chronomètre !'
        WHEN (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'tasks') = 0 
        THEN '❌ PROBLÈME: Table tasks manquante'
        WHEN (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'projects') = 0 
        THEN '⚠️ ATTENTION: Table projects manquante - les entreprises ne s''afficheront pas'
        ELSE '✅ Toutes les tables critiques sont présentes'
    END as status_final; 