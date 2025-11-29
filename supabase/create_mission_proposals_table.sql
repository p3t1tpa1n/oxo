-- Script pour créer la table mission_proposals
-- Cette table gère les propositions de missions entre associés et partenaires

-- 1. Création de la table mission_proposals
CREATE TABLE IF NOT EXISTS mission_proposals (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    mission_id uuid REFERENCES missions(id) ON DELETE CASCADE,
    partner_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    associate_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    proposed_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    status text DEFAULT 'pending', -- pending, accepted, rejected
    response_at timestamp with time zone,
    response_notes text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- 2. Création des index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_mission_proposals_mission_id ON mission_proposals(mission_id);
CREATE INDEX IF NOT EXISTS idx_mission_proposals_partner_id ON mission_proposals(partner_id);
CREATE INDEX IF NOT EXISTS idx_mission_proposals_associate_id ON mission_proposals(associate_id);
CREATE INDEX IF NOT EXISTS idx_mission_proposals_status ON mission_proposals(status);
CREATE INDEX IF NOT EXISTS idx_mission_proposals_proposed_at ON mission_proposals(proposed_at);

-- 3. Politiques RLS
ALTER TABLE mission_proposals ENABLE ROW LEVEL SECURITY;

-- Politique pour que les associés voient leurs propositions
CREATE POLICY "Associates can view their proposals" ON mission_proposals
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND user_role = 'associe'
        )
        AND associate_id = auth.uid()
    );

-- Politique pour que les partenaires voient les propositions qui leur sont faites
CREATE POLICY "Partners can view their proposals" ON mission_proposals
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND user_role = 'partenaire'
        )
        AND partner_id = auth.uid()
    );

-- Politique pour que les associés créent des propositions
CREATE POLICY "Associates can create proposals" ON mission_proposals
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND user_role = 'associe'
        )
        AND associate_id = auth.uid()
    );

-- Politique pour que les partenaires mettent à jour le statut des propositions
CREATE POLICY "Partners can update proposal status" ON mission_proposals
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND user_role = 'partenaire'
        )
        AND partner_id = auth.uid()
    );

-- Politique pour que les admins voient toutes les propositions
CREATE POLICY "Admins can view all proposals" ON mission_proposals
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND user_role = 'admin'
        )
    );

-- 4. Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_mission_proposals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. Trigger pour updated_at
CREATE TRIGGER update_mission_proposals_updated_at
    BEFORE UPDATE ON mission_proposals
    FOR EACH ROW
    EXECUTE FUNCTION update_mission_proposals_updated_at();

-- 6. Fonction pour notifier lors d'une nouvelle proposition
CREATE OR REPLACE FUNCTION notify_new_mission_proposal()
RETURNS TRIGGER AS $$
BEGIN
    -- Insérer une notification pour le partenaire
    INSERT INTO notifications (
        user_id,
        title,
        message,
        type,
        is_read,
        created_at
    ) VALUES (
        NEW.partner_id,
        'Nouvelle mission proposée',
        'Une nouvelle mission vous a été proposée',
        'mission_proposal',
        false,
        timezone('utc'::text, now())
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Trigger pour les notifications
CREATE TRIGGER notify_new_mission_proposal_trigger
    AFTER INSERT ON mission_proposals
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_mission_proposal();

-- 8. Vérification de la création
SELECT 
    'Table mission_proposals créée' as info,
    COUNT(*) as policies_count
FROM information_schema.table_constraints
WHERE table_name = 'mission_proposals';

-- 9. Afficher la structure de la table
SELECT 
    'Structure mission_proposals' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'mission_proposals'
ORDER BY ordinal_position;


