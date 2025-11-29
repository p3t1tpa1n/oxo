-- ============================================
-- Script pour RÉACTIVER RLS après le test
-- ============================================

-- 1. Réactiver RLS sur la table missions
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;

-- 2. Vérifier que RLS est bien réactivé
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'missions';

-- 3. Appliquer les politiques RLS corrigées
-- (Exécutez ensuite fix_missions_rls_policies.sql)

COMMIT;

