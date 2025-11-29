-- =============================================
-- SCRIPT DE NETTOYAGE : SUPPRESSION DES TABLES OBSOLÈTES
-- =============================================
-- Ce script supprime les tables qui ne servent plus après l'homogénéisation
-- "projet" → "mission"

-- ⚠️ ATTENTION : Ce script supprime définitivement des données !
-- ⚠️ Sauvegardez vos données importantes avant d'exécuter ce script

-- =============================================
-- 1. VÉRIFICATION PRÉALABLE
-- =============================================

-- Vérifier les tables existantes avant suppression
SELECT 'TABLES EXISTANTES AVANT NETTOYAGE' as info;
SELECT tablename as table_name, 'EXISTE' as status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN (
    'project_proposals',
    'project_proposal_documents', 
    'project_details',
    'time_extension_requests',
    'old_missions',
    'mission_assignments_old',
    'project_tasks_old'
)
ORDER BY tablename;

-- =============================================
-- 2. SUPPRESSION DES TABLES OBSOLÈTES
-- =============================================

-- Supprimer les vues obsolètes en premier
DROP VIEW IF EXISTS project_details CASCADE;
DROP VIEW IF EXISTS project_summary CASCADE;
DROP VIEW IF EXISTS project_client_view CASCADE;

-- Supprimer les tables de propositions de projets (remplacées par le système de missions)
DROP TABLE IF EXISTS public.project_proposals CASCADE;
DROP TABLE IF EXISTS public.project_proposal_documents CASCADE;

-- Supprimer les tables de demandes d'extension liées aux projets
DROP TABLE IF EXISTS public.time_extension_requests CASCADE;

-- Supprimer les tables de missions obsolètes (si elles existent)
DROP TABLE IF EXISTS public.old_missions CASCADE;
DROP TABLE IF EXISTS public.mission_assignments_old CASCADE;
DROP TABLE IF EXISTS public.project_tasks_old CASCADE;

-- Supprimer les tables de backup temporaires
DROP TABLE IF EXISTS public.projects_backup CASCADE;
DROP TABLE IF EXISTS public.tasks_backup CASCADE;
DROP TABLE IF EXISTS public.messages_backup CASCADE;

-- =============================================
-- 3. NETTOYAGE DES FONCTIONS OBSOLÈTES
-- =============================================

-- Supprimer les fonctions liées aux projets obsolètes
DROP FUNCTION IF EXISTS approve_project_proposal(UUID) CASCADE;
DROP FUNCTION IF EXISTS reject_project_proposal(UUID) CASCADE;
DROP FUNCTION IF EXISTS submit_project_proposal(VARCHAR, TEXT, DECIMAL, DECIMAL, TEXT) CASCADE;
DROP FUNCTION IF EXISTS request_time_extension(UUID, INTEGER, TEXT) CASCADE;
DROP FUNCTION IF EXISTS approve_time_extension(UUID) CASCADE;
DROP FUNCTION IF EXISTS reject_time_extension(UUID) CASCADE;

-- Supprimer les fonctions de création de projets obsolètes
DROP FUNCTION IF EXISTS create_project_for_company(VARCHAR, TEXT, VARCHAR, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS create_project_with_client(VARCHAR, UUID, TEXT, DECIMAL, DECIMAL, DECIMAL, DECIMAL, DATE, DATE) CASCADE;
DROP FUNCTION IF EXISTS assign_client_to_project(UUID, UUID) CASCADE;

-- =============================================
-- 4. NETTOYAGE DES POLITIQUES RLS OBSOLÈTES
-- =============================================

-- Supprimer les politiques RLS obsolètes
DROP POLICY IF EXISTS "project_proposals_access" ON public.project_proposals;
DROP POLICY IF EXISTS "project_proposal_documents_access" ON public.project_proposal_documents;
DROP POLICY IF EXISTS "time_extension_requests_access" ON public.time_extension_requests;
DROP POLICY IF EXISTS "projects_company_access" ON public.projects;
DROP POLICY IF EXISTS "projects_client_access" ON public.projects;

-- =============================================
-- 5. NETTOYAGE DES INDEX OBSOLÈTES
-- =============================================

-- Supprimer les index obsolètes
DROP INDEX IF EXISTS idx_project_proposals_client_id;
DROP INDEX IF EXISTS idx_project_proposals_status;
DROP INDEX IF EXISTS idx_time_extension_requests_project_id;
DROP INDEX IF EXISTS idx_time_extension_requests_status;

-- =============================================
-- 6. VÉRIFICATION POST-NETTOYAGE
-- =============================================

-- Vérifier les tables restantes
SELECT 'TABLES RESTANTES APRÈS NETTOYAGE' as info;
SELECT tablename as table_name, 'CONSERVÉE' as status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN (
    'missions',
    'notifications', 
    'partner_availability',
    'mission_proposals',
    'partner_profiles',
    'user_roles',
    'projects', -- Table principale conservée
    'tasks',   -- Table principale conservée
    'clients',
    'companies'
)
ORDER BY tablename;

-- Vérifier les fonctions restantes
SELECT 'FONCTIONS RESTANTES' as info;
SELECT routine_name as function_name, 'ACTIVE' as status
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%mission%'
ORDER BY routine_name;

-- =============================================
-- 7. RÉSUMÉ DU NETTOYAGE
-- =============================================

SELECT 'NETTOYAGE TERMINÉ' as result
UNION ALL
SELECT '✅ Tables obsolètes supprimées'
UNION ALL  
SELECT '✅ Fonctions obsolètes supprimées'
UNION ALL
SELECT '✅ Politiques RLS obsolètes supprimées'
UNION ALL
SELECT '✅ Index obsolètes supprimés'
UNION ALL
SELECT '✅ Système de missions homogénéisé';

-- =============================================
-- 8. RECOMMANDATIONS POST-NETTOYAGE
-- =============================================

SELECT 'RECOMMANDATIONS' as section
UNION ALL
SELECT '1. Vérifier que l''application fonctionne correctement'
UNION ALL
SELECT '2. Tester les fonctionnalités de missions'
UNION ALL
SELECT '3. Vérifier les permissions utilisateur'
UNION ALL
SELECT '4. Mettre à jour la documentation si nécessaire';


