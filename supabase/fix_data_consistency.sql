-- Script pour harmoniser les données entre toutes les tables

-- 1. Vérifier la structure des tables
SELECT 
    'Structure user_roles' as info,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'user_roles'
ORDER BY ordinal_position;

SELECT 
    'Structure partner_profiles' as info,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'partner_profiles'
ORDER BY ordinal_position;

-- 2. Vérifier les incohérences actuelles (seulement les colonnes qui existent)
SELECT 
    'Données user_roles' as info,
    user_id,
    user_role
FROM user_roles 
WHERE user_id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';

SELECT 
    'Données partner_profiles' as info,
    user_id,
    first_name,
    last_name,
    email
FROM partner_profiles 
WHERE user_id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';

-- 2. Vérifier toutes les tables qui contiennent des informations utilisateur
SELECT 
    'Tables avec données utilisateur' as info,
    table_name,
    column_name
FROM information_schema.columns 
WHERE column_name IN ('first_name', 'last_name', 'email', 'user_id')
AND table_schema = 'public'
ORDER BY table_name, column_name;

-- 3. Harmoniser les données dans user_roles (seulement les colonnes qui existent)
-- Vérifier d'abord si les colonnes existent
DO $$
BEGIN
    -- Mettre à jour email si la colonne existe
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_roles' AND column_name = 'email') THEN
        UPDATE user_roles 
        SET email = 'part@gmail.com'
        WHERE user_id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';
    END IF;
    
    -- Mettre à jour first_name si la colonne existe
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_roles' AND column_name = 'first_name') THEN
        UPDATE user_roles 
        SET first_name = 'Pat'
        WHERE user_id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';
    END IF;
    
    -- Mettre à jour last_name si la colonne existe
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_roles' AND column_name = 'last_name') THEN
        UPDATE user_roles 
        SET last_name = 'Dumoulin'
        WHERE user_id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';
    END IF;
    
    -- Afficher un message si aucune colonne n'a été mise à jour
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_roles' AND column_name IN ('email', 'first_name', 'last_name')) THEN
        RAISE NOTICE 'Aucune colonne de données utilisateur trouvée dans user_roles';
    END IF;
END $$;

-- 4. Harmoniser les données dans partner_profiles
UPDATE partner_profiles 
SET 
    first_name = 'Pat',
    last_name = 'Dumoulin',
    email = 'part@gmail.com'
WHERE user_id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';

-- 5. Vérifier s'il y a d'autres tables avec des données utilisateur
-- Vérifier la table users (si elle existe)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'users' AND table_schema = 'public') THEN
        -- Vérifier si les colonnes existent avant de les mettre à jour
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'first_name') THEN
            UPDATE users 
            SET first_name = 'Pat'
            WHERE id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'last_name') THEN
            UPDATE users 
            SET last_name = 'Dumoulin'
            WHERE id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';
        END IF;
        
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'users' AND column_name = 'email') THEN
            UPDATE users 
            SET email = 'part@gmail.com'
            WHERE id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';
        END IF;
        
        RAISE NOTICE 'Table users trouvée et mise à jour';
    ELSE
        RAISE NOTICE 'Table users n''existe pas - ignorée';
    END IF;
END $$;

-- 6. Vérifier la table auth.users (table d'authentification Supabase)
-- Note: Cette table est gérée par Supabase, on ne peut pas la modifier directement
-- Mais on peut vérifier les données
SELECT 
    'Auth users (lecture seule)' as info,
    id,
    email,
    raw_user_meta_data->>'first_name' as first_name,
    raw_user_meta_data->>'last_name' as last_name
FROM auth.users 
WHERE id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';

-- 7. Vérifier les autres utilisateurs pour s'assurer de la cohérence
SELECT 
    'Vérification cohérence user_roles' as info,
    user_id,
    user_role
FROM user_roles 
ORDER BY user_id;

-- 8. Vérifier les profils partenaires
SELECT 
    'Vérification profils' as info,
    'partner_profiles' as table_name,
    user_id,
    first_name,
    last_name,
    email,
    questionnaire_completed
FROM partner_profiles 
ORDER BY user_id;

-- 9. Créer une fonction pour maintenir la cohérence à l'avenir
CREATE OR REPLACE FUNCTION maintain_user_data_consistency()
RETURNS TRIGGER AS $$
BEGIN
    -- Mettre à jour user_roles quand partner_profiles change (seulement si les colonnes existent)
    IF TG_TABLE_NAME = 'partner_profiles' THEN
        -- Mettre à jour email si la colonne existe
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'user_roles' AND column_name = 'email') THEN
            UPDATE user_roles 
            SET email = NEW.email
            WHERE user_id = NEW.user_id;
        END IF;
    END IF;
    
    -- Mettre à jour partner_profiles quand user_roles change (seulement si les colonnes existent)
    IF TG_TABLE_NAME = 'user_roles' THEN
        -- Mettre à jour email si la colonne existe
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'partner_profiles' AND column_name = 'email') THEN
            UPDATE partner_profiles 
            SET email = NEW.email
            WHERE user_id = NEW.user_id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 10. Créer les triggers pour maintenir la cohérence
DROP TRIGGER IF EXISTS maintain_consistency_on_partner_profiles_update ON partner_profiles;
CREATE TRIGGER maintain_consistency_on_partner_profiles_update
    AFTER UPDATE ON partner_profiles
    FOR EACH ROW
    EXECUTE FUNCTION maintain_user_data_consistency();

DROP TRIGGER IF EXISTS maintain_consistency_on_user_roles_update ON user_roles;
CREATE TRIGGER maintain_consistency_on_user_roles_update
    AFTER UPDATE ON user_roles
    FOR EACH ROW
    EXECUTE FUNCTION maintain_user_data_consistency();

-- 11. Vérification finale
SELECT 
    'Vérification finale user_roles' as info,
    user_id,
    user_role
FROM user_roles 
WHERE user_id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';

SELECT 
    'Vérification finale partner_profiles' as info,
    user_id,
    first_name,
    last_name,
    email
FROM partner_profiles 
WHERE user_id = 'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7';
