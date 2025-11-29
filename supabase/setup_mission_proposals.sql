-- ============================================================================
-- SCRIPT: Création de la table mission_proposals
-- Cette table gère les propositions de missions entre associés et partenaires
-- ============================================================================

-- 1. Supprimer les fonctions existantes (si elles existent)
DROP FUNCTION IF EXISTS notify_new_mission_proposal() CASCADE;
DROP FUNCTION IF EXISTS update_mission_proposals_updated_at() CASCADE;

-- 2. Supprimer la table si elle existe (pour réexécution propre)
DROP TABLE IF EXISTS mission_proposals CASCADE;

-- 3. Création de la table mission_proposals
CREATE TABLE IF NOT EXISTS mission_proposals (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    mission_id uuid NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
    partner_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    associate_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    proposed_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected')),
    response_at timestamp with time zone,
    response_notes text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now())
);

-- 4. Création des index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_mission_proposals_mission_id ON mission_proposals(mission_id);
CREATE INDEX IF NOT EXISTS idx_mission_proposals_partner_id ON mission_proposals(partner_id);
CREATE INDEX IF NOT EXISTS idx_mission_proposals_associate_id ON mission_proposals(associate_id);
CREATE INDEX IF NOT EXISTS idx_mission_proposals_status ON mission_proposals(status);
CREATE INDEX IF NOT EXISTS idx_mission_proposals_proposed_at ON mission_proposals(proposed_at);

-- 5. Activer RLS
ALTER TABLE mission_proposals ENABLE ROW LEVEL SECURITY;

-- 6. Politiques RLS
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

-- 7. Fonction pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_mission_proposals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 8. Trigger pour updated_at
CREATE TRIGGER update_mission_proposals_updated_at
    BEFORE UPDATE ON mission_proposals
    FOR EACH ROW
    EXECUTE FUNCTION update_mission_proposals_updated_at();

-- 9. Fonction pour notifier lors d'une nouvelle proposition (optionnel - seulement si la table notifications existe)
-- Créer la fonction avec SECURITY DEFINER pour bypasser RLS
CREATE OR REPLACE FUNCTION notify_new_mission_proposal()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Vérifier si la table notifications existe avant d'insérer
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
        -- Utiliser SECURITY DEFINER pour bypasser RLS lors de l'insertion
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
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour les notifications
DROP TRIGGER IF EXISTS notify_new_mission_proposal_trigger ON mission_proposals;
CREATE TRIGGER notify_new_mission_proposal_trigger
    AFTER INSERT ON mission_proposals
    FOR EACH ROW
    EXECUTE FUNCTION notify_new_mission_proposal();

-- 10. Vérification de la création
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mission_proposals') THEN
        RAISE NOTICE '✅ Table mission_proposals créée avec succès';
    ELSE
        RAISE EXCEPTION '❌ Erreur: La table mission_proposals n''a pas pu être créée';
    END IF;
END $$;

-- 11. Afficher un résumé
SELECT 
    'mission_proposals' as table_name,
    COUNT(*) as column_count
FROM information_schema.columns
WHERE table_name = 'mission_proposals';

