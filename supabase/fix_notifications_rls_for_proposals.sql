-- ============================================================================
-- SCRIPT: Correction RLS pour notifications (pour les propositions de mission)
-- ============================================================================

-- Option 1: Modifier la fonction pour utiliser SECURITY DEFINER
-- (Déjà fait dans setup_mission_proposals.sql)

-- Option 2: Ajouter une politique RLS pour permettre l'insertion système
-- Vérifier si la table notifications existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
        -- Supprimer la politique existante si elle existe
        DROP POLICY IF EXISTS "System can create notifications for proposals" ON notifications;
        
        -- Créer une politique qui permet l'insertion depuis les triggers
        -- Cette politique permet aux fonctions SECURITY DEFINER d'insérer
        CREATE POLICY "System can create notifications for proposals" ON notifications
            FOR INSERT
            WITH CHECK (true);
        
        RAISE NOTICE '✅ Politique RLS créée pour notifications (propositions)';
    ELSE
        RAISE NOTICE '⚠️  Table notifications n''existe pas - politique non créée';
    END IF;
END $$;

-- Option 3: Mettre à jour la fonction pour utiliser SECURITY DEFINER (si pas déjà fait)
CREATE OR REPLACE FUNCTION notify_new_mission_proposal()
RETURNS TRIGGER
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Vérifier si la table notifications existe avant d'insérer
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
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

-- Vérification
DO $$
BEGIN
    RAISE NOTICE '✅ Fonction notify_new_mission_proposal mise à jour avec SECURITY DEFINER';
END $$;

-- ============================================================================
-- IMPORTANT: Ajouter 'mission_proposal' aux types de notifications autorisés
-- ============================================================================
-- Exécuter aussi: supabase/add_mission_proposal_to_notifications_type.sql

