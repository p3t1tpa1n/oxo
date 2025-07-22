-- Script pour ajouter les fonctionnalités client: suivi du temps, demandes d'extension et propositions de projets
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Ajouter des colonnes de suivi du temps à la table projects (si elles n'existent pas déjà)
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS estimated_hours DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS worked_hours DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'actif' CHECK (status IN ('actif', 'inactif', 'terminé', 'suspendu'));

-- 2. Créer une table pour les demandes d'extension de temps
CREATE TABLE IF NOT EXISTS public.time_extension_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID NOT NULL,
    client_id UUID NOT NULL,
    hours_requested DECIMAL(10,2) NOT NULL,
    reason TEXT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    response_message TEXT,
    approved_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Contraintes de clé étrangère
    CONSTRAINT fk_time_extension_project
        FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE,
    CONSTRAINT fk_time_extension_client
        FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_time_extension_approver
        FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL
);

-- 3. Créer une table pour les propositions de nouveaux projets
CREATE TABLE IF NOT EXISTS public.project_proposals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    estimated_budget DECIMAL(12,2),
    estimated_hours DECIMAL(10,2),
    client_id UUID NOT NULL,
    company_id BIGINT NOT NULL,
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'in_review')),
    response_message TEXT,
    reviewed_by UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Contraintes de clé étrangère
    CONSTRAINT fk_proposal_client
        FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_proposal_company
        FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE,
    CONSTRAINT fk_proposal_reviewer
        FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL
);

-- 4. Créer une table pour les documents joints aux propositions
CREATE TABLE IF NOT EXISTS public.project_proposal_documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    proposal_id UUID NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    mime_type VARCHAR(100),
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Contrainte de clé étrangère
    CONSTRAINT fk_document_proposal
        FOREIGN KEY (proposal_id) REFERENCES public.project_proposals(id) ON DELETE CASCADE
);

-- 5. Ajouter RLS (Row Level Security) pour time_extension_requests
ALTER TABLE public.time_extension_requests ENABLE ROW LEVEL SECURITY;

CREATE POLICY "time_extension_requests_client_access"
ON public.time_extension_requests FOR ALL
TO authenticated
USING (
    -- Les clients peuvent voir/modifier leurs propres demandes
    client_id = auth.uid()
    OR
    -- Les admins et associés peuvent voir toutes les demandes
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    -- Les partenaires peuvent voir les demandes des projets de leur entreprise
    EXISTS (
        SELECT 1 FROM public.projects p
        JOIN public.profiles pr ON pr.company_id = p.company_id
        WHERE p.id = time_extension_requests.project_id
        AND pr.user_id = auth.uid()
        AND pr.role = 'partenaire'
    )
);

-- 6. Ajouter RLS pour project_proposals
ALTER TABLE public.project_proposals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "project_proposals_access"
ON public.project_proposals FOR ALL
TO authenticated
USING (
    -- Les clients peuvent voir/modifier leurs propres propositions
    client_id = auth.uid()
    OR
    -- Les admins et associés peuvent voir toutes les propositions
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    -- Les partenaires peuvent voir les propositions de leur entreprise
    EXISTS (
        SELECT 1 FROM public.profiles pr
        WHERE pr.user_id = auth.uid()
        AND pr.company_id = project_proposals.company_id
        AND pr.role = 'partenaire'
    )
);

-- 7. Ajouter RLS pour project_proposal_documents
ALTER TABLE public.project_proposal_documents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "project_proposal_documents_access"
ON public.project_proposal_documents FOR ALL
TO authenticated
USING (
    -- Accès basé sur l'accès à la proposition
    EXISTS (
        SELECT 1 FROM public.project_proposals pp
        WHERE pp.id = proposal_id
        AND (
            pp.client_id = auth.uid()
            OR
            EXISTS (
                SELECT 1 FROM public.profiles 
                WHERE user_id = auth.uid() 
                AND role IN ('admin', 'associe')
            )
            OR
            EXISTS (
                SELECT 1 FROM public.profiles pr
                WHERE pr.user_id = auth.uid()
                AND pr.company_id = pp.company_id
                AND pr.role = 'partenaire'
            )
        )
    )
);

-- 8. Créer des fonctions utilitaires pour les clients

-- Fonction pour soumettre une demande d'extension de temps
CREATE OR REPLACE FUNCTION submit_time_extension_request(
    p_project_id UUID,
    p_hours_requested DECIMAL(10,2),
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
    -- Vérifier que l'utilisateur est un client
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role = 'client'
    ) THEN
        RAISE EXCEPTION 'Seuls les clients peuvent soumettre des demandes d''extension';
    END IF;
    
    -- Récupérer l'entreprise de l'utilisateur
    SELECT company_id INTO user_company_id
    FROM public.profiles
    WHERE user_id = auth.uid();
    
    -- Vérifier que le projet appartient à l'entreprise du client
    IF NOT EXISTS (
        SELECT 1 FROM public.projects 
        WHERE id = p_project_id 
        AND company_id = user_company_id
    ) THEN
        RAISE EXCEPTION 'Vous ne pouvez demander une extension que pour les projets de votre entreprise';
    END IF;
    
    -- Insérer la demande
    INSERT INTO public.time_extension_requests (
        project_id, 
        client_id, 
        hours_requested, 
        reason
    )
    VALUES (
        p_project_id,
        auth.uid(),
        p_hours_requested,
        p_reason
    )
    RETURNING id INTO request_id;
    
    RETURN request_id;
END;
$$;

-- Fonction pour soumettre une proposition de projet
CREATE OR REPLACE FUNCTION submit_project_proposal(
    p_title VARCHAR(255),
    p_description TEXT,
    p_estimated_budget DECIMAL(12,2),
    p_estimated_hours DECIMAL(10,2)
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    proposal_id UUID;
    user_company_id BIGINT;
BEGIN
    -- Vérifier que l'utilisateur est un client
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role = 'client'
    ) THEN
        RAISE EXCEPTION 'Seuls les clients peuvent soumettre des propositions de projet';
    END IF;
    
    -- Récupérer l'entreprise de l'utilisateur
    SELECT company_id INTO user_company_id
    FROM public.profiles
    WHERE user_id = auth.uid();
    
    IF user_company_id IS NULL THEN
        RAISE EXCEPTION 'Vous devez être assigné à une entreprise pour proposer un projet';
    END IF;
    
    -- Insérer la proposition
    INSERT INTO public.project_proposals (
        title,
        description,
        estimated_budget,
        estimated_hours,
        client_id,
        company_id
    )
    VALUES (
        p_title,
        p_description,
        p_estimated_budget,
        p_estimated_hours,
        auth.uid(),
        user_company_id
    )
    RETURNING id INTO proposal_id;
    
    RETURN proposal_id;
END;
$$;

-- 9. Ajouter quelques colonnes de metadonnées utiles
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
ADD COLUMN IF NOT EXISTS completion_percentage DECIMAL(5,2) DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100);

-- 10. Mettre à jour les projets existants avec des valeurs par défaut pour le temps
UPDATE public.projects 
SET 
    estimated_hours = 100,
    worked_hours = COALESCE(completion_percentage, 0) * estimated_hours / 100
WHERE estimated_hours IS NULL OR estimated_hours = 0;

-- 11. Créer des vues utiles pour le dashboard client
CREATE OR REPLACE VIEW client_project_summary AS
SELECT 
    p.id,
    p.name,
    p.description,
    p.estimated_hours,
    p.worked_hours,
    CASE 
        WHEN p.estimated_hours > 0 
        THEN (p.worked_hours / p.estimated_hours) * 100
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
GROUP BY p.id, p.name, p.description, p.estimated_hours, p.worked_hours, 
         p.completion_percentage, p.status, p.priority, p.start_date, p.end_date, p.company_id;

-- 12. Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_time_extension_project_id ON public.time_extension_requests(project_id);
CREATE INDEX IF NOT EXISTS idx_time_extension_client_id ON public.time_extension_requests(client_id);
CREATE INDEX IF NOT EXISTS idx_time_extension_status ON public.time_extension_requests(status);

CREATE INDEX IF NOT EXISTS idx_project_proposals_client_id ON public.project_proposals(client_id);
CREATE INDEX IF NOT EXISTS idx_project_proposals_company_id ON public.project_proposals(company_id);
CREATE INDEX IF NOT EXISTS idx_project_proposals_status ON public.project_proposals(status);

CREATE INDEX IF NOT EXISTS idx_proposal_documents_proposal_id ON public.project_proposal_documents(proposal_id);

-- 13. Messages de confirmation
SELECT '✅ Tables créées avec succès:' as result;
SELECT 'time_extension_requests' as table_name
UNION ALL SELECT 'project_proposals'
UNION ALL SELECT 'project_proposal_documents';

SELECT '✅ Colonnes ajoutées à projects:' as result;
SELECT column_name 
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'projects'
AND column_name IN ('estimated_hours', 'worked_hours', 'hourly_rate', 'priority', 'completion_percentage')
ORDER BY column_name;

SELECT '✅ Fonctions créées:' as result;
SELECT 'submit_time_extension_request' as function_name
UNION ALL SELECT 'submit_project_proposal';

SELECT '✅ Configuration terminée avec succès!' as final_message; 