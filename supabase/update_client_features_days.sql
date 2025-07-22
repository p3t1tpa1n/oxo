-- Mise à jour pour utiliser les jours au lieu des heures et ajouter la date de fin

-- 1. Modifier les colonnes des projets pour utiliser des jours
ALTER TABLE public.projects 
RENAME COLUMN estimated_hours TO estimated_days;

ALTER TABLE public.projects 
RENAME COLUMN worked_hours TO worked_days;

ALTER TABLE public.projects 
RENAME COLUMN hourly_rate TO daily_rate;

-- 2. Ajouter une colonne date de fin aux propositions de projets
ALTER TABLE public.project_proposals
ADD COLUMN IF NOT EXISTS end_date DATE;

ALTER TABLE public.project_proposals
RENAME COLUMN estimated_hours TO estimated_days;

-- 3. Modifier les demandes d'extension pour utiliser des jours
ALTER TABLE public.time_extension_requests
RENAME COLUMN hours_requested TO days_requested;

-- 4. Mettre à jour les fonctions existantes

-- Fonction pour soumettre une demande d'extension (jours)
CREATE OR REPLACE FUNCTION submit_time_extension_request(
    p_project_id UUID,
    p_days_requested DECIMAL(10,2),
    p_reason TEXT
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

    -- Vérifier que le projet appartient à la même entreprise
    IF NOT EXISTS (
        SELECT 1 FROM public.projects p
        WHERE p.id = p_project_id AND p.company_id = user_company_id
    ) THEN
        RAISE EXCEPTION 'Projet non trouvé ou accès non autorisé';
    END IF;

    -- Insérer la demande d'extension
    INSERT INTO public.time_extension_requests (
        project_id,
        client_id,
        days_requested,
        reason,
        status,
        created_at,
        updated_at
    ) VALUES (
        p_project_id,
        auth.uid(),
        p_days_requested,
        p_reason,
        'pending',
        NOW(),
        NOW()
    ) RETURNING id INTO request_id;

    RETURN request_id;
END;
$$;

-- Fonction pour soumettre une proposition de projet (avec jours)
CREATE OR REPLACE FUNCTION submit_project_proposal(
    p_title VARCHAR(255),
    p_description TEXT,
    p_estimated_budget DECIMAL(12,2),
    p_estimated_days DECIMAL(10,2),
    p_end_date DATE DEFAULT NULL
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
        NOW(),
        NOW()
    ) RETURNING id INTO proposal_id;

    RETURN proposal_id;
END;
$$;

-- 5. Fonction pour approuver une proposition et créer le projet
CREATE OR REPLACE FUNCTION approve_project_proposal(
    p_proposal_id UUID,
    p_response_message TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_project_id UUID;
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

    -- Créer le nouveau projet
    INSERT INTO public.projects (
        name,
        description,
        estimated_days,
        worked_days,
        daily_rate,
        company_id,
        status,
        priority,
        start_date,
        end_date,
        completion_percentage,
        created_at,
        updated_at
    ) VALUES (
        proposal_record.title,
        proposal_record.description,
        proposal_record.estimated_days,
        0,
        CASE 
            WHEN proposal_record.estimated_days > 0 AND proposal_record.estimated_budget > 0
            THEN proposal_record.estimated_budget / proposal_record.estimated_days
            ELSE NULL
        END,
        proposal_record.company_id,
        'actif',
        'medium',
        CURRENT_DATE,
        proposal_record.end_date,
        0,
        NOW(),
        NOW()
    ) RETURNING id INTO new_project_id;

    -- Mettre à jour la proposition comme approuvée
    UPDATE public.project_proposals
    SET 
        status = 'approved',
        response_message = p_response_message,
        reviewed_by = auth.uid(),
        updated_at = NOW()
    WHERE id = p_proposal_id;

    RETURN new_project_id;
END;
$$;

-- 6. Fonction pour approuver une extension de temps
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
        RAISE EXCEPTION 'Demande d\''extension non trouvée ou déjà traitée';
    END IF;

    -- Mettre à jour le projet avec les jours supplémentaires
    UPDATE public.projects
    SET 
        estimated_days = estimated_days + extension_record.days_requested,
        updated_at = NOW()
    WHERE id = extension_record.project_id;

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

-- 7. Mise à jour de la vue pour utiliser les jours
DROP VIEW IF EXISTS client_project_summary;
CREATE OR REPLACE VIEW client_project_summary AS
SELECT
    p.id,
    p.name,
    p.description,
    p.estimated_days,
    p.worked_days,
    CASE
        WHEN p.estimated_days > 0
        THEN (p.worked_days / p.estimated_days) * 100
        ELSE 0
    END as time_progress_percentage,
    p.completion_percentage as task_progress_percentage,
    p.status,
    p.priority,
    p.start_date,
    p.end_date,
    p.company_id,
    COUNT(t.id) as total_tasks,
    COUNT(CASE WHEN t.status IN ('completed', 'done') THEN 1 END) as completed_tasks
FROM public.projects p
LEFT JOIN public.tasks t ON p.id = t.project_id
GROUP BY p.id, p.name, p.description, p.estimated_days, p.worked_days,
         p.completion_percentage, p.status, p.priority, p.start_date, p.end_date, p.company_id;

-- 8. Messages de confirmation
SELECT '✅ Migration vers les jours terminée avec succès!' as result;
SELECT 'Tables mises à jour: projects, project_proposals, time_extension_requests' as info;
SELECT 'Nouvelles fonctions: approve_project_proposal, approve_time_extension' as info; 