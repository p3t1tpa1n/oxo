-- Script de diagnostic pour les profils partenaires
-- Vérifier l'état de la table partner_profiles

-- 1. Vérifier si la table existe
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'partner_profiles';

-- 2. Compter le nombre total de profils
SELECT COUNT(*) as total_profiles FROM partner_profiles;

-- 3. Voir tous les profils (si il y en a)
SELECT 
    id,
    user_id,
    first_name,
    last_name,
    email,
    questionnaire_completed,
    created_at
FROM partner_profiles
ORDER BY created_at DESC;

-- 4. Vérifier les politiques RLS
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

-- 5. Vérifier si RLS est activé
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'partner_profiles';

-- 6. Tester l'accès en tant qu'associé
-- (Cette requête simule l'accès d'un associé)
SELECT 
    'Test accès associé' as test_type,
    COUNT(*) as accessible_profiles
FROM partner_profiles
WHERE EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = '62f86bcb-3529-4aa5-a4b3-ca231f71dc2d'  -- ID de l'associé connecté
    AND user_role = 'associe'
);

-- 7. Vérifier les rôles des utilisateurs
SELECT 
    user_id,
    user_role,
    email
FROM user_roles 
WHERE user_role IN ('associe', 'partenaire')
ORDER BY user_role;
