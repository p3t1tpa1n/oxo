-- =============================================
-- SCRIPT DE DIAGNOSTIC - ÉTAT ACTUEL DE LA BASE
-- =============================================

-- 1. Lister toutes les tables existantes
DO $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '📋 === TABLES EXISTANTES ===';
    FOR rec IN 
        SELECT schemaname, tablename, tableowner
        FROM pg_tables 
        WHERE schemaname = 'public'
        ORDER BY tablename
    LOOP
        RAISE NOTICE '  📄 % (owner: %)', rec.tablename, rec.tableowner;
    END LOOP;
END $$;

-- 2. Vérifier la table clients spécifiquement
DO $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🔍 === TABLE CLIENTS ===';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clients') THEN
        RAISE NOTICE '✅ Table clients existe';
        
        -- Colonnes de la table clients
        RAISE NOTICE '📋 Colonnes:';
        FOR rec IN 
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'clients' 
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  - %: % (nullable: %, default: %)', 
                rec.column_name, rec.data_type, rec.is_nullable, rec.column_default;
        END LOOP;
        
        -- RLS status
        IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'clients' AND relrowsecurity = true) THEN
            RAISE NOTICE '🔒 RLS: Activé';
        ELSE
            RAISE NOTICE '🔒 RLS: Désactivé';
        END IF;
        
    ELSE
        RAISE NOTICE '❌ Table clients n''existe pas';
    END IF;
END $$;

-- 3. Vérifier la table user_roles
DO $$
DECLARE
    rec RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '👥 === TABLE USER_ROLES ===';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_roles') THEN
        RAISE NOTICE '✅ Table user_roles existe';
        
        -- Colonnes de user_roles
        RAISE NOTICE '📋 Colonnes:';
        FOR rec IN 
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'user_roles' 
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  - %: % (nullable: %, default: %)', 
                rec.column_name, rec.data_type, rec.is_nullable, rec.column_default;
        END LOOP;
        
        -- Compter les utilisateurs par rôle
        RAISE NOTICE '📊 Utilisateurs par rôle:';
        FOR rec IN 
            SELECT user_role, COUNT(*) as count
            FROM user_roles 
            GROUP BY user_role
            ORDER BY user_role
        LOOP
            RAISE NOTICE '  - %: % utilisateurs', rec.user_role, rec.count;
        END LOOP;
        
    ELSE
        RAISE NOTICE '❌ Table user_roles n''existe pas';
    END IF;
END $$;

-- 4. Vérifier les tables de missions
DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎯 === TABLES MISSIONS ===';
    
    -- mission_assignments
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mission_assignments') THEN
        RAISE NOTICE '✅ Table mission_assignments existe';
    ELSE
        RAISE NOTICE '❌ Table mission_assignments n''existe pas';
    END IF;
    
    -- user_notifications
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_notifications') THEN
        RAISE NOTICE '✅ Table user_notifications existe';
    ELSE
        RAISE NOTICE '❌ Table user_notifications n''existe pas';
    END IF;
    
    -- projects
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'projects') THEN
        RAISE NOTICE '✅ Table projects existe';
    ELSE
        RAISE NOTICE '❌ Table projects n''existe pas';
    END IF;
    
    -- tasks
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'tasks') THEN
        RAISE NOTICE '✅ Table tasks existe';
    ELSE
        RAISE NOTICE '❌ Table tasks n''existe pas';
    END IF;
END $$;

-- 5. Lister toutes les politiques RLS
DO $$
DECLARE
    policy_count INTEGER;
    rec RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🛡️ === POLITIQUES RLS ===';
    
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies;
    
    IF policy_count > 0 THEN
        RAISE NOTICE '📊 Total: % politiques RLS';
        
        FOR rec IN 
            SELECT schemaname, tablename, policyname, cmd, qual, with_check
            FROM pg_policies 
            ORDER BY tablename, policyname
        LOOP
            RAISE NOTICE '  🛡️ %.%: % (%)', rec.tablename, rec.policyname, rec.cmd, rec.qual;
        END LOOP;
    ELSE
        RAISE NOTICE '❌ Aucune politique RLS trouvée';
    END IF;
END $$;

-- 6. Vérifier les fonctions
DO $$
DECLARE
    function_count INTEGER;
    rec RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '⚙️ === FONCTIONS ===';
    
    SELECT COUNT(*) INTO function_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.prokind = 'f';
    
    IF function_count > 0 THEN
        RAISE NOTICE '📊 Total: % fonctions';
        
        FOR rec IN 
            SELECT p.proname, pg_get_function_result(p.oid) as result_type
            FROM pg_proc p
            JOIN pg_namespace n ON p.pronamespace = n.oid
            WHERE n.nspname = 'public' AND p.prokind = 'f'
            ORDER BY p.proname
        LOOP
            RAISE NOTICE '  ⚙️ %() -> %', rec.proname, rec.result_type;
        END LOOP;
    ELSE
        RAISE NOTICE '❌ Aucune fonction trouvée';
    END IF;
END $$;

-- 7. Vérifier les vues
DO $$
DECLARE
    view_count INTEGER;
    rec RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '👁️ === VUES ===';
    
    SELECT COUNT(*) INTO view_count
    FROM information_schema.views
    WHERE table_schema = 'public';
    
    IF view_count > 0 THEN
        RAISE NOTICE '📊 Total: % vues';
        
        FOR rec IN 
            SELECT table_name, view_definition
            FROM information_schema.views
            WHERE table_schema = 'public'
            ORDER BY table_name
        LOOP
            RAISE NOTICE '  👁️ %', rec.table_name;
        END LOOP;
    ELSE
        RAISE NOTICE '❌ Aucune vue trouvée';
    END IF;
END $$;

-- 8. Vérifier les index
DO $$
DECLARE
    index_count INTEGER;
    rec RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📇 === INDEX ===';
    
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes
    WHERE schemaname = 'public';
    
    IF index_count > 0 THEN
        RAISE NOTICE '📊 Total: % index';
        
        FOR rec IN 
            SELECT tablename, indexname, indexdef
            FROM pg_indexes
            WHERE schemaname = 'public'
            ORDER BY tablename, indexname
        LOOP
            RAISE NOTICE '  📇 %.%', rec.tablename, rec.indexname;
        END LOOP;
    ELSE
        RAISE NOTICE '❌ Aucun index trouvé';
    END IF;
END $$;

-- 9. Vérifier les triggers
DO $$
DECLARE
    trigger_count INTEGER;
    rec RECORD;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '⚡ === TRIGGERS ===';
    
    SELECT COUNT(*) INTO trigger_count
    FROM information_schema.triggers
    WHERE trigger_schema = 'public';
    
    IF trigger_count > 0 THEN
        RAISE NOTICE '📊 Total: % triggers';
        
        FOR rec IN 
            SELECT event_object_table, trigger_name, action_timing, event_manipulation
            FROM information_schema.triggers
            WHERE trigger_schema = 'public'
            ORDER BY event_object_table, trigger_name
        LOOP
            RAISE NOTICE '  ⚡ %.%: % %', rec.event_object_table, rec.trigger_name, rec.action_timing, rec.event_manipulation;
        END LOOP;
    ELSE
        RAISE NOTICE '❌ Aucun trigger trouvé';
    END IF;
END $$;

-- 10. Résumé final
DO $$
DECLARE
    table_count INTEGER;
    policy_count INTEGER;
    function_count INTEGER;
    view_count INTEGER;
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '📊 === RÉSUMÉ FINAL ===';
    
    SELECT COUNT(*) INTO table_count FROM pg_tables WHERE schemaname = 'public';
    SELECT COUNT(*) INTO policy_count FROM pg_policies;
    SELECT COUNT(*) INTO function_count FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.prokind = 'f';
    SELECT COUNT(*) INTO view_count FROM information_schema.views WHERE table_schema = 'public';
    
    RAISE NOTICE '📄 Tables: %', table_count;
    RAISE NOTICE '🛡️ Politiques RLS: %', policy_count;
    RAISE NOTICE '⚙️ Fonctions: %', function_count;
    RAISE NOTICE '👁️ Vues: %', view_count;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎯 === RECOMMANDATIONS ===';
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clients') THEN
        RAISE NOTICE '❌ Table clients manquante - Exécutez migrate_clients_table.sql';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'user_roles') THEN
        RAISE NOTICE '❌ Table user_roles manquante - Exécutez setup_mission_system_complete.sql';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mission_assignments') THEN
        RAISE NOTICE '❌ Tables missions manquantes - Exécutez setup_mission_system_complete.sql';
    END IF;
    
    IF policy_count = 0 THEN
        RAISE NOTICE '❌ Aucune politique RLS - Exécutez les scripts de migration';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ Diagnostic terminé !';
END $$;
