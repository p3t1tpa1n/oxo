-- =============================================
-- TEST DE LA TABLE CLIENTS
-- =============================================

-- Vérifier si la table clients existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clients') THEN
        RAISE NOTICE '✅ Table clients existe';
        
        -- Lister les colonnes
        RAISE NOTICE '📋 Colonnes de la table clients:';
        FOR rec IN 
            SELECT column_name, data_type, is_nullable, column_default
            FROM information_schema.columns 
            WHERE table_name = 'clients' 
            ORDER BY ordinal_position
        LOOP
            RAISE NOTICE '  - %: % (nullable: %, default: %)', 
                rec.column_name, rec.data_type, rec.is_nullable, rec.column_default;
        END LOOP;
        
    ELSE
        RAISE NOTICE '❌ Table clients n''existe pas';
    END IF;
END $$;

-- Tester l'insertion d'un client de test
DO $$
DECLARE
    test_user_id UUID;
    test_client_id UUID;
BEGIN
    -- Récupérer un utilisateur admin ou associé pour le test
    SELECT ur.user_id INTO test_user_id
    FROM user_roles ur
    WHERE ur.user_role IN ('admin', 'associe')
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE '👤 Utilisateur de test trouvé: %', test_user_id;
        
        -- Tenter d'insérer un client de test
        BEGIN
            INSERT INTO clients (name, email, created_by, status)
            VALUES ('Client Test', 'test@example.com', test_user_id, 'active')
            RETURNING id INTO test_client_id;
            
            RAISE NOTICE '✅ Client de test créé avec succès: %', test_client_id;
            
            -- Nettoyer le client de test
            DELETE FROM clients WHERE id = test_client_id;
            RAISE NOTICE '🧹 Client de test supprimé';
            
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors de l''insertion: %', SQLERRM;
        END;
        
    ELSE
        RAISE NOTICE '❌ Aucun utilisateur admin/associé trouvé pour le test';
    END IF;
END $$;

-- Vérifier les politiques RLS
DO $$
BEGIN
    RAISE NOTICE '🔒 Politiques RLS sur la table clients:';
    FOR rec IN 
        SELECT policyname, cmd, qual, with_check
        FROM pg_policies 
        WHERE tablename = 'clients'
    LOOP
        RAISE NOTICE '  - %: % (qual: %, with_check: %)', 
            rec.policyname, rec.cmd, rec.qual, rec.with_check;
    END LOOP;
END $$;

-- Message final
DO $$
BEGIN
    RAISE NOTICE '🎯 Test terminé !';
    RAISE NOTICE '📝 Si vous voyez des erreurs, exécutez d''abord migrate_clients_table.sql';
END $$;


