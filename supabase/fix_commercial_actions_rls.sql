-- ============================================================================
-- FIX: RLS pour commercial_actions - Correction des politiques de sécurité
-- ============================================================================
-- Ce script corrige les politiques RLS pour permettre l'accès aux actions
-- commerciales même si le company_id n'est pas dans profiles
-- ============================================================================

-- 1. Supprimer les anciennes politiques RLS
DROP POLICY IF EXISTS "commercial_actions_read" ON public.commercial_actions;
DROP POLICY IF EXISTS "commercial_actions_insert" ON public.commercial_actions;
DROP POLICY IF EXISTS "commercial_actions_update" ON public.commercial_actions;
DROP POLICY IF EXISTS "commercial_actions_delete" ON public.commercial_actions;

-- 2. S'assurer que RLS est activé
ALTER TABLE public.commercial_actions ENABLE ROW LEVEL SECURITY;

-- 3. Politique de lecture : Plus permissive
-- Permet l'accès si :
-- - L'utilisateur est dans la même entreprise (via profiles)
-- - L'utilisateur a créé l'action
-- - L'utilisateur est assigné à l'action
-- - L'utilisateur est le partenaire de l'action
CREATE POLICY "commercial_actions_read" ON public.commercial_actions
    FOR SELECT TO authenticated
    USING (
        -- Même entreprise via profiles
        company_id IN (
            SELECT p.company_id 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
            AND p.company_id IS NOT NULL
        )
        -- OU créateur de l'action
        OR created_by = auth.uid()
        -- OU assigné à l'action
        OR assigned_to = auth.uid()
        -- OU partenaire de l'action
        OR partner_id = auth.uid()
        -- OU admin/associé (via user_roles si profiles.company_id est NULL)
        OR EXISTS (
            SELECT 1 
            FROM public.profiles p
            WHERE p.user_id = auth.uid()
            AND p.role IN ('admin', 'associe')
        )
    );

-- 4. Politique d'insertion : Plus permissive
CREATE POLICY "commercial_actions_insert" ON public.commercial_actions
    FOR INSERT TO authenticated
    WITH CHECK (
        -- Même entreprise via profiles
        company_id IN (
            SELECT p.company_id 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
            AND p.company_id IS NOT NULL
        )
        -- OU admin/associé peut créer pour n'importe quelle entreprise
        OR EXISTS (
            SELECT 1 
            FROM public.profiles p
            WHERE p.user_id = auth.uid()
            AND p.role IN ('admin', 'associe')
        )
        -- OU l'utilisateur crée pour lui-même (company_id peut être NULL)
        OR created_by = auth.uid()
    );

-- 5. Politique de mise à jour : Plus permissive
CREATE POLICY "commercial_actions_update" ON public.commercial_actions
    FOR UPDATE TO authenticated
    USING (
        -- Créateur de l'action
        created_by = auth.uid()
        -- OU assigné à l'action
        OR assigned_to = auth.uid()
        -- OU partenaire de l'action
        OR partner_id = auth.uid()
        -- OU admin/associé de la même entreprise
        OR EXISTS (
            SELECT 1 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
            AND (
                -- Même entreprise
                (p.company_id IS NOT NULL AND p.company_id = commercial_actions.company_id)
                -- OU admin/associé global
                OR p.role IN ('admin', 'associe')
            )
        )
    )
    WITH CHECK (
        -- Mêmes conditions pour la vérification
        created_by = auth.uid()
        OR assigned_to = auth.uid()
        OR partner_id = auth.uid()
        OR EXISTS (
            SELECT 1 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
            AND (
                (p.company_id IS NOT NULL AND p.company_id = commercial_actions.company_id)
                OR p.role IN ('admin', 'associe')
            )
        )
    );

-- 6. Politique de suppression : Plus permissive
CREATE POLICY "commercial_actions_delete" ON public.commercial_actions
    FOR DELETE TO authenticated
    USING (
        -- Créateur de l'action
        created_by = auth.uid()
        -- OU admin de la même entreprise
        OR EXISTS (
            SELECT 1 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
            AND p.role = 'admin'
            AND (
                -- Même entreprise
                (p.company_id IS NOT NULL AND p.company_id = commercial_actions.company_id)
                -- OU admin global
                OR p.company_id IS NULL
            )
        )
    );

-- 7. Vérifier que les politiques sont créées
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies
WHERE tablename = 'commercial_actions'
ORDER BY policyname;

-- 8. Message de confirmation
SELECT '✅ Politiques RLS corrigées pour commercial_actions' as status;

