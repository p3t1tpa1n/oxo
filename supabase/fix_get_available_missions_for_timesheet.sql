-- ============================================================================
-- FIX: get_available_missions_for_timesheet - Correction du type de retour
-- ============================================================================
-- Problème: La fonction retourne TEXT mais la signature attend VARCHAR
-- Solution: Ajouter des casts explicites ::VARCHAR

DROP FUNCTION IF EXISTS get_available_missions_for_timesheet(UUID, DATE) CASCADE;

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
        m.daily_rate
    FROM missions m
    LEFT JOIN company c ON m.company_id = c.id
    LEFT JOIN investor_group ig ON c.group_id = ig.id
    WHERE m.partner_id = p_partner_id
    AND m.status IN ('in_progress', 'pending', 'accepted') -- Inclure pending et accepted
    AND m.start_date <= p_date
    AND (m.end_date IS NULL OR m.end_date >= p_date)
    ORDER BY m.start_date DESC;
END;
$$;

COMMENT ON FUNCTION get_available_missions_for_timesheet(UUID, DATE) IS 'Missions disponibles pour saisie du temps à une date donnée - Types corrigés';

