-- Vérifier les données des partenaires et la fonction get_users
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la fonction get_users()
SELECT 'TEST FONCTION get_users()' as test;
SELECT * FROM get_users() LIMIT 5;

-- 2. Vérifier les rôles dans la table profiles
SELECT 'RÔLES DANS PROFILES' as test;
SELECT 
    role,
    COUNT(*) as count
FROM public.profiles 
GROUP BY role
ORDER BY count DESC;

-- 3. Chercher spécifiquement les partenaires
SELECT 'PARTENAIRES DÉTAILLÉS' as test;
SELECT 
    user_id,
    email,
    first_name,
    last_name,
    role,
    status
FROM get_users() 
WHERE role = 'partenaire';

-- 4. Vérifier tous les rôles possibles (au cas où il y aurait des variations)
SELECT 'TOUS LES RÔLES POSSIBLES' as test;
SELECT DISTINCT role FROM get_users() ORDER BY role;

-- 5. Si aucun partenaire, vérifier les profils directement
SELECT 'PROFILS DIRECTS' as test;
SELECT 
    p.user_id,
    au.email,
    p.first_name,
    p.last_name,
    p.role,
    p.status
FROM public.profiles p
JOIN auth.users au ON au.id = p.user_id
WHERE p.role ILIKE '%parte%'
OR p.role = 'partenaire'
ORDER BY p.created_at DESC;

-- 6. Créer un partenaire de test si aucun n'existe
DO $$
DECLARE
    test_user_id uuid;
    test_email text := 'partenaire-test@example.com';
BEGIN
    -- Vérifier s'il y a déjà des partenaires
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles WHERE role = 'partenaire'
    ) THEN
        RAISE NOTICE 'Aucun partenaire trouvé, création d un partenaire de test...';
        
        -- Chercher un utilisateur existant sans rôle ou créer un profil de test
        SELECT au.id INTO test_user_id
        FROM auth.users au
        LEFT JOIN public.profiles p ON p.user_id = au.id
        WHERE p.user_id IS NULL
        LIMIT 1;
        
        IF test_user_id IS NOT NULL THEN
            INSERT INTO public.profiles (
                user_id,
                email,
                first_name,
                last_name,
                role,
                status,
                created_at,
                updated_at
            ) VALUES (
                test_user_id,
                test_email,
                'Test',
                'Partenaire',
                'partenaire',
                'actif',
                NOW(),
                NOW()
            );
            RAISE NOTICE 'Partenaire de test créé avec l ID: %', test_user_id;
        ELSE
            RAISE NOTICE 'Impossible de créer un partenaire de test - aucun utilisateur disponible';
        END IF;
    ELSE
        RAISE NOTICE 'Des partenaires existent déjà dans la base';
    END IF;
END $$;

-- 7. Vérification finale après création éventuelle
SELECT 'VÉRIFICATION FINALE' as test;
SELECT 
    user_id,
    email,
    first_name,
    last_name,
    role,
    status
FROM get_users() 
WHERE role = 'partenaire'
ORDER BY created_at DESC;

-- 8. Test de la requête exacte utilisée par Flutter
SELECT 'TEST REQUÊTE FLUTTER' as test;
SELECT COUNT(*) as nombre_partenaires FROM (
    SELECT * FROM get_users() WHERE role = 'partenaire'
) as partenaires; 