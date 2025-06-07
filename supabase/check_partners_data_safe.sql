-- Diagnostic sécurisé des partenaires - Version adaptative
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure de la fonction get_users()
SELECT 'STRUCTURE DE get_users()' as test;
SELECT * FROM get_users() LIMIT 1;

-- 2. Vérifier la structure de la table profiles directement
SELECT 'STRUCTURE DE profiles' as test;
SELECT 
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 3. Vérifier les rôles dans la table profiles (colonne réelle)
SELECT 'RÔLES DANS PROFILES (structure réelle)' as test;
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'role')
        THEN 'Colonne "role" existe'
        WHEN EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'profiles' AND column_name = 'user_role')
        THEN 'Colonne "user_role" existe'
        ELSE 'Colonne de rôle non trouvée'
    END as structure_info;

-- 4. Requête adaptative pour les rôles
DO $$
DECLARE
    role_column_name text;
    query_text text;
    result_record record;
BEGIN
    -- Détecter le nom de la colonne de rôle
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'role') THEN
        role_column_name := 'role';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'user_role') THEN
        role_column_name := 'user_role';
    ELSE
        RAISE NOTICE 'Aucune colonne de rôle trouvée dans profiles';
        RETURN;
    END IF;

    RAISE NOTICE 'Colonne de rôle détectée: %', role_column_name;

    -- Construire et exécuter la requête pour compter les rôles
    query_text := format('SELECT %I, COUNT(*) as count FROM public.profiles GROUP BY %I ORDER BY count DESC', role_column_name, role_column_name);
    
    RAISE NOTICE 'Exécution de: %', query_text;
    
    FOR result_record IN EXECUTE query_text LOOP
        RAISE NOTICE 'Rôle: %, Count: %', result_record, result_record.count;
    END LOOP;
END $$;

-- 5. Chercher des partenaires avec requête adaptative
DO $$
DECLARE
    role_column_name text;
    query_text text;
    partner_count integer := 0;
BEGIN
    -- Détecter le nom de la colonne de rôle dans profiles
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'role') THEN
        role_column_name := 'role';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'user_role') THEN
        role_column_name := 'user_role';
    ELSE
        RAISE NOTICE 'Aucune colonne de rôle trouvée';
        RETURN;
    END IF;

    -- Compter les partenaires
    query_text := format('SELECT COUNT(*) FROM public.profiles WHERE %I = ''partenaire''', role_column_name);
    EXECUTE query_text INTO partner_count;
    
    RAISE NOTICE 'Nombre de partenaires trouvés: %', partner_count;

    -- Si aucun partenaire, essayer de créer un partenaire de test
    IF partner_count = 0 THEN
        RAISE NOTICE 'Aucun partenaire trouvé, tentative de création...';
        
        -- Essayer de créer un partenaire de test
        DECLARE
            test_user_id uuid;
        BEGIN
            -- Chercher un utilisateur existant sans profil
            SELECT au.id INTO test_user_id
            FROM auth.users au
            LEFT JOIN public.profiles p ON p.user_id = au.id
            WHERE p.user_id IS NULL
            LIMIT 1;
            
            IF test_user_id IS NOT NULL THEN
                query_text := format('INSERT INTO public.profiles (user_id, email, first_name, last_name, %I, status, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6, NOW(), NOW())', role_column_name);
                
                EXECUTE query_text USING 
                    test_user_id,
                    'partenaire-test@example.com',
                    'Test',
                    'Partenaire',
                    'partenaire',
                    'actif';
                    
                RAISE NOTICE 'Partenaire de test créé avec l ID: %', test_user_id;
            ELSE
                RAISE NOTICE 'Impossible de créer un partenaire de test - aucun utilisateur disponible';
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Erreur lors de la création du partenaire de test: %', SQLERRM;
        END;
    END IF;
END $$;

-- 6. Afficher les partenaires trouvés avec requête adaptative
DO $$
DECLARE
    role_column_name text;
    query_text text;
    result_record record;
BEGIN
    -- Détecter le nom de la colonne de rôle
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'role') THEN
        role_column_name := 'role';
    ELSIF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'user_role') THEN
        role_column_name := 'user_role';
    ELSE
        RAISE NOTICE 'Aucune colonne de rôle trouvée';
        RETURN;
    END IF;

    RAISE NOTICE 'PARTENAIRES TROUVÉS:';
    
    query_text := format('SELECT p.user_id, au.email, p.first_name, p.last_name, p.%I as role, p.status FROM public.profiles p JOIN auth.users au ON au.id = p.user_id WHERE p.%I = ''partenaire'' ORDER BY p.created_at DESC', role_column_name, role_column_name);
    
    FOR result_record IN EXECUTE query_text LOOP
        RAISE NOTICE 'Partenaire: % % (%), Email: %', result_record.first_name, result_record.last_name, result_record.user_id, result_record.email;
    END LOOP;
END $$;

-- 7. Test final pour vérifier que la fonction get_users() fonctionne
SELECT 'TEST FINAL get_users()' as test;
SELECT 
    user_id,
    email,
    first_name,
    last_name,
    CASE 
        WHEN 'role' IN (SELECT column_name FROM information_schema.columns WHERE table_name = 'get_users')
        THEN 'Utilise colonne role'
        ELSE 'Utilise probablement user_role'
    END as diagnostic
FROM get_users() 
LIMIT 3; 