-- Créer la table des actions commerciales
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Créer la table commercial_actions
CREATE TABLE IF NOT EXISTS public.commercial_actions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) NOT NULL CHECK (type IN ('call', 'email', 'meeting', 'follow_up', 'proposal', 'negotiation')),
    status VARCHAR(50) DEFAULT 'planned' CHECK (status IN ('planned', 'in_progress', 'completed', 'cancelled')),
    priority VARCHAR(20) DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    
    -- Informations client
    client_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    
    -- Informations commerciales
    estimated_value DECIMAL(12,2),
    actual_value DECIMAL(12,2),
    
    -- Dates
    due_date TIMESTAMPTZ,
    completed_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Relations
    assigned_to UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    partner_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    company_id BIGINT REFERENCES public.companies(id) ON DELETE CASCADE,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Informations supplémentaires
    notes TEXT,
    follow_up_date TIMESTAMPTZ,
    outcome TEXT
);

-- 2. Créer les index pour améliorer les performances
CREATE INDEX IF NOT EXISTS commercial_actions_company_id_idx ON public.commercial_actions(company_id);
CREATE INDEX IF NOT EXISTS commercial_actions_assigned_to_idx ON public.commercial_actions(assigned_to);
CREATE INDEX IF NOT EXISTS commercial_actions_partner_id_idx ON public.commercial_actions(partner_id);
CREATE INDEX IF NOT EXISTS commercial_actions_status_idx ON public.commercial_actions(status);
CREATE INDEX IF NOT EXISTS commercial_actions_due_date_idx ON public.commercial_actions(due_date);
CREATE INDEX IF NOT EXISTS commercial_actions_created_at_idx ON public.commercial_actions(created_at);

-- 3. Activer Row Level Security
ALTER TABLE public.commercial_actions ENABLE ROW LEVEL SECURITY;

-- 4. Créer les politiques RLS
-- Politique de lecture : utilisateurs de la même entreprise
CREATE POLICY "commercial_actions_read" ON public.commercial_actions
    FOR SELECT TO authenticated
    USING (
        company_id IN (
            SELECT p.company_id 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
        )
    );

-- Politique d'insertion : utilisateurs admin/associé de la même entreprise
CREATE POLICY "commercial_actions_insert" ON public.commercial_actions
    FOR INSERT TO authenticated
    WITH CHECK (
        company_id IN (
            SELECT p.company_id 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
            AND p.role IN ('admin', 'associe')
        )
    );

-- Politique de mise à jour : créateur ou admin/associé de la même entreprise
CREATE POLICY "commercial_actions_update" ON public.commercial_actions
    FOR UPDATE TO authenticated
    USING (
        created_by = auth.uid()
        OR assigned_to = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles p 
            WHERE p.user_id = auth.uid()
            AND p.company_id = commercial_actions.company_id
            AND p.role IN ('admin', 'associe')
        )
    );

-- Politique de suppression : créateur ou admin de la même entreprise
CREATE POLICY "commercial_actions_delete" ON public.commercial_actions
    FOR DELETE TO authenticated
    USING (
        created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.profiles p 
            WHERE p.user_id = auth.uid()
            AND p.company_id = commercial_actions.company_id
            AND p.role = 'admin'
        )
    );

-- 5. Créer une vue pour simplifier les requêtes
CREATE OR REPLACE VIEW public.commercial_actions_view AS
SELECT 
    ca.*,
    creator.email as created_by_email,
    creator.first_name as created_by_first_name,
    creator.last_name as created_by_last_name,
    assignee.email as assigned_to_email,
    assignee.first_name as assigned_to_first_name,
    assignee.last_name as assigned_to_last_name,
    partner.email as partner_email,
    partner.first_name as partner_first_name,
    partner.last_name as partner_last_name,
    comp.name as company_name
FROM public.commercial_actions ca
LEFT JOIN public.profiles creator ON creator.user_id = ca.created_by
LEFT JOIN public.profiles assignee ON assignee.user_id = ca.assigned_to
LEFT JOIN public.profiles partner ON partner.user_id = ca.partner_id
LEFT JOIN public.companies comp ON comp.id = ca.company_id;

-- 6. Créer des fonctions utilitaires
CREATE OR REPLACE FUNCTION get_commercial_actions_for_company()
RETURNS TABLE (
    id UUID,
    title VARCHAR(255),
    description TEXT,
    type VARCHAR(50),
    status VARCHAR(50),
    priority VARCHAR(20),
    client_name VARCHAR(255),
    contact_person VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    estimated_value DECIMAL(12,2),
    actual_value DECIMAL(12,2),
    due_date TIMESTAMPTZ,
    completed_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ,
    assigned_to_email TEXT,
    assigned_to_name TEXT,
    partner_email TEXT,
    partner_name TEXT,
    notes TEXT
) LANGUAGE plpgsql SECURITY DEFINER
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