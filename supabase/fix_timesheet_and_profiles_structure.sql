-- Corriger la structure des tables profiles et timesheet_entries
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Diagnostiquer la structure de la table profiles
SELECT 'STRUCTURE ACTUELLE PROFILES' as test;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'profiles'
ORDER BY ordinal_position;

-- 2. Diagnostiquer la structure de timesheet_entries
SELECT 'STRUCTURE ACTUELLE TIMESHEET_ENTRIES' as test;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
ORDER BY ordinal_position;

-- 3. Vérifier les contraintes FK existantes
SELECT 'CONTRAINTES FK TIMESHEET_ENTRIES' as test;
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'timesheet_entries';

-- 4. Corriger la structure de la table profiles si nécessaire
DO $$
BEGIN
    -- Ajouter user_email si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'user_email'
    ) THEN
        -- Vérifier si on a déjà un champ email
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'email'
        ) THEN
            -- Utiliser le champ email existant comme user_email
            ALTER TABLE public.profiles RENAME COLUMN email TO user_email;
            RAISE NOTICE 'Colonne email renommée en user_email';
        ELSE
            -- Ajouter une nouvelle colonne user_email
            ALTER TABLE public.profiles ADD COLUMN user_email VARCHAR(255);
            RAISE NOTICE 'Colonne user_email ajoutée';
            
            -- Essayer de remplir avec les emails des utilisateurs auth
            UPDATE public.profiles 
            SET user_email = auth.users.email 
            FROM auth.users 
            WHERE profiles.user_id = auth.users.id;
            RAISE NOTICE 'user_email rempli à partir de auth.users';
        END IF;
    END IF;
    
    -- S'assurer que user_role existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'user_role'
    ) THEN
        ALTER TABLE public.profiles ADD COLUMN user_role VARCHAR(50) DEFAULT 'client';
        RAISE NOTICE 'Colonne user_role ajoutée';
    END IF;
END $$;

-- 5. Corriger la structure de timesheet_entries
DO $$
BEGIN
    -- S'assurer que user_id référence bien auth.users.id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'timesheet_entries' AND column_name = 'user_id'
    ) THEN
        -- Supprimer l'ancienne contrainte FK si elle existe
        ALTER TABLE public.timesheet_entries 
        DROP CONSTRAINT IF EXISTS timesheet_entries_user_id_fkey;
        
        -- Ajouter la bonne contrainte FK vers auth.users
        ALTER TABLE public.timesheet_entries 
        ADD CONSTRAINT timesheet_entries_user_id_fkey 
        FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Contrainte FK user_id vers auth.users ajoutée';
    END IF;
    
    -- S'assurer que task_id a la bonne contrainte
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'timesheet_entries' AND column_name = 'task_id'
    ) THEN
        -- Supprimer l'ancienne contrainte FK si elle existe
        ALTER TABLE public.timesheet_entries 
        DROP CONSTRAINT IF EXISTS timesheet_entries_task_id_fkey;
        
        -- Ajouter la bonne contrainte FK vers tasks
        ALTER TABLE public.timesheet_entries 
        ADD CONSTRAINT timesheet_entries_task_id_fkey 
        FOREIGN KEY (task_id) REFERENCES public.tasks(id) ON DELETE CASCADE;
        
        RAISE NOTICE 'Contrainte FK task_id vers tasks ajoutée';
    END IF;
END $$;

-- 6. Créer une vue pour simplifier les requêtes timesheet avec utilisateurs
CREATE OR REPLACE VIEW timesheet_entries_with_user AS
SELECT 
    te.*,
    au.email as user_email,
    p.first_name,
    p.last_name,
    p.user_role
FROM public.timesheet_entries te
LEFT JOIN auth.users au ON te.user_id = au.id
LEFT JOIN public.profiles p ON te.user_id = p.user_id;

-- 7. Activer RLS sur la vue si nécessaire
-- (Les vues héritent des politiques RLS des tables sous-jacentes)

-- 8. Vérification finale
SELECT 'VÉRIFICATION FINALE PROFILES' as test;
SELECT 
    column_name,
    data_type,
    CASE 
        WHEN column_name IN ('user_id', 'user_email', 'user_role') THEN '✅ Requis OK'
        ELSE '📝 Optionnel'
    END as status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'profiles'
ORDER BY ordinal_position;

SELECT 'VÉRIFICATION FINALE TIMESHEET_ENTRIES' as test;
SELECT 
    column_name,
    data_type,
    CASE 
        WHEN column_name IN ('id', 'user_id', 'task_id', 'hours', 'date', 'status') THEN '✅ Requis OK'
        ELSE '📝 Optionnel'
    END as status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'timesheet_entries'
ORDER BY ordinal_position;

-- 9. Test de la vue
SELECT 'TEST VUE TIMESHEET_ENTRIES_WITH_USER' as test;
SELECT COUNT(*) as total_entries FROM timesheet_entries_with_user;

-- 10. Test des relations
SELECT 'TEST RELATIONS' as test;
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            WHERE tc.table_name = 'timesheet_entries' 
            AND tc.constraint_type = 'FOREIGN KEY'
            AND tc.constraint_name LIKE '%user_id%'
        ) THEN '✅ FK user_id OK'
        ELSE '❌ FK user_id manquante'
    END as fk_user_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            WHERE tc.table_name = 'timesheet_entries' 
            AND tc.constraint_type = 'FOREIGN KEY'
            AND tc.constraint_name LIKE '%task_id%'
        ) THEN '✅ FK task_id OK'
        ELSE '❌ FK task_id manquante'
    END as fk_task_status; 