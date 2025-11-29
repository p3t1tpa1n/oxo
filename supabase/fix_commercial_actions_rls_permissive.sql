-- ============================================================================
-- FIX: RLS permissif pour commercial_actions - TEMPORAIRE POUR TEST
-- ============================================================================
-- Ce script crée des politiques RLS très permissives pour tester l'accès
-- ATTENTION: À utiliser uniquement pour le diagnostic, puis revenir à des politiques plus strictes
-- ============================================================================

-- 1. Supprimer toutes les anciennes politiques
DROP POLICY IF EXISTS "commercial_actions_read" ON public.commercial_actions;
DROP POLICY IF EXISTS "commercial_actions_insert" ON public.commercial_actions;
DROP POLICY IF EXISTS "commercial_actions_update" ON public.commercial_actions;
DROP POLICY IF EXISTS "commercial_actions_delete" ON public.commercial_actions;

-- 2. S'assurer que RLS est activé
ALTER TABLE public.commercial_actions ENABLE ROW LEVEL SECURITY;

-- 3. Politique de lecture : TRÈS PERMISSIVE (tous les utilisateurs authentifiés)
CREATE POLICY "commercial_actions_read" ON public.commercial_actions
    FOR SELECT TO authenticated
    USING (true);  -- Permet l'accès à tous les utilisateurs authentifiés

-- 4. Politique d'insertion : Permet à tous les utilisateurs authentifiés de créer
CREATE POLICY "commercial_actions_insert" ON public.commercial_actions
    FOR INSERT TO authenticated
    WITH CHECK (true);

-- 5. Politique de mise à jour : Permet à tous les utilisateurs authentifiés de modifier
CREATE POLICY "commercial_actions_update" ON public.commercial_actions
    FOR UPDATE TO authenticated
    USING (true)
    WITH CHECK (true);

-- 6. Politique de suppression : Permet à tous les utilisateurs authentifiés de supprimer
CREATE POLICY "commercial_actions_delete" ON public.commercial_actions
    FOR DELETE TO authenticated
    USING (true);

-- 7. Vérifier que les politiques sont créées
SELECT 
    'Politiques RLS créées' as status,
    policyname,
    cmd
FROM pg_policies
WHERE tablename = 'commercial_actions'
ORDER BY policyname;

-- 8. Test : Compter les actions accessibles
SELECT 
    'Test: Actions accessibles' as test,
    COUNT(*) as total_actions
FROM public.commercial_actions;

-- 9. Message de confirmation
SELECT '⚠️ ATTENTION: Politiques RLS très permissives activées. À utiliser uniquement pour le diagnostic.' as warning;
SELECT '✅ Si les actions s\'affichent maintenant, le problème vient des politiques RLS.' as info;
SELECT '✅ Après diagnostic, exécutez fix_commercial_actions_rls.sql pour restaurer des politiques sécurisées.' as next_step;

