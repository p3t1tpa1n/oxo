-- Diagnostic approfondi des profils partenaires

-- 1. Vérifier l'état de RLS
SELECT 
    'RLS Status' as check_type,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'partner_profiles';

-- 2. Compter les profils avec différentes méthodes
SELECT 
    'Count with RLS' as method,
    COUNT(*) as total_count
FROM partner_profiles;

-- 3. Compter sans RLS (temporaire)
ALTER TABLE partner_profiles DISABLE ROW LEVEL SECURITY;

SELECT 
    'Count without RLS' as method,
    COUNT(*) as total_count
FROM partner_profiles;

-- 4. Voir les profils sans RLS
SELECT 
    'Profiles without RLS' as info,
    id,
    user_id,
    first_name,
    last_name,
    email,
    questionnaire_completed,
    created_at
FROM partner_profiles
ORDER BY created_at DESC;

-- 5. Réactiver RLS
ALTER TABLE partner_profiles ENABLE ROW LEVEL SECURITY;

-- 6. Tester l'accès avec l'ID de l'associé connecté
SELECT 
    'Test access for associate' as test_type,
    COUNT(*) as accessible_profiles
FROM partner_profiles
WHERE EXISTS (
    SELECT 1 FROM user_roles 
    WHERE user_id = '62f86bcb-3529-4aa5-a4b3-ca231f71dc2d'  -- ID de l'associé
    AND user_role = 'associe'
);

-- 7. Tester l'accès avec la politique de fallback
SELECT 
    'Test fallback policy' as test_type,
    COUNT(*) as accessible_profiles
FROM partner_profiles
WHERE auth.uid() IS NOT NULL;

-- 8. Vérifier les rôles de l'utilisateur connecté
SELECT 
    'User roles check' as info,
    user_id,
    user_role
FROM user_roles 
WHERE user_id = '62f86bcb-3529-4aa5-a4b3-ca231f71dc2d';

-- 9. Tester une requête simple avec auth.uid()
SELECT 
    'Auth UID test' as info,
    auth.uid() as current_user_id,
    '62f86bcb-3529-4aa5-a4b3-ca231f71dc2d' as expected_user_id,
    (auth.uid() = '62f86bcb-3529-4aa5-a4b3-ca231f71dc2d') as ids_match;

-- 10. Vérifier la structure de la table
SELECT 
    'Table structure' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'partner_profiles'
ORDER BY ordinal_position;
