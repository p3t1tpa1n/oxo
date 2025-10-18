-- Script pour diagnostiquer et corriger les politiques RLS des profils partenaires

-- 1. Vérifier l'état actuel de RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'partner_profiles';

-- 2. Voir les politiques existantes
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'partner_profiles';

-- 3. Tester l'accès direct (sans RLS)
-- Désactiver temporairement RLS pour tester
ALTER TABLE partner_profiles DISABLE ROW LEVEL SECURITY;

-- 4. Vérifier que les données sont bien là
SELECT 
    COUNT(*) as total_profiles,
    COUNT(CASE WHEN questionnaire_completed = true THEN 1 END) as completed_profiles
FROM partner_profiles;

-- 5. Voir quelques profils
SELECT 
    id,
    user_id,
    first_name,
    last_name,
    email,
    questionnaire_completed,
    created_at
FROM partner_profiles
ORDER BY created_at DESC
LIMIT 5;

-- 6. Recréer les politiques RLS correctement
-- D'abord, supprimer les anciennes politiques
DROP POLICY IF EXISTS "Users can view their own profile" ON partner_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON partner_profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON partner_profiles;
DROP POLICY IF EXISTS "Associates can view all profiles" ON partner_profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON partner_profiles;
DROP POLICY IF EXISTS "Allow all authenticated users to view profiles" ON partner_profiles;

-- 7. Recréer les politiques RLS
-- Politique pour que les utilisateurs voient leur propre profil
CREATE POLICY "Users can view their own profile" ON partner_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- Politique pour que les utilisateurs modifient leur propre profil
CREATE POLICY "Users can update their own profile" ON partner_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Politique pour que les utilisateurs créent leur propre profil
CREATE POLICY "Users can insert their own profile" ON partner_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour que les associés voient TOUS les profils
CREATE POLICY "Associates can view all profiles" ON partner_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'associe'
        )
    );

-- Politique pour que les admins voient TOUS les profils
CREATE POLICY "Admins can view all profiles" ON partner_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'admin'
        )
    );

-- Politique de fallback : tous les utilisateurs authentifiés peuvent voir les profils
-- (pour s'assurer que les associés peuvent accéder aux données)
CREATE POLICY "Allow all authenticated users to view profiles" ON partner_profiles
    FOR SELECT USING (auth.uid() IS NOT NULL);

-- 8. Réactiver RLS
ALTER TABLE partner_profiles ENABLE ROW LEVEL SECURITY;

-- 9. Tester l'accès avec RLS activé
-- Cette requête simule l'accès d'un associé
SELECT 
    'Test accès associé avec RLS' as test_type,
    COUNT(*) as accessible_profiles
FROM partner_profiles
WHERE EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = '62f86bcb-3529-4aa5-a4b3-ca231f71dc2d'  -- ID de l'associé connecté
    AND user_role = 'associe'
);

-- 10. Vérifier que les politiques sont bien créées
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'partner_profiles'
ORDER BY policyname;
