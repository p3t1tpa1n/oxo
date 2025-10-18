-- =============================================
-- MIGRATION DE LA TABLE CLIENTS EXISTANTE
-- =============================================

-- Ce script ajoute les colonnes manquantes à une table clients existante

-- Vérifier si la table clients existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clients') THEN
        RAISE NOTICE '📋 Table clients trouvée, ajout des colonnes manquantes...';
        
        -- Ajouter created_by si elle n'existe pas
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'clients' AND column_name = 'created_by') THEN
            ALTER TABLE clients ADD COLUMN created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE;
            RAISE NOTICE '✅ Colonne created_by ajoutée';
        ELSE
            RAISE NOTICE 'ℹ️ Colonne created_by existe déjà';
        END IF;
        
        -- Ajouter created_at si elle n'existe pas
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'clients' AND column_name = 'created_at') THEN
            ALTER TABLE clients ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
            RAISE NOTICE '✅ Colonne created_at ajoutée';
        ELSE
            RAISE NOTICE 'ℹ️ Colonne created_at existe déjà';
        END IF;
        
        -- Ajouter updated_at si elle n'existe pas
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'clients' AND column_name = 'updated_at') THEN
            ALTER TABLE clients ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
            RAISE NOTICE '✅ Colonne updated_at ajoutée';
        ELSE
            RAISE NOTICE 'ℹ️ Colonne updated_at existe déjà';
        END IF;
        
        -- Ajouter deleted_at si elle n'existe pas
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'clients' AND column_name = 'deleted_at') THEN
            ALTER TABLE clients ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
            RAISE NOTICE '✅ Colonne deleted_at ajoutée';
        ELSE
            RAISE NOTICE 'ℹ️ Colonne deleted_at existe déjà';
        END IF;
        
        -- Ajouter status si elle n'existe pas
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'clients' AND column_name = 'status') THEN
            ALTER TABLE clients ADD COLUMN status TEXT DEFAULT 'active';
            -- Ajouter la contrainte CHECK après
            ALTER TABLE clients ADD CONSTRAINT clients_status_check 
                CHECK (status IN ('active', 'inactive', 'deleted'));
            RAISE NOTICE '✅ Colonne status ajoutée';
        ELSE
            RAISE NOTICE 'ℹ️ Colonne status existe déjà';
        END IF;
        
        -- Ajouter phone si elle n'existe pas
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'clients' AND column_name = 'phone') THEN
            ALTER TABLE clients ADD COLUMN phone TEXT;
            RAISE NOTICE '✅ Colonne phone ajoutée';
        ELSE
            RAISE NOTICE 'ℹ️ Colonne phone existe déjà';
        END IF;
        
        -- Ajouter company si elle n'existe pas
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'clients' AND column_name = 'company') THEN
            ALTER TABLE clients ADD COLUMN company TEXT;
            RAISE NOTICE '✅ Colonne company ajoutée';
        ELSE
            RAISE NOTICE 'ℹ️ Colonne company existe déjà';
        END IF;
        
        -- Ajouter address si elle n'existe pas
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'clients' AND column_name = 'address') THEN
            ALTER TABLE clients ADD COLUMN address TEXT;
            RAISE NOTICE '✅ Colonne address ajoutée';
        ELSE
            RAISE NOTICE 'ℹ️ Colonne address existe déjà';
        END IF;
        
        -- Ajouter notes si elle n'existe pas
        IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                       WHERE table_name = 'clients' AND column_name = 'notes') THEN
            ALTER TABLE clients ADD COLUMN notes TEXT;
            RAISE NOTICE '✅ Colonne notes ajoutée';
        ELSE
            RAISE NOTICE 'ℹ️ Colonne notes existe déjà';
        END IF;
        
        RAISE NOTICE '🎉 Migration de la table clients terminée !';
        
    ELSE
        RAISE NOTICE '❌ Table clients non trouvée. Utilisez create_clients_table.sql pour la créer.';
    END IF;
END $$;

-- Créer les index s'ils n'existent pas
CREATE INDEX IF NOT EXISTS idx_clients_email ON clients(email);
CREATE INDEX IF NOT EXISTS idx_clients_status ON clients(status);
CREATE INDEX IF NOT EXISTS idx_clients_created_by ON clients(created_by);

-- Activer RLS si ce n'est pas déjà fait
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Créer les politiques RLS si elles n'existent pas
DO $$
BEGIN
    -- Politique pour voir les clients actifs
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'clients' AND policyname = 'Users can view active clients') THEN
        CREATE POLICY "Users can view active clients" ON clients
            FOR SELECT USING (
                status = 'active' AND (
                    EXISTS (
                        SELECT 1 FROM user_roles 
                        WHERE user_id = auth.uid() 
                        AND user_role IN ('admin', 'associe', 'partenaire')
                    )
                )
            );
        RAISE NOTICE '✅ Politique "Users can view active clients" créée';
    END IF;
    
    -- Politique pour créer des clients
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'clients' AND policyname = 'Admins and associates can create clients') THEN
        CREATE POLICY "Admins and associates can create clients" ON clients
            FOR INSERT WITH CHECK (
                EXISTS (
                    SELECT 1 FROM user_roles 
                    WHERE user_id = auth.uid() 
                    AND user_role IN ('admin', 'associe')
                )
            );
        RAISE NOTICE '✅ Politique "Admins and associates can create clients" créée';
    END IF;
    
    -- Politique pour modifier des clients
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'clients' AND policyname = 'Admins and associates can update clients') THEN
        CREATE POLICY "Admins and associates can update clients" ON clients
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM user_roles 
                    WHERE user_id = auth.uid() 
                    AND user_role IN ('admin', 'associe')
                )
            );
        RAISE NOTICE '✅ Politique "Admins and associates can update clients" créée';
    END IF;
    
    -- Politique pour supprimer des clients
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'clients' AND policyname = 'Only admins can delete clients') THEN
        CREATE POLICY "Only admins can delete clients" ON clients
            FOR UPDATE USING (
                EXISTS (
                    SELECT 1 FROM user_roles 
                    WHERE user_id = auth.uid() 
                    AND user_role = 'admin'
                )
            );
        RAISE NOTICE '✅ Politique "Only admins can delete clients" créée';
    END IF;
END $$;

-- Créer la fonction de trigger pour updated_at
CREATE OR REPLACE FUNCTION update_clients_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger si il n'existe pas
DROP TRIGGER IF EXISTS trigger_update_clients_updated_at ON clients;
CREATE TRIGGER trigger_update_clients_updated_at
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION update_clients_updated_at();

-- Créer la vue si elle n'existe pas
CREATE OR REPLACE VIEW clients_with_creator AS
SELECT 
    c.*,
    creator.email as creator_email,
    creator.raw_user_meta_data->>'first_name' as creator_first_name,
    creator.raw_user_meta_data->>'last_name' as creator_last_name
FROM clients c
LEFT JOIN auth.users creator ON c.created_by = creator.id
WHERE c.status = 'active';

-- Message final
DO $$
BEGIN
    RAISE NOTICE '🚀 Migration complète terminée !';
    RAISE NOTICE '📋 Table clients mise à jour avec toutes les colonnes nécessaires';
    RAISE NOTICE '🔒 RLS activé avec politiques de sécurité';
    RAISE NOTICE '👁️ Vue clients_with_creator créée/mise à jour';
    RAISE NOTICE '✅ La table est prête pour la création de clients !';
END $$;


