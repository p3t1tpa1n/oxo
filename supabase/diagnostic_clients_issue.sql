-- =============================================
-- DIAGNOSTIC COMPLET - PROBLÈME CRÉATION CLIENTS
-- =============================================

-- 1. Vérifier l'existence de la table clients
DO $$
BEGIN
    RAISE NOTICE '🔍 === DIAGNOSTIC TABLE CLIENTS ===';
    
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clients') THEN
        RAISE NOTICE '✅ Table clients existe';
    ELSE
        RAISE NOTICE '❌ Table clients n''existe PAS - C''est le problème !';
        RAISE NOTICE '💡 Solution: Exécutez migrate_clients_table.sql';
        RETURN;
    END IF;
END $$;

-- 2. Vérifier les colonnes de la table
DO $$
BEGIN
    RAISE NOTICE '📋 === COLONNES DE LA TABLE CLIENTS ===';
    
    FOR rec IN 
        SELECT column_name, data_type, is_nullable, column_default
        FROM information_schema.columns 
        WHERE table_name = 'clients' 
        ORDER BY ordinal_position
    LOOP
        RAISE NOTICE '  - %: % (nullable: %, default: %)', 
            rec.column_name, rec.data_type, rec.is_nullable, rec.column_default;
    END LOOP;
END $$;

-- 3. Vérifier les colonnes manquantes
DO $$
DECLARE
    missing_columns TEXT[] := ARRAY[]::TEXT[];
    required_columns TEXT[] := ARRAY['id', 'name', 'email', 'phone', 'company', 'address', 'notes', 'status', 'created_by', 'created_at', 'updated_at', 'deleted_at'];
    col TEXT;
BEGIN
    RAISE NOTICE '🔍 === VÉRIFICATION COLONNES MANQUANTES ===';
    
    FOREACH col IN ARRAY required_columns
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'clients' AND column_name = col
        ) THEN
            missing_columns := array_append(missing_columns, col);
        END IF;
    END LOOP;
    
    IF array_length(missing_columns, 1) > 0 THEN
        RAISE NOTICE '❌ Colonnes manquantes: %', array_to_string(missing_columns, ', ');
        RAISE NOTICE '💡 Solution: Exécutez migrate_clients_table.sql';
    ELSE
        RAISE NOTICE '✅ Toutes les colonnes requises sont présentes';
    END IF;
END $$;

-- 4. Vérifier RLS
DO $$
BEGIN
    RAISE NOTICE '🔒 === VÉRIFICATION RLS ===';
    
    IF EXISTS (
        SELECT 1 FROM pg_class 
        WHERE relname = 'clients' AND relrowsecurity = true
    ) THEN
        RAISE NOTICE '✅ RLS est activé sur la table clients';
    ELSE
        RAISE NOTICE '❌ RLS n''est PAS activé sur la table clients';
        RAISE NOTICE '💡 Solution: ALTER TABLE clients ENABLE ROW LEVEL SECURITY;';
    END IF;
END $$;

-- 5. Vérifier les politiques RLS
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    RAISE NOTICE '🛡️ === POLITIQUES RLS ===';
    
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies 
    WHERE tablename = 'clients';
    
    IF policy_count > 0 THEN
        RAISE NOTICE '✅ % politiques RLS trouvées', policy_count;
        
        FOR rec IN 
            SELECT policyname, cmd, qual, with_check
            FROM pg_policies 
            WHERE tablename = 'clients'
        LOOP
            RAISE NOTICE '  - %: %', rec.policyname, rec.cmd;
        END LOOP;
    ELSE
        RAISE NOTICE '❌ Aucune politique RLS trouvée';
        RAISE NOTICE '💡 Solution: Exécutez migrate_clients_table.sql pour créer les politiques';
    END IF;
END $$;

-- 6. Vérifier les utilisateurs et rôles
DO $$
DECLARE
    admin_count INTEGER;
    associe_count INTEGER;
BEGIN
    RAISE NOTICE '👥 === UTILISATEURS ET RÔLES ===';
    
    SELECT COUNT(*) INTO admin_count
    FROM user_roles 
    WHERE user_role = 'admin';
    
    SELECT COUNT(*) INTO associe_count
    FROM user_roles 
    WHERE user_role = 'associe';
    
    RAISE NOTICE '👑 Admins: %', admin_count;
    RAISE NOTICE '🤝 Associés: %', associe_count;
    
    IF admin_count = 0 AND associe_count = 0 THEN
        RAISE NOTICE '❌ Aucun admin ou associé trouvé - impossible de créer des clients';
        RAISE NOTICE '💡 Solution: Créez un utilisateur avec le rôle admin ou associe';
    END IF;
END $$;

-- 7. Test d'insertion
DO $$
DECLARE
    test_user_id UUID;
    test_client_id UUID;
BEGIN
    RAISE NOTICE '🧪 === TEST D''INSERTION ===';
    
    -- Récupérer un utilisateur admin ou associé
    SELECT ur.user_id INTO test_user_id
    FROM user_roles ur
    WHERE ur.user_role IN ('admin', 'associe')
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE '👤 Utilisateur de test: %', test_user_id;
        
        BEGIN
            -- Tenter l'insertion
            INSERT INTO clients (name, email, created_by, status)
            VALUES ('Test Client', 'test@example.com', test_user_id, 'active')
            RETURNING id INTO test_client_id;
            
            RAISE NOTICE '✅ Insertion réussie: %', test_client_id;
            
            -- Nettoyer
            DELETE FROM clients WHERE id = test_client_id;
            RAISE NOTICE '🧹 Test nettoyé';
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur d''insertion: %', SQLERRM;
            RAISE NOTICE '💡 C''est probablement la cause du problème !';
        END;
        
    ELSE
        RAISE NOTICE '❌ Aucun utilisateur admin/associé pour le test';
    END IF;
END $$;

-- 8. Résumé et recommandations
DO $$
BEGIN
    RAISE NOTICE '📋 === RÉSUMÉ ET RECOMMANDATIONS ===';
    RAISE NOTICE '1. Si la table clients n''existe pas: Exécutez create_clients_table.sql';
    RAISE NOTICE '2. Si des colonnes manquent: Exécutez migrate_clients_table.sql';
    RAISE NOTICE '3. Si RLS/politiques manquent: Exécutez migrate_clients_table.sql';
    RAISE NOTICE '4. Si aucun admin/associé: Créez un utilisateur avec le bon rôle';
    RAISE NOTICE '5. Si l''insertion échoue: Vérifiez les logs d''erreur ci-dessus';
    RAISE NOTICE '';
    RAISE NOTICE '🎯 SOLUTION RECOMMANDÉE: Exécutez migrate_clients_table.sql';
END $$;


