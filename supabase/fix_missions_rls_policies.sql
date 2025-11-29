-- ============================================
-- Script pour corriger les politiques RLS sur la table missions
-- ============================================

-- 1. Supprimer toutes les anciennes politiques RLS sur missions
DROP POLICY IF EXISTS "Users can view their company missions" ON missions;
DROP POLICY IF EXISTS "Users can insert missions" ON missions;
DROP POLICY IF EXISTS "Users can update missions" ON missions;
DROP POLICY IF EXISTS "Users can delete missions" ON missions;
DROP POLICY IF EXISTS "Admins can view all missions" ON missions;
DROP POLICY IF EXISTS "Partners can view assigned missions" ON missions;
DROP POLICY IF EXISTS "Clients can view their missions" ON missions;
DROP POLICY IF EXISTS "Associates can view company missions" ON missions;
DROP POLICY IF EXISTS "Enable read access for all users" ON missions;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON missions;
DROP POLICY IF EXISTS "Enable update for users based on company_id" ON missions;
DROP POLICY IF EXISTS "Enable delete for users based on company_id" ON missions;

-- 2. Activer RLS sur la table missions
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;

-- 3. Créer des politiques RLS simples et permissives

-- Politique de lecture : Tous les utilisateurs authentifiés peuvent voir toutes les missions de leur entreprise
CREATE POLICY "missions_select_policy" ON missions
    FOR SELECT
    TO authenticated
    USING (
        -- Admin peut tout voir
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_roles.user_id = auth.uid()
            AND user_roles.role = 'admin'
        )
        OR
        -- Partenaire peut voir les missions qui lui sont assignées
        (
            partner_id = auth.uid()
            AND EXISTS (
                SELECT 1 FROM user_roles
                WHERE user_roles.user_id = auth.uid()
                AND user_roles.role = 'partner'
            )
        )
        OR
        -- Client peut voir ses propres missions
        (
            client_id = auth.uid()
            AND EXISTS (
                SELECT 1 FROM user_roles
                WHERE user_roles.user_id = auth.uid()
                AND user_roles.role = 'client'
            )
        )
        OR
        -- Associé peut voir toutes les missions de son entreprise
        (
            EXISTS (
                SELECT 1 FROM user_roles ur1
                WHERE ur1.user_id = auth.uid()
                AND ur1.role = 'associate'
                AND ur1.company_id = missions.company_id
            )
        )
    );

-- Politique d'insertion : Admin et Associé peuvent créer des missions
CREATE POLICY "missions_insert_policy" ON missions
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_roles.user_id = auth.uid()
            AND (user_roles.role = 'admin' OR user_roles.role = 'associate')
        )
    );

-- Politique de mise à jour : Admin, Associé et Partenaire assigné peuvent modifier
CREATE POLICY "missions_update_policy" ON missions
    FOR UPDATE
    TO authenticated
    USING (
        -- Admin peut tout modifier
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_roles.user_id = auth.uid()
            AND user_roles.role = 'admin'
        )
        OR
        -- Associé peut modifier les missions de son entreprise
        (
            EXISTS (
                SELECT 1 FROM user_roles ur1
                WHERE ur1.user_id = auth.uid()
                AND ur1.role = 'associate'
                AND ur1.company_id = missions.company_id
            )
        )
        OR
        -- Partenaire peut modifier ses missions assignées (seulement certains champs)
        (
            partner_id = auth.uid()
            AND EXISTS (
                SELECT 1 FROM user_roles
                WHERE user_roles.user_id = auth.uid()
                AND user_roles.role = 'partner'
            )
        )
    );

-- Politique de suppression : Seulement Admin
CREATE POLICY "missions_delete_policy" ON missions
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_roles.user_id = auth.uid()
            AND user_roles.role = 'admin'
        )
    );

-- 4. Vérifier les politiques créées
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE tablename = 'missions'
ORDER BY policyname;

-- 5. Tester la récupération des missions
SELECT 
    id,
    title,
    status,
    progress_status,
    partner_id,
    client_id,
    company_id,
    created_at
FROM missions
ORDER BY created_at DESC
LIMIT 10;

COMMIT;

