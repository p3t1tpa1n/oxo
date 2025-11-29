-- ============================================
-- ⚠️ SCRIPT TEMPORAIRE DE DIAGNOSTIC
-- Ce script désactive RLS pour tester si c'est la cause du problème
-- À RÉACTIVER IMMÉDIATEMENT APRÈS LE TEST !
-- ============================================

-- 1. Désactiver RLS sur la table missions
ALTER TABLE missions DISABLE ROW LEVEL SECURITY;

-- 2. Vérifier que RLS est bien désactivé
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'missions';

-- 3. Tester la récupération des missions
SELECT 
    id,
    title,
    status,
    progress_status,
    company_id,
    created_at
FROM missions
ORDER BY created_at DESC
LIMIT 10;

-- ============================================
-- ⚠️ IMPORTANT: Après avoir testé l'application,
-- exécutez le script enable_rls.sql pour réactiver RLS !
-- ============================================

COMMIT;

