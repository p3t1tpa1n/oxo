-- Script adaptatif pour créer les fonctionnalités client
-- Ce script détecte automatiquement les types des colonnes existantes

-- 1. Ajouter des colonnes de suivi du temps à la table projects
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS estimated_hours DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS worked_hours DECIMAL(10,2) DEFAULT 0,
ADD COLUMN IF NOT EXISTS hourly_rate DECIMAL(10,2),
ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'actif' CHECK (status IN ('actif', 'inactif', 'terminé', 'suspendu')),
ADD COLUMN IF NOT EXISTS priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
ADD COLUMN IF NOT EXISTS completion_percentage DECIMAL(5,2) DEFAULT 0 CHECK (completion_percentage >= 0 AND completion_percentage <= 100);

-- 2. Créer une fonction pour détecter le type de projects.id
DO $$
DECLARE
    projects_id_type TEXT;
    companies_id_type TEXT;
BEGIN
    -- Détecter le type de projects.id
    SELECT data_type INTO projects_id_type 
    FROM information_schema.columns 
    WHERE table_name = 'projects' AND column_name = 'id' AND table_schema = 'public';
    
    -- Détecter le type de companies.id
    SELECT data_type INTO companies_id_type 
    FROM information_schema.columns 
    WHERE table_name = 'companies' AND column_name = 'id' AND table_schema = 'public';
    
    -- Créer time_extension_requests avec le bon type
    IF projects_id_type = 'uuid' THEN
        EXECUTE '
        CREATE TABLE IF NOT EXISTS public.time_extension_requests (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            project_id UUID NOT NULL,
            client_id UUID NOT NULL,
            hours_requested DECIMAL(10,2) NOT NULL,
            reason TEXT NOT NULL,
            status VARCHAR(50) DEFAULT ''pending'' CHECK (status IN (''pending'', ''approved'', ''rejected'')),
            response_message TEXT,
            approved_by UUID,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            
            CONSTRAINT fk_time_extension_project
                FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE,
            CONSTRAINT fk_time_extension_client
                FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
            CONSTRAINT fk_time_extension_approver
                FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL
        );';
    ELSE
        EXECUTE '
        CREATE TABLE IF NOT EXISTS public.time_extension_requests (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            project_id BIGINT NOT NULL,
            client_id UUID NOT NULL,
            hours_requested DECIMAL(10,2) NOT NULL,
            reason TEXT NOT NULL,
            status VARCHAR(50) DEFAULT ''pending'' CHECK (status IN (''pending'', ''approved'', ''rejected'')),
            response_message TEXT,
            approved_by UUID,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            
            CONSTRAINT fk_time_extension_project
                FOREIGN KEY (project_id) REFERENCES public.projects(id) ON DELETE CASCADE,
            CONSTRAINT fk_time_extension_client
                FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
            CONSTRAINT fk_time_extension_approver
                FOREIGN KEY (approved_by) REFERENCES auth.users(id) ON DELETE SET NULL
        );';
    END IF;
    
    -- Créer project_proposals avec le bon type
    IF companies_id_type = 'uuid' THEN
        EXECUTE '
        CREATE TABLE IF NOT EXISTS public.project_proposals (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description TEXT NOT NULL,
            estimated_budget DECIMAL(12,2),
            estimated_hours DECIMAL(10,2),
            client_id UUID NOT NULL,
            company_id UUID NOT NULL,
            status VARCHAR(50) DEFAULT ''pending'' CHECK (status IN (''pending'', ''approved'', ''rejected'', ''in_review'')),
            response_message TEXT,
            reviewed_by UUID,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            
            CONSTRAINT fk_proposal_client
                FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
            CONSTRAINT fk_proposal_company
                FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE,
            CONSTRAINT fk_proposal_reviewer
                FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL
        );';
    ELSE
        EXECUTE '
        CREATE TABLE IF NOT EXISTS public.project_proposals (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description TEXT NOT NULL,
            estimated_budget DECIMAL(12,2),
            estimated_hours DECIMAL(10,2),
            client_id UUID NOT NULL,
            company_id BIGINT NOT NULL,
            status VARCHAR(50) DEFAULT ''pending'' CHECK (status IN (''pending'', ''approved'', ''rejected'', ''in_review'')),
            response_message TEXT,
            reviewed_by UUID,
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            
            CONSTRAINT fk_proposal_client
                FOREIGN KEY (client_id) REFERENCES auth.users(id) ON DELETE CASCADE,
            CONSTRAINT fk_proposal_company
                FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE,
            CONSTRAINT fk_proposal_reviewer
                FOREIGN KEY (reviewed_by) REFERENCES auth.users(id) ON DELETE SET NULL
        );';
    END IF;
    
    RAISE NOTICE 'Tables créées avec projects.id type: % et companies.id type: %', projects_id_type, companies_id_type;
END $$;

-- 3. Créer la table des documents (toujours UUID pour proposal_id)
CREATE TABLE IF NOT EXISTS public.project_proposal_documents (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    proposal_id UUID NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path TEXT NOT NULL,
    file_size BIGINT,
    mime_type VARCHAR(100),
    uploaded_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT fk_document_proposal
        FOREIGN KEY (proposal_id) REFERENCES public.project_proposals(id) ON DELETE CASCADE
);

-- 4. Activer RLS sur toutes les nouvelles tables
ALTER TABLE public.time_extension_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_proposals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.project_proposal_documents ENABLE ROW LEVEL SECURITY;

-- 5. Politiques RLS simplifiées
CREATE POLICY "time_extension_requests_policy" ON public.time_extension_requests FOR ALL TO authenticated USING (true);
CREATE POLICY "project_proposals_policy" ON public.project_proposals FOR ALL TO authenticated USING (true);
CREATE POLICY "project_proposal_documents_policy" ON public.project_proposal_documents FOR ALL TO authenticated USING (true);

-- 6. Mettre à jour les projets existants avec des valeurs par défaut
UPDATE public.projects 
SET 
    estimated_hours = 100,
    worked_hours = COALESCE(completion_percentage, 0) * 100 / 100
WHERE estimated_hours IS NULL OR estimated_hours = 0;

-- 7. Message de succès
SELECT '✅ Configuration client terminée avec succès!' as result; 