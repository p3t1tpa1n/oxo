-- Script SQL pour la gestion des disponibilités des partenaires
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Créer la table des disponibilités des partenaires
CREATE TABLE IF NOT EXISTS public.partner_availability (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    partner_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    company_id BIGINT NOT NULL REFERENCES public.companies(id) ON DELETE CASCADE,
    
    -- Date et disponibilité
    date DATE NOT NULL,
    is_available BOOLEAN NOT NULL DEFAULT true,
    
    -- Détails de disponibilité (optionnel)
    start_time TIME,
    end_time TIME,
    
    -- Type de disponibilité
    availability_type VARCHAR(50) DEFAULT 'full_day' CHECK (availability_type IN ('full_day', 'partial_day', 'unavailable')),
    
    -- Notes et raison
    notes TEXT,
    unavailability_reason VARCHAR(100), -- 'vacation', 'sick', 'personal', 'training', 'other'
    
    -- Métadonnées
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    
    -- Contrainte d'unicité : un partenaire ne peut avoir qu'une entrée par date
    UNIQUE(partner_id, date)
);

-- 2. Créer les index pour optimiser les performances
CREATE INDEX IF NOT EXISTS partner_availability_partner_id_idx ON public.partner_availability(partner_id);
CREATE INDEX IF NOT EXISTS partner_availability_company_id_idx ON public.partner_availability(company_id);
CREATE INDEX IF NOT EXISTS partner_availability_date_idx ON public.partner_availability(date);
CREATE INDEX IF NOT EXISTS partner_availability_is_available_idx ON public.partner_availability(is_available);

-- 3. Activer Row Level Security
ALTER TABLE public.partner_availability ENABLE ROW LEVEL SECURITY;

-- 4. Créer les politiques RLS

-- Politique de lecture : utilisateurs de la même entreprise
CREATE POLICY "partner_availability_read" ON public.partner_availability
    FOR SELECT TO authenticated
    USING (
        company_id IN (
            SELECT p.company_id 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
        )
    );

-- Politique d'insertion : partenaires pour eux-mêmes OU admin/associé de la même entreprise
CREATE POLICY "partner_availability_insert" ON public.partner_availability
    FOR INSERT TO authenticated
    WITH CHECK (
        -- Le partenaire peut créer ses propres disponibilités
        (partner_id = auth.uid() AND company_id IN (
            SELECT p.company_id 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
        ))
        OR 
        -- Admin/Associé peut créer pour n'importe quel partenaire de la même entreprise
        (company_id IN (
            SELECT p.company_id 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
            AND p.role IN ('admin', 'associe')
        ))
    );

-- Politique de mise à jour : partenaire pour lui-même OU admin/associé de la même entreprise
CREATE POLICY "partner_availability_update" ON public.partner_availability
    FOR UPDATE TO authenticated
    USING (
        -- Le partenaire peut modifier ses propres disponibilités
        (partner_id = auth.uid())
        OR 
        -- Admin/Associé peut modifier les disponibilités de leur entreprise
        (company_id IN (
            SELECT p.company_id 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
            AND p.role IN ('admin', 'associe')
        ))
    );

-- Politique de suppression : partenaire pour lui-même OU admin/associé de la même entreprise
CREATE POLICY "partner_availability_delete" ON public.partner_availability
    FOR DELETE TO authenticated
    USING (
        -- Le partenaire peut supprimer ses propres disponibilités
        (partner_id = auth.uid())
        OR 
        -- Admin/Associé peut supprimer les disponibilités de leur entreprise
        (company_id IN (
            SELECT p.company_id 
            FROM public.profiles p 
            WHERE p.user_id = auth.uid()
            AND p.role IN ('admin', 'associe')
        ))
    );

-- 5. Créer une vue pour simplifier les requêtes avec les informations des partenaires
CREATE OR REPLACE VIEW public.partner_availability_view AS
SELECT 
    pa.*,
    partner.first_name as partner_first_name,
    partner.last_name as partner_last_name,
    partner.email as partner_email,
    partner.role as partner_role,
    comp.name as company_name
FROM public.partner_availability pa
LEFT JOIN public.profiles partner ON partner.user_id = pa.partner_id
LEFT JOIN public.companies comp ON comp.id = pa.company_id;

-- 6. Créer des fonctions utilitaires

-- Fonction pour récupérer les disponibilités d'une période
CREATE OR REPLACE FUNCTION get_partner_availability_for_period(
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE DEFAULT CURRENT_DATE + INTERVAL '30 days'
)
RETURNS TABLE (
    id UUID,
    partner_id UUID,
    partner_name TEXT,
    partner_email TEXT,
    date DATE,
    is_available BOOLEAN,
    availability_type VARCHAR(50),
    start_time TIME,
    end_time TIME,
    notes TEXT,
    unavailability_reason VARCHAR(100)
) LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pav.id,
        pav.partner_id,
        CONCAT(pav.partner_first_name, ' ', pav.partner_last_name) as partner_name,
        pav.partner_email,
        pav.date,
        pav.is_available,
        pav.availability_type,
        pav.start_time,
        pav.end_time,
        pav.notes,
        pav.unavailability_reason
    FROM public.partner_availability_view pav
    WHERE pav.company_id IN (
        SELECT p.company_id 
        FROM public.profiles p 
        WHERE p.user_id = auth.uid()
    )
    AND pav.date BETWEEN start_date AND end_date
    ORDER BY pav.date ASC, pav.partner_name ASC;
END;
$$;

-- Fonction pour récupérer les partenaires disponibles pour une date donnée
CREATE OR REPLACE FUNCTION get_available_partners_for_date(
    target_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    partner_id UUID,
    partner_name TEXT,
    partner_email TEXT,
    availability_type VARCHAR(50),
    start_time TIME,
    end_time TIME,
    notes TEXT
) LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pav.partner_id,
        CONCAT(pav.partner_first_name, ' ', pav.partner_last_name) as partner_name,
        pav.partner_email,
        pav.availability_type,
        pav.start_time,
        pav.end_time,
        pav.notes
    FROM public.partner_availability_view pav
    WHERE pav.company_id IN (
        SELECT p.company_id 
        FROM public.profiles p 
        WHERE p.user_id = auth.uid()
    )
    AND pav.date = target_date
    AND pav.is_available = true
    ORDER BY pav.partner_name ASC;
END;
$$;

-- Fonction pour créer automatiquement les disponibilités par défaut pour un nouveau partenaire
CREATE OR REPLACE FUNCTION create_default_availability_for_partner(
    new_partner_id UUID,
    days_ahead INTEGER DEFAULT 30
)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER
AS $$
DECLARE
    partner_company_id BIGINT;
    current_date DATE := CURRENT_DATE;
    end_date DATE := CURRENT_DATE + INTERVAL '1 day' * days_ahead;
    day_date DATE;
BEGIN
    -- Récupérer l'ID de l'entreprise du partenaire
    SELECT company_id INTO partner_company_id
    FROM public.profiles 
    WHERE user_id = new_partner_id 
    AND role = 'partenaire';
    
    IF partner_company_id IS NULL THEN
        RAISE EXCEPTION 'Partenaire non trouvé ou pas du bon rôle';
    END IF;
    
    -- Créer les disponibilités par défaut (disponible en semaine, indisponible weekend)
    day_date := current_date;
    WHILE day_date <= end_date LOOP
        INSERT INTO public.partner_availability (
            partner_id,
            company_id,
            date,
            is_available,
            availability_type,
            start_time,
            end_time,
            created_by
        ) VALUES (
            new_partner_id,
            partner_company_id,
            day_date,
            CASE 
                WHEN EXTRACT(dow FROM day_date) IN (0, 6) THEN false  -- Weekend
                ELSE true  -- Semaine
            END,
            CASE 
                WHEN EXTRACT(dow FROM day_date) IN (0, 6) THEN 'unavailable'
                ELSE 'full_day'
            END,
            CASE 
                WHEN EXTRACT(dow FROM day_date) NOT IN (0, 6) THEN '09:00:00'::TIME
                ELSE NULL
            END,
            CASE 
                WHEN EXTRACT(dow FROM day_date) NOT IN (0, 6) THEN '17:00:00'::TIME
                ELSE NULL
            END,
            auth.uid()
        ) ON CONFLICT (partner_id, date) DO NOTHING;  -- Éviter les doublons
        
        day_date := day_date + 1;
    END LOOP;
END;
$$;

-- 7. Créer un trigger pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_partner_availability_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER partner_availability_updated_at
    BEFORE UPDATE ON public.partner_availability
    FOR EACH ROW
    EXECUTE FUNCTION update_partner_availability_updated_at();

-- 8. Commenter les tables et colonnes pour la documentation
COMMENT ON TABLE public.partner_availability IS 'Table pour gérer les disponibilités des partenaires par date';
COMMENT ON COLUMN public.partner_availability.availability_type IS 'Type de disponibilité: full_day, partial_day, unavailable';
COMMENT ON COLUMN public.partner_availability.unavailability_reason IS 'Raison de l''indisponibilité: vacation, sick, personal, training, other';
COMMENT ON FUNCTION get_partner_availability_for_period IS 'Récupère les disponibilités des partenaires pour une période donnée';
COMMENT ON FUNCTION get_available_partners_for_date IS 'Récupère uniquement les partenaires disponibles pour une date donnée';
COMMENT ON FUNCTION create_default_availability_for_partner IS 'Crée automatiquement les disponibilités par défaut pour un nouveau partenaire'; 