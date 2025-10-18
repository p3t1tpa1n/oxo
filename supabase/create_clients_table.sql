-- =============================================
-- CRÉATION DE LA TABLE CLIENTS
-- =============================================

-- Créer la table clients si elle n'existe pas
CREATE TABLE IF NOT EXISTS clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    company TEXT,
    address TEXT,
    notes TEXT,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'deleted')),
    created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

-- Si la table existe déjà, ajouter les colonnes manquantes
DO $$
BEGIN
    -- Ajouter created_by si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'clients' AND column_name = 'created_by') THEN
        ALTER TABLE clients ADD COLUMN created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- Ajouter created_at si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'clients' AND column_name = 'created_at') THEN
        ALTER TABLE clients ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Ajouter updated_at si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'clients' AND column_name = 'updated_at') THEN
        ALTER TABLE clients ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Ajouter deleted_at si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'clients' AND column_name = 'deleted_at') THEN
        ALTER TABLE clients ADD COLUMN deleted_at TIMESTAMP WITH TIME ZONE;
    END IF;
    
    -- Ajouter status si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'clients' AND column_name = 'status') THEN
        ALTER TABLE clients ADD COLUMN status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'deleted'));
    END IF;
    
    -- Ajouter phone si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'clients' AND column_name = 'phone') THEN
        ALTER TABLE clients ADD COLUMN phone TEXT;
    END IF;
    
    -- Ajouter company si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'clients' AND column_name = 'company') THEN
        ALTER TABLE clients ADD COLUMN company TEXT;
    END IF;
    
    -- Ajouter address si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'clients' AND column_name = 'address') THEN
        ALTER TABLE clients ADD COLUMN address TEXT;
    END IF;
    
    -- Ajouter notes si elle n'existe pas
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'clients' AND column_name = 'notes') THEN
        ALTER TABLE clients ADD COLUMN notes TEXT;
    END IF;
END $$;

-- Créer un index sur l'email pour les recherches rapides
CREATE INDEX IF NOT EXISTS idx_clients_email ON clients(email);
CREATE INDEX IF NOT EXISTS idx_clients_status ON clients(status);
CREATE INDEX IF NOT EXISTS idx_clients_created_by ON clients(created_by);

-- Activer RLS (Row Level Security)
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- Politiques RLS pour la table clients
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

CREATE POLICY "Admins and associates can create clients" ON clients
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role IN ('admin', 'associe')
        )
    );

CREATE POLICY "Admins and associates can update clients" ON clients
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role IN ('admin', 'associe')
        )
    );

CREATE POLICY "Only admins can delete clients" ON clients
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'admin'
        )
    );

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_clients_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mettre à jour updated_at
DROP TRIGGER IF EXISTS trigger_update_clients_updated_at ON clients;
CREATE TRIGGER trigger_update_clients_updated_at
    BEFORE UPDATE ON clients
    FOR EACH ROW
    EXECUTE FUNCTION update_clients_updated_at();

-- Vue pour les clients actifs avec informations du créateur
CREATE OR REPLACE VIEW clients_with_creator AS
SELECT 
    c.*,
    creator.email as creator_email,
    creator.raw_user_meta_data->>'first_name' as creator_first_name,
    creator.raw_user_meta_data->>'last_name' as creator_last_name
FROM clients c
LEFT JOIN auth.users creator ON c.created_by = creator.id
WHERE c.status = 'active';

-- Message de confirmation
DO $$
BEGIN
    RAISE NOTICE '✅ Table clients créée avec succès !';
    RAISE NOTICE '📋 Colonnes: id, name, email, phone, company, address, notes, status, created_by, created_at, updated_at, deleted_at';
    RAISE NOTICE '🔒 RLS activé avec politiques de sécurité';
    RAISE NOTICE '👁️ Vue clients_with_creator créée';
    RAISE NOTICE '🚀 La table est prête pour la création de clients !';
END $$;
