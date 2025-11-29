-- =============================================
-- SUPPRESSION COMPLÈTE DE TOUTES LES TABLES "PROJECT"
-- =============================================
-- Ce script supprime définitivement toutes les tables liées aux "projects"
-- et ne garde que les "missions"

-- ⚠️ ATTENTION : Ce script supprime définitivement toutes les données de projects !

-- =============================================
-- ÉTAPE 1 : VÉRIFICATION DES TABLES EXISTANTES
-- =============================================

SELECT 'ÉTAPE 1 : Vérification des tables project existantes' as etape;

-- Lister toutes les tables contenant "project" dans le nom
SELECT 
    'Tables contenant "project"' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name LIKE '%project%'
AND table_schema = 'public'
ORDER BY table_name;

-- =============================================
-- ÉTAPE 2 : SUPPRIMER LES CONTRAINTES DE CLÉS ÉTRANGÈRES
-- =============================================

SELECT 'ÉTAPE 2 : Suppression des contraintes de clés étrangères' as etape;

-- Supprimer les contraintes FK vers projects dans toutes les tables
DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Trouver toutes les contraintes de clés étrangères qui référencent des tables project
    FOR constraint_record IN
        SELECT 
            tc.table_name,
            tc.constraint_name,
            kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu 
            ON tc.constraint_name = kcu.constraint_name
        WHERE tc.constraint_type = 'FOREIGN KEY'
        AND (
            kcu.column_name LIKE '%project%' 
            OR tc.constraint_name LIKE '%project%'
        )
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE %I DROP CONSTRAINT IF EXISTS %I CASCADE', 
                constraint_record.table_name, 
                constraint_record.constraint_name);
            RAISE NOTICE '✅ Contrainte FK supprimée: %.%', 
                constraint_record.table_name, 
                constraint_record.constraint_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Impossible de supprimer la contrainte %.%: %', 
                constraint_record.table_name, 
                constraint_record.constraint_name, 
                SQLERRM;
        END;
    END LOOP;
END $$;

-- =============================================
-- ÉTAPE 3 : SUPPRIMER LES COLONNES LIÉES AUX PROJECTS
-- =============================================

SELECT 'ÉTAPE 3 : Suppression des colonnes liées aux projects' as etape;

-- Supprimer les colonnes project_id de toutes les tables
DO $$
DECLARE
    column_record RECORD;
BEGIN
    FOR column_record IN
        SELECT table_name, column_name
        FROM information_schema.columns 
        WHERE column_name LIKE '%project%'
        AND table_schema = 'public'
        AND table_name NOT LIKE '%mission%' -- Ne pas toucher aux missions
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE %I DROP COLUMN IF EXISTS %I CASCADE', 
                column_record.table_name, 
                column_record.column_name);
            RAISE NOTICE '✅ Colonne supprimée: %.%', 
                column_record.table_name, 
                column_record.column_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Impossible de supprimer la colonne %.%: %', 
                column_record.table_name, 
                column_record.column_name, 
                SQLERRM;
        END;
    END LOOP;
END $$;

-- =============================================
-- ÉTAPE 4 : SUPPRIMER LES TABLES PROJECT
-- =============================================

SELECT 'ÉTAPE 4 : Suppression des tables project' as etape;

-- Supprimer toutes les tables contenant "project" dans le nom
DO $$
DECLARE
    table_record RECORD;
BEGIN
    FOR table_record IN
        SELECT table_name
        FROM information_schema.tables 
        WHERE table_name LIKE '%project%'
        AND table_schema = 'public'
    LOOP
        BEGIN
            EXECUTE format('DROP TABLE IF EXISTS %I CASCADE', table_record.table_name);
            RAISE NOTICE '✅ Table supprimée: %', table_record.table_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Impossible de supprimer la table %: %', 
                table_record.table_name, 
                SQLERRM;
        END;
    END LOOP;
END $$;

-- =============================================
-- ÉTAPE 5 : SUPPRIMER LES VUES LIÉES AUX PROJECTS
-- =============================================

SELECT 'ÉTAPE 5 : Suppression des vues liées aux projects' as etape;

-- Supprimer toutes les vues contenant "project" dans le nom
DO $$
DECLARE
    view_record RECORD;
BEGIN
    FOR view_record IN
        SELECT table_name
        FROM information_schema.views 
        WHERE table_name LIKE '%project%'
        AND table_schema = 'public'
    LOOP
        BEGIN
            EXECUTE format('DROP VIEW IF EXISTS %I CASCADE', view_record.table_name);
            RAISE NOTICE '✅ Vue supprimée: %', view_record.table_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Impossible de supprimer la vue %: %', 
                view_record.table_name, 
                SQLERRM;
        END;
    END LOOP;
END $$;

-- =============================================
-- ÉTAPE 6 : SUPPRIMER LES FONCTIONS LIÉES AUX PROJECTS
-- =============================================

SELECT 'ÉTAPE 6 : Suppression des fonctions liées aux projects' as etape;

-- Supprimer toutes les fonctions contenant "project" dans le nom
DO $$
DECLARE
    function_record RECORD;
BEGIN
    FOR function_record IN
        SELECT routine_name
        FROM information_schema.routines 
        WHERE routine_name LIKE '%project%'
        AND routine_schema = 'public'
        AND routine_type = 'FUNCTION'
    LOOP
        BEGIN
            EXECUTE format('DROP FUNCTION IF EXISTS %I CASCADE', function_record.routine_name);
            RAISE NOTICE '✅ Fonction supprimée: %', function_record.routine_name;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Impossible de supprimer la fonction %: %', 
                function_record.routine_name, 
                SQLERRM;
        END;
    END LOOP;
END $$;

-- =============================================
-- ÉTAPE 7 : SUPPRIMER LES TRIGGERS LIÉS AUX PROJECTS
-- =============================================

SELECT 'ÉTAPE 7 : Suppression des triggers liés aux projects' as etape;

-- Supprimer tous les triggers contenant "project" dans le nom
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN
        SELECT trigger_name, event_object_table
        FROM information_schema.triggers 
        WHERE trigger_name LIKE '%project%'
        AND trigger_schema = 'public'
    LOOP
        BEGIN
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON %I CASCADE', 
                trigger_record.trigger_name, 
                trigger_record.event_object_table);
            RAISE NOTICE '✅ Trigger supprimé: % sur %', 
                trigger_record.trigger_name, 
                trigger_record.event_object_table;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Impossible de supprimer le trigger %: %', 
                trigger_record.trigger_name, 
                SQLERRM;
        END;
    END LOOP;
END $$;

-- =============================================
-- ÉTAPE 8 : SUPPRIMER LES INDEX LIÉS AUX PROJECTS
-- =============================================

SELECT 'ÉTAPE 8 : Suppression des index liés aux projects' as etape;

-- Supprimer tous les index contenant "project" dans le nom
DO $$
DECLARE
    index_record RECORD;
BEGIN
    FOR index_record IN
        SELECT indexname, tablename
        FROM pg_indexes 
        WHERE indexname LIKE '%project%'
        AND schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('DROP INDEX IF EXISTS %I CASCADE', index_record.indexname);
            RAISE NOTICE '✅ Index supprimé: % sur %', 
                index_record.indexname, 
                index_record.tablename;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '⚠️ Impossible de supprimer l''index %: %', 
                index_record.indexname, 
                SQLERRM;
        END;
    END LOOP;
END $$;

-- =============================================
-- ÉTAPE 9 : VÉRIFICATION FINALE
-- =============================================

SELECT 'ÉTAPE 9 : Vérification finale' as etape;

-- Vérifier qu'il ne reste plus de tables project
SELECT 
    'Tables restantes avec "project"' as info,
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name LIKE '%project%'
AND table_schema = 'public';

-- Vérifier qu'il ne reste plus de colonnes project
SELECT 
    'Colonnes restantes avec "project"' as info,
    table_name,
    column_name
FROM information_schema.columns 
WHERE column_name LIKE '%project%'
AND table_schema = 'public';

-- Vérifier qu'il ne reste plus de vues project
SELECT 
    'Vues restantes avec "project"' as info,
    table_name
FROM information_schema.views 
WHERE table_name LIKE '%project%'
AND table_schema = 'public';

-- Vérifier qu'il ne reste plus de fonctions project
SELECT 
    'Fonctions restantes avec "project"' as info,
    routine_name
FROM information_schema.routines 
WHERE routine_name LIKE '%project%'
AND routine_schema = 'public';

-- =============================================
-- ÉTAPE 10 : MISE À JOUR DES COMMENTAIRES
-- =============================================

SELECT 'ÉTAPE 10 : Mise à jour des commentaires' as etape;

-- Mettre à jour les commentaires des tables restantes
COMMENT ON TABLE missions IS 'Missions (remplace complètement les anciens projects)';
COMMENT ON TABLE mission_assignments IS 'Assignations de missions aux partenaires';
COMMENT ON TABLE time_extension_requests IS 'Demandes d''extension de temps pour les missions';

-- =============================================
-- FIN DU SCRIPT
-- =============================================

SELECT '✅ SUPPRESSION COMPLÈTE DES TABLES PROJECT TERMINÉE' as resultat;
SELECT '🎯 Seules les missions sont maintenant conservées' as resultat;
SELECT '📊 Vérifiez les résultats ci-dessus pour confirmer le nettoyage' as resultat;
