-- ============================================
-- Script pour RÉACTIVER RLS sur la table missions
-- avec les politiques appropriées
-- ============================================

-- 1. Réactiver RLS
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;

-- 2. Supprimer les anciennes politiques si elles existent
DROP POLICY IF EXISTS "missions_select_all" ON missions;
DROP POLICY IF EXISTS "missions_insert_all" ON missions;
DROP POLICY IF EXISTS "missions_update_all" ON missions;
DROP POLICY IF EXISTS "missions_delete_admin" ON missions;
DROP POLICY IF EXISTS "missions_select_policy" ON missions;
DROP POLICY IF EXISTS "missions_insert_policy" ON missions;
DROP POLICY IF EXISTS "missions_update_policy" ON missions;
DROP POLICY IF EXISTS "missions_delete_policy" ON missions;

-- 3. Créer des politiques RLS permissives pour tous les utilisateurs authentifiés
-- (Vous pourrez les affiner plus tard selon vos besoins)

-- Politique de lecture : Tous les utilisateurs authentifiés peuvent voir toutes les missions
CREATE POLICY "missions_select_authenticated" ON missions
    FOR SELECT
    TO authenticated
    USING (true);

-- Politique d'insertion : Tous les utilisateurs authentifiés peuvent créer des missions
CREATE POLICY "missions_insert_authenticated" ON missions
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Politique de mise à jour : Tous les utilisateurs authentifiés peuvent modifier les missions
CREATE POLICY "missions_update_authenticated" ON missions
    FOR UPDATE
    TO authenticated
    USING (true);

-- Politique de suppression : Tous les utilisateurs authentifiés peuvent supprimer les missions
CREATE POLICY "missions_delete_authenticated" ON missions
    FOR DELETE
    TO authenticated
    USING (true);

-- 4. Vérifier que RLS est bien activé
SELECT 
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'missions';

-- 5. Vérifier les politiques créées
SELECT 
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'missions'
ORDER BY policyname;

COMMIT;

-- ============================================
-- NOTES :
-- 
-- Ces politiques sont TRÈS permissives (tous les utilisateurs
-- authentifiés peuvent tout faire).
-- 
-- Pour une application en production, vous devriez :
-- 1. Limiter l'accès selon le rôle (admin, associate, partner, client)
-- 2. Filtrer par company_id
-- 3. Limiter les actions selon le contexte
-- 
-- Utilisez le script fix_missions_rls_policies.sql pour des
-- politiques plus strictes basées sur les rôles.
-- ============================================

