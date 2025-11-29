-- =============================================
-- SUPPRESSION COMPLÈTE DES TÂCHES
-- =============================================
-- Ce script supprime toutes les références aux "tâches" 
-- et ne garde que les "missions"

-- ⚠️ ATTENTION : Ce script supprime définitivement toutes les données de tâches !

-- =============================================
-- ÉTAPE 1 : SUPPRIMER LES CONTRAINTES DE CLÉS ÉTRANGÈRES
-- =============================================

SELECT 'ÉTAPE 1 : Suppression des contraintes de clés étrangères' as etape;

-- Supprimer les contraintes FK vers tasks dans time_extension_requests
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name LIKE '%task_id%' 
        AND table_name = 'time_extension_requests'
    ) THEN
        ALTER TABLE time_extension_requests DROP CONSTRAINT IF EXISTS time_extension_requests_task_id_fkey;
        RAISE NOTICE '✅ Contrainte FK task_id supprimée de time_extension_requests';
    END IF;
END $$;

-- =============================================
-- ÉTAPE 2 : SUPPRIMER LES TABLES DE TÂCHES
-- =============================================

SELECT 'ÉTAPE 2 : Suppression des tables de tâches' as etape;

-- Supprimer la table tasks
DROP TABLE IF EXISTS tasks CASCADE;

-- Supprimer la table task_assignments
DROP TABLE IF EXISTS task_assignments CASCADE;

-- Supprimer la table task_comments
DROP TABLE IF EXISTS task_comments CASCADE;

-- Supprimer la table task_files
DROP TABLE IF EXISTS task_files CASCADE;

-- Supprimer la table task_time_entries
DROP TABLE IF EXISTS task_time_entries CASCADE;

-- =============================================
-- ÉTAPE 3 : NETTOYER LES COLONNES LIÉES AUX TÂCHES
-- =============================================

SELECT 'ÉTAPE 3 : Nettoyage des colonnes liées aux tâches' as etape;

-- Supprimer la colonne task_id de time_extension_requests si elle existe
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'time_extension_requests' 
        AND column_name = 'task_id'
    ) THEN
        ALTER TABLE time_extension_requests DROP COLUMN task_id;
        RAISE NOTICE '✅ Colonne task_id supprimée de time_extension_requests';
    END IF;
END $$;

-- =============================================
-- ÉTAPE 4 : SUPPRIMER LES VUES ET FONCTIONS LIÉES AUX TÂCHES
-- =============================================

SELECT 'ÉTAPE 4 : Suppression des vues et fonctions liées aux tâches' as etape;

-- Supprimer les vues liées aux tâches
DROP VIEW IF EXISTS tasks_summary CASCADE;
DROP VIEW IF EXISTS task_assignments_summary CASCADE;
DROP VIEW IF EXISTS user_tasks CASCADE;

-- Supprimer les fonctions liées aux tâches
DROP FUNCTION IF EXISTS get_user_tasks(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_task_details(UUID) CASCADE;
DROP FUNCTION IF EXISTS create_task_assignment(UUID, UUID, TEXT) CASCADE;

-- =============================================
-- ÉTAPE 5 : SUPPRIMER LES POLITIQUES RLS LIÉES AUX TÂCHES
-- =============================================

SELECT 'ÉTAPE 5 : Suppression des politiques RLS liées aux tâches' as etape;

-- Les politiques RLS sont automatiquement supprimées avec les tables
-- Mais on peut vérifier qu'il n'en reste pas
SELECT 
    'Politiques RLS restantes' as info,
    COUNT(*) as count
FROM pg_policies 
WHERE tablename LIKE '%task%';

-- =============================================
-- ÉTAPE 6 : VÉRIFICATION FINALE
-- =============================================

SELECT 'ÉTAPE 6 : Vérification finale' as etape;

-- Vérifier qu'il ne reste plus de tables liées aux tâches
SELECT 
    'Tables restantes avec "task"' as info,
    table_name
FROM information_schema.tables 
WHERE table_name LIKE '%task%'
AND table_schema = 'public';

-- Vérifier qu'il ne reste plus de colonnes liées aux tâches
SELECT 
    'Colonnes restantes avec "task"' as info,
    table_name,
    column_name
FROM information_schema.columns 
WHERE column_name LIKE '%task%'
AND table_schema = 'public';

-- =============================================
-- ÉTAPE 7 : MISE À JOUR DES COMMENTAIRES
-- =============================================

SELECT 'ÉTAPE 7 : Mise à jour des commentaires' as etape;

-- Mettre à jour les commentaires des tables restantes
COMMENT ON TABLE missions IS 'Missions (remplace les anciens projets et tâches)';
COMMENT ON TABLE mission_assignments IS 'Assignations de missions aux partenaires';
COMMENT ON TABLE time_extension_requests IS 'Demandes d''extension de temps pour les missions';

-- =============================================
-- FIN DU SCRIPT
-- =============================================

SELECT '✅ SUPPRESSION COMPLÈTE DES TÂCHES TERMINÉE' as resultat;
SELECT '🎯 Seules les missions sont maintenant conservées' as resultat;
SELECT '📊 Vérifiez les résultats ci-dessus pour confirmer le nettoyage' as resultat;
