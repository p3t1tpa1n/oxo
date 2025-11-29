-- ============================================================================
-- CORRECTION : Type de retour pour get_timesheet_report_by_partner
-- ============================================================================
-- Ce script corrige l'erreur de type dans la fonction get_timesheet_report_by_partner
-- L'erreur était : "Returned type character varying(255) does not match expected type text in column 3"
-- Solution : Caster explicitement u.email en TEXT

CREATE OR REPLACE FUNCTION get_timesheet_report_by_partner(
  p_year INTEGER,
  p_month INTEGER,
  p_company_id BIGINT DEFAULT NULL
)
RETURNS TABLE (
  partner_id UUID,
  partner_name TEXT,
  partner_email TEXT,
  total_days NUMERIC,
  total_amount NUMERIC,
  client_count BIGINT
) LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id as partner_id,
    COALESCE(p.first_name || ' ' || p.last_name, u.email)::TEXT as partner_name,
    u.email::TEXT as partner_email,
    COALESCE(SUM(te.days), 0) as total_days,
    COALESCE(SUM(te.amount), 0) as total_amount,
    COUNT(DISTINCT te.client_id) as client_count
  FROM auth.users u
  LEFT JOIN profiles p ON u.id = p.user_id
  LEFT JOIN timesheet_entries te ON u.id = te.partner_id
    AND EXTRACT(YEAR FROM te.entry_date) = p_year
    AND EXTRACT(MONTH FROM te.entry_date) = p_month
    AND (p_company_id IS NULL OR te.company_id = p_company_id)
  GROUP BY u.id, p.first_name, p.last_name, u.email
  HAVING SUM(te.days) > 0
  ORDER BY total_amount DESC;
END;
$$;

COMMENT ON FUNCTION get_timesheet_report_by_partner IS 'Rapport mensuel par partenaire en jours - Version corrigée avec cast TEXT';


