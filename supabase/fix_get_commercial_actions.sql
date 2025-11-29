-- ============================================================================
-- FIX: get_commercial_actions_for_company - Correction pour afficher les actions
-- ============================================================================
-- Ce script corrige la fonction pour qu'elle récupère correctement les actions
-- commerciales même si le company_id dans profiles n'est pas défini
-- ============================================================================

-- 1. S'assurer que la vue inclut created_by
DROP VIEW IF EXISTS public.commercial_actions_view CASCADE;

CREATE OR REPLACE VIEW public.commercial_actions_view AS
SELECT 
    ca.id,
    ca.title,
    ca.description,
    ca.type,
    ca.status,
    ca.priority,
    COALESCE(c.name, '') as client_name,
    ca.contact_person,
    ca.contact_email,
    ca.contact_phone,
    ca.estimated_value,
    ca.actual_value,
    ca.due_date,
    ca.completed_date,
    ca.created_at,
    ca.updated_at,
    ca.assigned_to,
    u_assigned.email as assigned_to_email,
    p_assigned.first_name as assigned_to_first_name,
    p_assigned.last_name as assigned_to_last_name,
    ca.partner_id,
    u_partner.email as partner_email,
    p_partner.first_name as partner_first_name,
    p_partner.last_name as partner_last_name,
    ca.notes,
    ca.company_id,
    ca.created_by
FROM public.commercial_actions ca
LEFT JOIN public.company c ON ca.company_id = c.id
LEFT JOIN auth.users u_assigned ON ca.assigned_to = u_assigned.id
LEFT JOIN public.profiles p_assigned ON u_assigned.id = p_assigned.user_id
LEFT JOIN auth.users u_partner ON ca.partner_id = u_partner.id
LEFT JOIN public.profiles p_partner ON u_partner.id = p_partner.user_id;

-- 2. Supprimer l'ancienne fonction
DROP FUNCTION IF EXISTS get_commercial_actions_for_company() CASCADE;

-- 2. Créer une nouvelle version améliorée de la fonction
CREATE OR REPLACE FUNCTION get_commercial_actions_for_company()
RETURNS TABLE (
    id UUID,
    title VARCHAR,
    description TEXT,
    type VARCHAR,
    status VARCHAR,
    priority VARCHAR,
    client_name TEXT,
    contact_person TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    estimated_value DECIMAL,
    actual_value DECIMAL,
    due_date DATE,
    completed_date DATE,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    assigned_to_email TEXT,
    assigned_to_name TEXT,
    partner_email TEXT,
    partner_name TEXT,
    notes TEXT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_user_id UUID;
    v_company_id BIGINT;
BEGIN
    -- Récupérer l'ID de l'utilisateur connecté
    v_user_id := auth.uid();
    
    -- Si pas d'utilisateur authentifié, retourner une liste vide
    -- (plutôt que de lever une exception)
    IF v_user_id IS NULL THEN
        RETURN;
    END IF;
    
    -- Récupérer le company_id depuis profiles
    SELECT p.company_id INTO v_company_id
    FROM public.profiles p
    WHERE p.user_id = v_user_id
    LIMIT 1;
    
    -- Si pas de company_id dans profiles, essayer depuis user_roles
    IF v_company_id IS NULL THEN
        SELECT ur.company_id INTO v_company_id
        FROM public.user_roles ur
        WHERE ur.user_id = v_user_id
        LIMIT 1;
    END IF;
    
    -- Si toujours pas de company_id, essayer depuis company directement via created_by
    IF v_company_id IS NULL THEN
        SELECT ca.company_id INTO v_company_id
        FROM public.commercial_actions ca
        WHERE ca.created_by = v_user_id
        LIMIT 1;
    END IF;
    
    -- Si on a un company_id, filtrer par celui-ci
    IF v_company_id IS NOT NULL THEN
        RETURN QUERY
        SELECT 
            cav.id,
            cav.title,
            cav.description,
            cav.type,
            cav.status,
            cav.priority,
            cav.client_name,
            cav.contact_person,
            cav.contact_email,
            cav.contact_phone,
            cav.estimated_value,
            cav.actual_value,
            cav.due_date,
            cav.completed_date,
            cav.created_at,
            cav.updated_at,
            cav.assigned_to_email,
            COALESCE(CONCAT(cav.assigned_to_first_name, ' ', cav.assigned_to_last_name), '') as assigned_to_name,
            cav.partner_email,
            COALESCE(CONCAT(cav.partner_first_name, ' ', cav.partner_last_name), '') as partner_name,
            cav.notes
        FROM public.commercial_actions_view cav
        WHERE cav.company_id = v_company_id
        ORDER BY cav.created_at DESC;
    ELSE
        -- Fallback : retourner toutes les actions créées par l'utilisateur
        RETURN QUERY
        SELECT 
            cav.id,
            cav.title,
            cav.description,
            cav.type,
            cav.status,
            cav.priority,
            cav.client_name,
            cav.contact_person,
            cav.contact_email,
            cav.contact_phone,
            cav.estimated_value,
            cav.actual_value,
            cav.due_date,
            cav.completed_date,
            cav.created_at,
            cav.updated_at,
            cav.assigned_to_email,
            COALESCE(CONCAT(cav.assigned_to_first_name, ' ', cav.assigned_to_last_name), '') as assigned_to_name,
            cav.partner_email,
            COALESCE(CONCAT(cav.partner_first_name, ' ', cav.partner_last_name), '') as partner_name,
            cav.notes
        FROM public.commercial_actions_view cav
        WHERE cav.created_by = v_user_id
           OR cav.assigned_to = v_user_id
           OR cav.partner_id = v_user_id
        ORDER BY cav.created_at DESC;
    END IF;
END;
$$;

-- 3. Commentaire
COMMENT ON FUNCTION get_commercial_actions_for_company() IS 'Récupère les actions commerciales pour l''entreprise de l''utilisateur connecté avec fallback si company_id non trouvé';

-- 4. Message de confirmation
SELECT '✅ Fonction get_commercial_actions_for_company corrigée avec succès.' as status;

