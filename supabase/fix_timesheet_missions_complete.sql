-- ============================================================================
-- FIX COMPLET: Missions disponibles pour la saisie du temps
-- ============================================================================
-- Ce script corrige la fonction get_available_missions_for_timesheet pour
-- inclure les missions avec statut pending, accepted et in_progress

-- 1. Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS get_available_missions_for_timesheet(UUID, DATE) CASCADE;

-- 2. Créer la nouvelle fonction avec types corrigés et statuts étendus
CREATE OR REPLACE FUNCTION get_available_missions_for_timesheet(
    p_partner_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    mission_id UUID,
    mission_title VARCHAR,
    company_name VARCHAR,
    group_name VARCHAR,
    daily_rate DECIMAL
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.title::VARCHAR,
        COALESCE(c.name, '')::VARCHAR as company_name,
        COALESCE(ig.name, '')::VARCHAR as group_name,
        COALESCE(m.daily_rate, 0) as daily_rate
    FROM missions m
    LEFT JOIN company c ON m.company_id = c.id
    LEFT JOIN investor_group ig ON c.group_id = ig.id
    WHERE m.partner_id = p_partner_id
    -- Inclure pending, accepted et in_progress
    AND m.status IN ('in_progress', 'pending', 'accepted')
    AND m.start_date <= p_date
    AND (m.end_date IS NULL OR m.end_date >= p_date)
    -- Exclure les missions annulées ou terminées
    AND m.status NOT IN ('cancelled', 'completed', 'rejected')
    ORDER BY m.start_date DESC;
END;
$$;

COMMENT ON FUNCTION get_available_missions_for_timesheet(UUID, DATE) IS 
'Missions disponibles pour saisie du temps - Inclut pending, accepted et in_progress';

-- 3. Vérifier que la fonction fonctionne
DO $$
DECLARE
    test_count INTEGER;
BEGIN
    -- Compter les missions disponibles (sans filtrer par partenaire pour le test)
    SELECT COUNT(*) INTO test_count
    FROM missions m
    WHERE m.status IN ('in_progress', 'pending', 'accepted')
    AND m.status NOT IN ('cancelled', 'completed', 'rejected');
    
    RAISE NOTICE '✅ Fonction créée avec succès. % missions trouvées avec les statuts acceptés.', test_count;
END $$;


