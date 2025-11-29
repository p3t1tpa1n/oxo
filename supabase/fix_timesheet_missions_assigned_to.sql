-- ============================================================================
-- FIX: Missions disponibles pour timesheet - Inclure assigned_to
-- ============================================================================
-- Problème: La fonction filtre uniquement par partner_id mais pas par assigned_to
-- Solution: Ajouter la condition OR assigned_to = p_partner_id

DROP FUNCTION IF EXISTS get_available_missions_for_timesheet(UUID, DATE) CASCADE;

CREATE OR REPLACE FUNCTION get_available_missions_for_timesheet(
    p_partner_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    id UUID,
    title VARCHAR,
    company_id INTEGER,
    company_name VARCHAR,
    city VARCHAR,
    group_id INTEGER,
    group_name VARCHAR,
    group_sector VARCHAR,
    partner_id UUID,
    partner_email VARCHAR,
    partner_first_name VARCHAR,
    partner_last_name VARCHAR,
    start_date DATE,
    end_date DATE,
    status VARCHAR,
    progress_status VARCHAR,
    budget DECIMAL,
    daily_rate DECIMAL,
    estimated_days DECIMAL,
    worked_days DECIMAL,
    completion_percentage DECIMAL,
    notes TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.title::VARCHAR,
        c.id as company_id,
        COALESCE(c.name, '')::VARCHAR as company_name,
        COALESCE(c.city, '')::VARCHAR as city,
        ig.id as group_id,
        COALESCE(ig.name, '')::VARCHAR as group_name,
        COALESCE(ig.sector, '')::VARCHAR as group_sector,
        m.partner_id,
        COALESCE(p.email, '')::VARCHAR as partner_email,
        COALESCE(p.first_name, '')::VARCHAR as partner_first_name,
        COALESCE(p.last_name, '')::VARCHAR as partner_last_name,
        m.start_date,
        m.end_date,
        COALESCE(m.status, 'pending')::VARCHAR as status,
        COALESCE(m.progress_status, 'à_assigner')::VARCHAR as progress_status,
        m.budget,
        COALESCE(m.daily_rate, 0) as daily_rate,
        m.estimated_days,
        m.worked_days,
        m.completion_percentage,
        m.notes,
        m.created_at,
        m.updated_at
    FROM missions m
    LEFT JOIN company c ON m.company_id = c.id
    LEFT JOIN investor_group ig ON c.group_id = ig.id
    LEFT JOIN profiles p ON m.partner_id = p.user_id
    -- Inclure les missions où partner_id = p_partner_id OU assigned_to = p_partner_id
    WHERE (m.partner_id = p_partner_id OR m.assigned_to = p_partner_id)
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
'Missions disponibles pour saisie du temps - Inclut partner_id ET assigned_to';

-- Vérification
DO $$
DECLARE
    test_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO test_count
    FROM missions m
    WHERE m.status IN ('in_progress', 'pending', 'accepted')
    AND m.status NOT IN ('cancelled', 'completed', 'rejected');
    
    RAISE NOTICE '✅ Fonction créée avec succès. % missions avec statuts valides.', test_count;
END $$;

