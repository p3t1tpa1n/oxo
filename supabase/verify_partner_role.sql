-- Vérifier et corriger le rôle du partenaire existant
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier les rôles actuels de tous les utilisateurs
SELECT 'RÔLES ACTUELS' as test;
SELECT 
    user_id,
    email,
    first_name,
    last_name,
    user_role,
    status
FROM get_users() 
ORDER BY email;

-- 2. Vérifier spécifiquement l'utilisateur part@gmail.com
SELECT 'UTILISATEUR PART@GMAIL.COM' as test;
SELECT 
    user_id,
    email,
    first_name,
    last_name,
    user_role,
    status
FROM get_users() 
WHERE email = 'part@gmail.com';

-- 3. Corriger le rôle si nécessaire
DO $$
DECLARE
    user_record record;
    role_column_name text;
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

    -- Vérifier l'utilisateur part@gmail.com
    SELECT * INTO user_record FROM get_users() WHERE email = 'part@gmail.com';
    
    IF FOUND THEN
        RAISE NOTICE 'Utilisateur trouvé: % % (%), Rôle actuel: %', 
                     user_record.first_name, user_record.last_name, 
                     user_record.email, user_record.user_role;
        
        -- Si le rôle n'est pas 'partenaire', le corriger
        IF user_record.user_role != 'partenaire' THEN
            RAISE NOTICE 'Correction du rôle de % vers partenaire', user_record.email;
            
            EXECUTE format('UPDATE public.profiles SET %I = $1 WHERE user_id = $2', role_column_name)
            USING 'partenaire', user_record.user_id;
            
            RAISE NOTICE 'Rôle mis à jour avec succès';
        ELSE
            RAISE NOTICE 'Le rôle est déjà correct (partenaire)';
        END IF;
    ELSE
        RAISE NOTICE 'Utilisateur part@gmail.com non trouvé';
    END IF;
END $$;

-- 4. Vérification finale
SELECT 'VÉRIFICATION FINALE' as test;
SELECT 
    user_id,
    email,
    first_name,
    last_name,
    user_role,
    status
FROM get_users() 
WHERE user_role = 'partenaire'
ORDER BY email;

-- 5. Test de la requête exacte utilisée par Flutter
SELECT 'TEST REQUÊTE FLUTTER' as test;
SELECT COUNT(*) as nombre_partenaires FROM get_users() WHERE user_role = 'partenaire'; 