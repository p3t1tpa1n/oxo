-- =============================================
-- SCRIPT SIMPLE DE DIAGNOSTIC - ÉTAT ACTUEL DE LA BASE
-- =============================================

-- 1. Lister toutes les tables existantes
SELECT 'TABLES EXISTANTES' as section, tablename as item, 'Table' as type
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 2. Vérifier la table clients spécifiquement
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clients') 
        THEN 'Table clients existe' 
        ELSE 'Table clients n''existe pas' 
    END as status;

-- 3. Colonnes de la table clients (si elle existe)
SELECT 'Colonnes de clients' as info, column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'clients' 
ORDER BY ordinal_position;

-- 4. Vérifier RLS sur clients
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_class WHERE relname = 'clients' AND relrowsecurity = true) 
        THEN 'RLS activé sur clients' 
        ELSE 'RLS désactivé sur clients' 
    END as rls_status;

-- 5. Vérifier la table user_roles
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_roles') 
        THEN 'Table user_roles existe' 
        ELSE 'Table user_roles n''existe pas' 
    END as status;

-- 6. Utilisateurs par rôle (si user_roles existe)
SELECT 'Utilisateurs par rôle' as info, user_role, COUNT(*) as count
FROM user_roles 
GROUP BY user_role
ORDER BY user_role;

-- 7. Vérifier les tables de missions
SELECT 'Tables missions' as section,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mission_assignments') 
         THEN 'mission_assignments: EXISTE' 
         ELSE 'mission_assignments: MANQUANTE' 
    END as status
UNION ALL
SELECT 'Tables missions' as section,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_notifications') 
         THEN 'user_notifications: EXISTE' 
         ELSE 'user_notifications: MANQUANTE' 
    END as status
UNION ALL
SELECT 'Tables missions' as section,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'projects') 
         THEN 'projects: EXISTE' 
         ELSE 'projects: MANQUANTE' 
    END as status
UNION ALL
SELECT 'Tables missions' as section,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tasks') 
         THEN 'tasks: EXISTE' 
         ELSE 'tasks: MANQUANTE' 
    END as status;

-- 8. Politiques RLS
SELECT 'Politiques RLS' as section, tablename, policyname, cmd
FROM pg_policies 
ORDER BY tablename, policyname;

-- 9. Fonctions
SELECT 'Fonctions' as section, proname as function_name
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' AND p.prokind = 'f'
ORDER BY p.proname;

-- 10. Vues
SELECT 'Vues' as section, table_name
FROM information_schema.views
WHERE table_schema = 'public'
ORDER BY table_name;

-- 11. Index
SELECT 'Index' as section, tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- 12. Triggers
SELECT 'Triggers' as section, event_object_table, trigger_name
FROM information_schema.triggers
WHERE trigger_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 13. Résumé final
SELECT 'RÉSUMÉ' as section,
    (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public') as tables_count,
    (SELECT COUNT(*) FROM pg_policies) as policies_count,
    (SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.prokind = 'f') as functions_count,
    (SELECT COUNT(*) FROM information_schema.views WHERE table_schema = 'public') as views_count;


