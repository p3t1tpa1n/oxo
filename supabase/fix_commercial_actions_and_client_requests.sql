-- ============================================================================
-- FIX: Actions Commerciales + Fonctions Demandes Clients avec PDF
-- ============================================================================
-- Ce script corrige la récupération des actions commerciales et ajoute
-- les fonctions pour les demandes clients (ajout de temps + proposition mission)
-- avec support PDF
-- ============================================================================

-- 1. Vérifier et corriger la vue commercial_actions_view
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
    ca.company_id
FROM public.commercial_actions ca
LEFT JOIN public.company c ON ca.company_id = c.id
LEFT JOIN auth.users u_assigned ON ca.assigned_to = u_assigned.id
LEFT JOIN public.profiles p_assigned ON u_assigned.id = p_assigned.user_id
LEFT JOIN auth.users u_partner ON ca.partner_id = u_partner.id
LEFT JOIN public.profiles p_partner ON u_partner.id = p_partner.user_id;

-- 2. Corriger la fonction get_commercial_actions_for_company
DROP FUNCTION IF EXISTS get_commercial_actions_for_company() CASCADE;

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
BEGIN
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
        CONCAT(cav.assigned_to_first_name, ' ', cav.assigned_to_last_name) as assigned_to_name,
        cav.partner_email,
        CONCAT(cav.partner_first_name, ' ', cav.partner_last_name) as partner_name,
        cav.notes
    FROM public.commercial_actions_view cav
    WHERE cav.company_id IN (
        SELECT p.company_id 
        FROM public.profiles p 
        WHERE p.user_id = auth.uid()
    )
    ORDER BY cav.created_at DESC;
END;
$$;

-- ============================================================================
-- 3. CRÉER LES TABLES POUR LES DEMANDES CLIENTS (si elles n'existent pas)
-- ============================================================================

-- Table pour les demandes d'extension de temps (si elle n'existe pas)
-- Note: La table existe déjà, on ajoute juste les colonnes manquantes
DO $$ 
BEGIN
    -- Créer la table si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'time_extension_requests' AND table_schema = 'public'
    ) THEN
        CREATE TABLE public.time_extension_requests (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            mission_id UUID NOT NULL,
            client_id UUID NOT NULL,
            days_requested DECIMAL(10,2) NOT NULL,
            reason TEXT NOT NULL,
            status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
            response_message TEXT,
            approved_by UUID,
            document_url TEXT,
            document_name TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            
            CONSTRAINT fk_time_extension_mission
                FOREIGN KEY (mission_id) REFERENCES public.missions(id) ON DELETE CASCADE,
            CONSTRAINT fk_time_extension_client
                FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
            CONSTRAINT fk_time_extension_approver
                FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL
        );
    END IF;
    
    -- Renommer project_id en mission_id si elle existe encore
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'time_extension_requests' 
        AND column_name = 'project_id' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.time_extension_requests 
        RENAME COLUMN project_id TO mission_id;
    END IF;
    
    -- Ajouter les colonnes document si elles n'existent pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'time_extension_requests' 
        AND column_name = 'document_url'
    ) THEN
        ALTER TABLE public.time_extension_requests 
        ADD COLUMN document_url TEXT;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'time_extension_requests' 
        AND column_name = 'document_name'
    ) THEN
        ALTER TABLE public.time_extension_requests 
        ADD COLUMN document_name TEXT;
    END IF;
END $$;

-- Table pour les propositions de mission
CREATE TABLE IF NOT EXISTS public.project_proposals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    estimated_budget DECIMAL(12,2),
    estimated_days DECIMAL(10,2),
    end_date DATE,
    client_id UUID NOT NULL,
    company_id BIGINT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    response_message TEXT,
    reviewed_by UUID,
    document_url TEXT, -- URL du document PDF
    document_name TEXT, -- Nom du fichier PDF
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT fk_proposal_client
        FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_proposal_company
        FOREIGN KEY (company_id) REFERENCES public.company(id) ON DELETE CASCADE,
    CONSTRAINT fk_proposal_reviewer
        FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL
);

-- Ajouter les colonnes document pour project_proposals si elles n'existent pas déjà
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'project_proposals' 
        AND column_name = 'document_url'
    ) THEN
        ALTER TABLE public.project_proposals 
        ADD COLUMN document_url TEXT;
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'project_proposals' 
        AND column_name = 'document_name'
    ) THEN
        ALTER TABLE public.project_proposals 
        ADD COLUMN document_name TEXT;
    END IF;
END $$;

-- ============================================================================
-- 4. FONCTIONS POUR LES DEMANDES D'EXTENSION DE TEMPS
-- ============================================================================

-- Fonction pour soumettre une demande d'extension de temps (avec PDF)
CREATE OR REPLACE FUNCTION submit_time_extension_request(
    p_mission_id UUID,
    p_days_requested DECIMAL(10,2),
    p_reason TEXT,
    p_document_url TEXT DEFAULT NULL,
    p_document_name TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    request_id UUID;
    user_company_id BIGINT;
BEGIN
    -- Vérifier que l'utilisateur est connecté
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;

    -- Récupérer la company_id de l'utilisateur
    SELECT company_id INTO user_company_id
    FROM public.profiles
    WHERE user_id = auth.uid();

    IF user_company_id IS NULL THEN
        RAISE EXCEPTION 'Profil utilisateur non trouvé';
    END IF;

    -- Vérifier que la mission appartient à la même entreprise
    IF NOT EXISTS (
        SELECT 1 FROM public.missions m
        WHERE m.id = p_mission_id AND m.company_id = user_company_id
    ) THEN
        RAISE EXCEPTION 'Mission non trouvée ou accès non autorisé';
    END IF;

    -- Insérer la demande d'extension
    INSERT INTO public.time_extension_requests (
        mission_id,
        client_id,
        days_requested,
        reason,
        status,
        document_url,
        document_name,
        created_at,
        updated_at
    ) VALUES (
        p_mission_id,
        auth.uid(),
        p_days_requested,
        p_reason,
        'pending',
        p_document_url,
        p_document_name,
        NOW(),
        NOW()
    ) RETURNING id INTO request_id;

    RETURN request_id;
END;
$$;

-- Fonction pour approuver une extension de temps
CREATE OR REPLACE FUNCTION approve_time_extension(
    p_request_id UUID,
    p_response_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    extension_record RECORD;
BEGIN
    -- Vérifier les permissions (admin ou associé)
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'associe')
    ) THEN
        RAISE EXCEPTION 'Permissions insuffisantes';
    END IF;

    -- Récupérer la demande d'extension
    SELECT * INTO extension_record
    FROM public.time_extension_requests
    WHERE id = p_request_id AND status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Demande d''extension non trouvée ou déjà traitée';
    END IF;

    -- Mettre à jour la mission avec les jours supplémentaires
    UPDATE public.missions
    SET 
        estimated_days = COALESCE(estimated_days, 0) + extension_record.days_requested,
        updated_at = NOW()
    WHERE id = extension_record.mission_id;

    -- Mettre à jour la demande comme approuvée
    UPDATE public.time_extension_requests
    SET 
        status = 'approved',
        response_message = p_response_message,
        approved_by = auth.uid(),
        updated_at = NOW()
    WHERE id = p_request_id;

    RETURN TRUE;
END;
$$;

-- Fonction pour rejeter une extension de temps
CREATE OR REPLACE FUNCTION reject_time_extension(
    p_request_id UUID,
    p_response_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier les permissions (admin ou associé)
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'associe')
    ) THEN
        RAISE EXCEPTION 'Permissions insuffisantes';
    END IF;

    -- Mettre à jour la demande comme rejetée
    UPDATE public.time_extension_requests
    SET 
        status = 'rejected',
        response_message = p_response_message,
        approved_by = auth.uid(),
        updated_at = NOW()
    WHERE id = p_request_id AND status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Demande d''extension non trouvée ou déjà traitée';
    END IF;

    RETURN TRUE;
END;
$$;

-- ============================================================================
-- 5. FONCTIONS POUR LES PROPOSITIONS DE MISSION
-- ============================================================================

-- Fonction pour soumettre une proposition de mission (avec PDF)
CREATE OR REPLACE FUNCTION submit_project_proposal(
    p_title VARCHAR(255),
    p_description TEXT,
    p_estimated_budget DECIMAL(12,2),
    p_estimated_days DECIMAL(10,2),
    p_end_date DATE DEFAULT NULL,
    p_document_url TEXT DEFAULT NULL,
    p_document_name TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    proposal_id UUID;
    user_company_id BIGINT;
BEGIN
    -- Vérifier que l'utilisateur est connecté
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non authentifié';
    END IF;

    -- Récupérer la company_id de l'utilisateur
    SELECT company_id INTO user_company_id
    FROM public.profiles
    WHERE user_id = auth.uid();

    IF user_company_id IS NULL THEN
        RAISE EXCEPTION 'Profil utilisateur non trouvé';
    END IF;

    -- Insérer la proposition
    INSERT INTO public.project_proposals (
        title,
        description,
        estimated_budget,
        estimated_days,
        end_date,
        client_id,
        company_id,
        status,
        document_url,
        document_name,
        created_at,
        updated_at
    ) VALUES (
        p_title,
        p_description,
        p_estimated_budget,
        p_estimated_days,
        p_end_date,
        auth.uid(),
        user_company_id,
        'pending',
        p_document_url,
        p_document_name,
        NOW(),
        NOW()
    ) RETURNING id INTO proposal_id;

    RETURN proposal_id;
END;
$$;

-- Fonction pour approuver une proposition et créer la mission
CREATE OR REPLACE FUNCTION approve_project_proposal(
    p_proposal_id UUID,
    p_response_message TEXT DEFAULT NULL,
    p_partner_id UUID DEFAULT NULL,
    p_daily_rate DECIMAL(10,2) DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_mission_id UUID;
    proposal_record RECORD;
BEGIN
    -- Vérifier les permissions (admin ou associé)
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'associe')
    ) THEN
        RAISE EXCEPTION 'Permissions insuffisantes';
    END IF;

    -- Récupérer la proposition
    SELECT * INTO proposal_record
    FROM public.project_proposals
    WHERE id = p_proposal_id AND status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Proposition non trouvée ou déjà traitée';
    END IF;

    -- Créer la nouvelle mission
    INSERT INTO public.missions (
        title,
        description,
        company_id,
        partner_id,
        start_date,
        end_date,
        budget,
        estimated_days,
        daily_rate,
        status,
        progress_status,
        created_at,
        updated_at
    ) VALUES (
        proposal_record.title,
        proposal_record.description,
        proposal_record.company_id,
        p_partner_id,
        CURRENT_DATE,
        proposal_record.end_date,
        proposal_record.estimated_budget,
        proposal_record.estimated_days,
        p_daily_rate,
        'accepted',
        'à_assigner',
        NOW(),
        NOW()
    ) RETURNING id INTO new_mission_id;

    -- Mettre à jour la proposition comme approuvée
    UPDATE public.project_proposals
    SET 
        status = 'approved',
        response_message = p_response_message,
        reviewed_by = auth.uid(),
        updated_at = NOW()
    WHERE id = p_proposal_id;

    RETURN new_mission_id;
END;
$$;

-- Fonction pour rejeter une proposition
CREATE OR REPLACE FUNCTION reject_project_proposal(
    p_proposal_id UUID,
    p_response_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier les permissions (admin ou associé)
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'associe')
    ) THEN
        RAISE EXCEPTION 'Permissions insuffisantes';
    END IF;

    -- Mettre à jour la proposition comme rejetée
    UPDATE public.project_proposals
    SET 
        status = 'rejected',
        response_message = p_response_message,
        reviewed_by = auth.uid(),
        updated_at = NOW()
    WHERE id = p_proposal_id AND status = 'pending';

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Proposition non trouvée ou déjà traitée';
    END IF;

    RETURN TRUE;
END;
$$;

-- ============================================================================
-- 6. FONCTIONS DE RÉCUPÉRATION POUR LES CLIENTS
-- ============================================================================

-- Fonction pour récupérer les demandes d'extension d'un client
CREATE OR REPLACE FUNCTION get_client_time_extension_requests()
RETURNS TABLE (
    id UUID,
    mission_id UUID,
    mission_title TEXT,
    days_requested DECIMAL,
    reason TEXT,
    status VARCHAR,
    response_message TEXT,
    document_url TEXT,
    document_name TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ter.id,
        ter.mission_id,
        m.title as mission_title,
        ter.days_requested,
        ter.reason,
        ter.status,
        ter.response_message,
        ter.document_url,
        ter.document_name,
        ter.created_at,
        ter.updated_at
    FROM public.time_extension_requests ter
    LEFT JOIN public.missions m ON ter.mission_id = m.id
    WHERE ter.client_id = auth.uid()
    ORDER BY ter.created_at DESC;
END;
$$;

-- Fonction pour récupérer les propositions d'un client
CREATE OR REPLACE FUNCTION get_client_project_proposals()
RETURNS TABLE (
    id UUID,
    title VARCHAR,
    description TEXT,
    estimated_budget DECIMAL,
    estimated_days DECIMAL,
    end_date DATE,
    status VARCHAR,
    response_message TEXT,
    document_url TEXT,
    document_name TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pp.id,
        pp.title,
        pp.description,
        pp.estimated_budget,
        pp.estimated_days,
        pp.end_date,
        pp.status,
        pp.response_message,
        pp.document_url,
        pp.document_name,
        pp.created_at,
        pp.updated_at
    FROM public.project_proposals pp
    WHERE pp.client_id = auth.uid()
    ORDER BY pp.created_at DESC;
END;
$$;

-- ============================================================================
-- 7. FONCTIONS DE RÉCUPÉRATION POUR LES ADMIN/ASSOCIÉS
-- ============================================================================

-- Fonction pour récupérer toutes les demandes d'extension (admin/associé)
CREATE OR REPLACE FUNCTION get_all_time_extension_requests()
RETURNS TABLE (
    id UUID,
    mission_id UUID,
    mission_title TEXT,
    client_email TEXT,
    client_name TEXT,
    days_requested DECIMAL,
    reason TEXT,
    status VARCHAR,
    response_message TEXT,
    document_url TEXT,
    document_name TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier les permissions
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'associe')
    ) THEN
        RAISE EXCEPTION 'Permissions insuffisantes';
    END IF;

    RETURN QUERY
    SELECT 
        ter.id,
        ter.mission_id,
        m.title as mission_title,
        u.email as client_email,
        CONCAT(p.first_name, ' ', p.last_name) as client_name,
        ter.days_requested,
        ter.reason,
        ter.status,
        ter.response_message,
        ter.document_url,
        ter.document_name,
        ter.created_at,
        ter.updated_at
    FROM public.time_extension_requests ter
    LEFT JOIN public.missions m ON ter.mission_id = m.id
    LEFT JOIN auth.users u ON ter.client_id = u.id
    LEFT JOIN public.profiles p ON u.id = p.user_id
    WHERE m.company_id IN (
        SELECT company_id FROM public.profiles WHERE user_id = auth.uid()
    )
    ORDER BY ter.created_at DESC;
END;
$$;

-- Fonction pour récupérer toutes les propositions (admin/associé)
CREATE OR REPLACE FUNCTION get_all_project_proposals()
RETURNS TABLE (
    id UUID,
    title VARCHAR,
    description TEXT,
    estimated_budget DECIMAL,
    estimated_days DECIMAL,
    end_date DATE,
    client_email TEXT,
    client_name TEXT,
    company_name TEXT,
    status VARCHAR,
    response_message TEXT,
    document_url TEXT,
    document_name TEXT,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier les permissions
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'associe')
    ) THEN
        RAISE EXCEPTION 'Permissions insuffisantes';
    END IF;

    RETURN QUERY
    SELECT 
        pp.id,
        pp.title,
        pp.description,
        pp.estimated_budget,
        pp.estimated_days,
        pp.end_date,
        u.email as client_email,
        CONCAT(p.first_name, ' ', p.last_name) as client_name,
        c.name as company_name,
        pp.status,
        pp.response_message,
        pp.document_url,
        pp.document_name,
        pp.created_at,
        pp.updated_at
    FROM public.project_proposals pp
    LEFT JOIN auth.users u ON pp.client_id = u.id
    LEFT JOIN public.profiles p ON u.id = p.user_id
    LEFT JOIN public.company c ON pp.company_id = c.id
    WHERE pp.company_id IN (
        SELECT company_id FROM public.profiles WHERE user_id = auth.uid()
    )
    ORDER BY pp.created_at DESC;
END;
$$;

-- ============================================================================
-- 8. INDEX POUR OPTIMISER LES REQUÊTES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_time_extension_requests_client_id 
    ON public.time_extension_requests(client_id);
CREATE INDEX IF NOT EXISTS idx_time_extension_requests_mission_id 
    ON public.time_extension_requests(mission_id);
CREATE INDEX IF NOT EXISTS idx_time_extension_requests_status 
    ON public.time_extension_requests(status);

CREATE INDEX IF NOT EXISTS idx_project_proposals_client_id 
    ON public.project_proposals(client_id);
CREATE INDEX IF NOT EXISTS idx_project_proposals_company_id 
    ON public.project_proposals(company_id);
CREATE INDEX IF NOT EXISTS idx_project_proposals_status 
    ON public.project_proposals(status);

-- ============================================================================
-- 9. MESSAGES DE CONFIRMATION
-- ============================================================================

SELECT '✅ Script exécuté avec succès!' as result;
SELECT '✅ Actions commerciales corrigées' as info;
SELECT '✅ Fonctions demandes clients créées (avec support PDF)' as info;
SELECT '✅ Tables créées: time_extension_requests, project_proposals' as info;

