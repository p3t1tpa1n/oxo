-- ============================================================================
-- SCRIPT: Ajouter 'mission_proposal' aux types de notifications autorisés
-- ============================================================================

-- 1. Vérifier si la table notifications existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'notifications') THEN
        RAISE NOTICE '⚠️  Table notifications n''existe pas - script non applicable';
        RETURN;
    END IF;
END $$;

-- 2. Supprimer l'ancienne contrainte CHECK
ALTER TABLE notifications 
    DROP CONSTRAINT IF EXISTS notifications_type_check;

-- 3. Ajouter la nouvelle contrainte CHECK avec 'mission_proposal'
ALTER TABLE notifications 
    ADD CONSTRAINT notifications_type_check 
    CHECK (type IN ('mission_assignment', 'mission_update', 'availability_request', 'general', 'mission_proposal'));

-- 4. Vérification
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.table_constraints 
        WHERE constraint_name = 'notifications_type_check'
        AND table_name = 'notifications'
    ) THEN
        RAISE NOTICE '✅ Contrainte CHECK mise à jour avec succès';
        RAISE NOTICE '   Types autorisés: mission_assignment, mission_update, availability_request, general, mission_proposal';
    ELSE
        RAISE WARNING '⚠️  La contrainte n''a pas pu être créée';
    END IF;
END $$;

-- 5. Afficher les valeurs actuelles dans la table (pour info)
SELECT 
    'Valeurs type actuelles' as info,
    type,
    COUNT(*) as count
FROM notifications
GROUP BY type
ORDER BY type;






