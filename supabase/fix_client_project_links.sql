-- ================================================================
-- SCRIPT : LIEN CLIENT-PROJET MANQUANT - CORRECTION COMPLÈTE
-- ================================================================
-- 
-- PROBLÈME IDENTIFIÉ :
-- 1. La table 'projects' n'a PAS de colonne 'client_id'
-- 2. La fonction approve_project_proposal ne sauvegarde pas le client
-- 3. Les associés créent des projets sans spécifier le client
--
-- SOLUTION :
-- ✅ Ajouter client_id à la table projects
-- ✅ Modifier approve_project_proposal pour inclure client_id
-- ✅ Créer une fonction pour associer des projets existants à des clients
-- ✅ Mettre à jour les vues et politiques RLS
-- ================================================================

-- 1. AJOUTER LA COLONNE CLIENT_ID À LA TABLE PROJECTS
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS client_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

-- 2. CRÉER UN INDEX POUR AMÉLIORER LES PERFORMANCES
CREATE INDEX IF NOT EXISTS projects_client_id_idx ON public.projects(client_id);

-- 3. CORRIGER LA FONCTION approve_project_proposal
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

    -- Créer le nouveau projet AVEC le client_id ✅
    INSERT INTO public.projects (
        name,
        description,
        estimated_days,
        worked_days,
        daily_rate,
        company_id,
        client_id,        -- ✅ AJOUTÉ : Lien vers le client
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
        proposal_record.client_id,  -- ✅ SAUVEGARDE DU CLIENT
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

-- 4. FONCTION POUR CRÉER UN PROJET AVEC CLIENT (pour les associés)
CREATE OR REPLACE FUNCTION create_project_with_client(
    p_name VARCHAR(255),
    p_client_id UUID,
    p_description TEXT DEFAULT NULL,
    p_estimated_days DECIMAL(10,2) DEFAULT NULL,
    p_daily_rate DECIMAL(10,2) DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_project_id UUID;
    user_company_id BIGINT;
BEGIN
    -- Vérifier les permissions (admin ou associé)
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'associe')
    ) THEN
        RAISE EXCEPTION 'Seuls les admins et associés peuvent créer des projets';
    END IF;

    -- Récupérer la company_id de l'utilisateur
    SELECT company_id INTO user_company_id
    FROM public.profiles
    WHERE user_id = auth.uid();

    IF user_company_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non assigné à une entreprise';
    END IF;

    -- Vérifier que le client appartient à la même entreprise
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = p_client_id
        AND company_id = user_company_id
        AND role = 'client'
    ) THEN
        RAISE EXCEPTION 'Le client spécifié n''appartient pas à votre entreprise';
    END IF;

    -- Créer le projet
    INSERT INTO public.projects (
        name,
        description,
        estimated_days,
        worked_days,
        daily_rate,
        company_id,
        client_id,
        status,
        priority,
        start_date,
        end_date,
        completion_percentage,
        created_at,
        updated_at
    ) VALUES (
        p_name,
        p_description,
        p_estimated_days,
        0,
        p_daily_rate,
        user_company_id,
        p_client_id,
        'actif',
        'medium',
        CURRENT_DATE,
        p_end_date,
        0,
        NOW(),
        NOW()
    ) RETURNING id INTO new_project_id;

    RETURN new_project_id;
END;
$$;

-- 5. FONCTION POUR OBTENIR LES CLIENTS D'UNE ENTREPRISE
CREATE OR REPLACE FUNCTION get_company_clients()
RETURNS TABLE (
    user_id UUID,
    email TEXT,
    first_name TEXT,
    last_name TEXT,
    full_name TEXT,
    company_id BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_company_id BIGINT;
BEGIN
    -- Récupérer la company_id de l'utilisateur connecté
    SELECT p.company_id INTO user_company_id
    FROM public.profiles p
    WHERE p.user_id = auth.uid();

    IF user_company_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non assigné à une entreprise';
    END IF;

    -- Retourner tous les clients de cette entreprise
    RETURN QUERY
    SELECT 
        p.user_id,
        p.email,
        p.first_name,
        p.last_name,
        CASE 
            WHEN p.first_name IS NOT NULL AND p.last_name IS NOT NULL 
            THEN p.first_name || ' ' || p.last_name
            ELSE COALESCE(p.email, 'Client')
        END as full_name,
        p.company_id
    FROM public.profiles p
    WHERE p.company_id = user_company_id
    AND p.role = 'client'
    ORDER BY p.first_name, p.last_name, p.email;
END;
$$;

-- 6. MISE À JOUR DES POLITIQUES RLS POUR INCLURE CLIENT_ID
-- Supprimer l'ancienne politique
DROP POLICY IF EXISTS "projects_company_access" ON public.projects;

-- Nouvelle politique incluant l'accès client
CREATE POLICY "projects_company_access"
ON public.projects
FOR ALL TO authenticated
USING (
    -- Admins et associés voient tous les projets de leur entreprise
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
        AND company_id IN (
            SELECT p2.company_id FROM public.profiles p2 
            WHERE p2.user_id = auth.uid()
        )
    )
    OR
    -- Les clients voient uniquement leurs propres projets
    (client_id = auth.uid())
    OR
    -- Partenaires voient les projets de leur entreprise
    EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.user_id = auth.uid()
        AND p.role = 'partenaire'
        AND p.company_id = projects.company_id
    )
)
WITH CHECK (
    -- Pour l'insertion/modification : même logique
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    -- Les clients peuvent seulement modifier leurs projets (via propositions)
    (client_id = auth.uid() AND auth.uid() IS NOT NULL)
);

-- 7. CRÉER UNE VUE ENRICHIE POUR LES PROJETS AVEC CLIENT
CREATE OR REPLACE VIEW project_details AS
SELECT 
    p.id,
    p.name,
    p.description,
    p.estimated_days,
    p.worked_days,
    p.daily_rate,
    p.status,
    p.priority,
    p.start_date,
    p.end_date,
    p.completion_percentage,
    p.created_at,
    p.updated_at,
    -- Informations entreprise
    c.name as company_name,
    c.id as company_id,
    -- Informations client
    client.email as client_email,
    CASE 
        WHEN client.first_name IS NOT NULL AND client.last_name IS NOT NULL 
        THEN client.first_name || ' ' || client.last_name
        ELSE COALESCE(client.email, 'Aucun client')
    END as client_name,
    client.user_id as client_id,
    -- Statistiques des tâches
    COUNT(t.id) as total_tasks,
    COUNT(CASE WHEN t.status IN ('completed', 'done') THEN 1 END) as completed_tasks,
    CASE 
        WHEN COUNT(t.id) > 0 
        THEN ROUND((COUNT(CASE WHEN t.status IN ('completed', 'done') THEN 1 END) * 100.0 / COUNT(t.id)), 2)
        ELSE 0 
    END as task_completion_percentage
FROM public.projects p
LEFT JOIN public.companies c ON p.company_id = c.id
LEFT JOIN public.profiles client ON p.client_id = client.user_id
LEFT JOIN public.tasks t ON p.id = t.project_id
GROUP BY p.id, p.name, p.description, p.estimated_days, p.worked_days, p.daily_rate,
         p.status, p.priority, p.start_date, p.end_date, p.completion_percentage, 
         p.created_at, p.updated_at, c.name, c.id, client.email, client.first_name, 
         client.last_name, client.user_id;

-- 8. FONCTION POUR ASSOCIER UN CLIENT À UN PROJET EXISTANT
CREATE OR REPLACE FUNCTION assign_client_to_project(
    p_project_id UUID,
    p_client_id UUID
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    user_company_id BIGINT;
    client_company_id BIGINT;
BEGIN
    -- Vérifier les permissions (admin ou associé)
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE user_id = auth.uid()
        AND role IN ('admin', 'associe')
    ) THEN
        RAISE EXCEPTION 'Permissions insuffisantes';
    END IF;

    -- Récupérer la company_id de l'utilisateur
    SELECT company_id INTO user_company_id
    FROM public.profiles
    WHERE user_id = auth.uid();

    -- Récupérer la company_id du client
    SELECT company_id INTO client_company_id
    FROM public.profiles
    WHERE user_id = p_client_id AND role = 'client';

    -- Vérifier que le client et l'utilisateur sont de la même entreprise
    IF user_company_id IS NULL OR client_company_id IS NULL OR user_company_id != client_company_id THEN
        RAISE EXCEPTION 'Le client doit appartenir à la même entreprise';
    END IF;

    -- Vérifier que le projet appartient à l'entreprise
    IF NOT EXISTS (
        SELECT 1 FROM public.projects
        WHERE id = p_project_id AND company_id = user_company_id
    ) THEN
        RAISE EXCEPTION 'Projet non trouvé ou accès non autorisé';
    END IF;

    -- Associer le client au projet
    UPDATE public.projects
    SET 
        client_id = p_client_id,
        updated_at = NOW()
    WHERE id = p_project_id;

    RETURN TRUE;
END;
$$;

-- 9. MESSAGES DE CONFIRMATION
SELECT '🎯 CORRECTIONS APPLIQUÉES AVEC SUCCÈS !' as status;

SELECT 'AJOUTS RÉALISÉS :' as result
UNION ALL SELECT '✅ Colonne client_id ajoutée à projects'
UNION ALL SELECT '✅ Fonction approve_project_proposal corrigée'
UNION ALL SELECT '✅ Fonction create_project_with_client créée'
UNION ALL SELECT '✅ Fonction get_company_clients créée'
UNION ALL SELECT '✅ Fonction assign_client_to_project créée'
UNION ALL SELECT '✅ Politiques RLS mises à jour'
UNION ALL SELECT '✅ Vue project_details enrichie créée';

SELECT '📋 PROCHAINES ÉTAPES :' as result
UNION ALL SELECT '1. Mettre à jour les interfaces Flutter'
UNION ALL SELECT '2. Ajouter sélection client dans création projet'
UNION ALL SELECT '3. Tester sur toutes les plateformes'; 