-- SCRIPT DE CORRECTION RAPIDE - Erreur user_role
-- Exécuter ce script au lieu du script complet si vous avez déjà créé la table

-- 1. Corriger la vue partner_availability_view
DROP VIEW IF EXISTS public.partner_availability_view;

CREATE OR REPLACE VIEW public.partner_availability_view AS
SELECT 
    pa.*,
    partner.first_name as partner_first_name,
    partner.last_name as partner_last_name,
    partner.email as partner_email,
    partner.role as partner_role,  -- CORRIGÉ : 'role' au lieu de 'user_role'
    comp.name as company_name
FROM public.partner_availability pa
LEFT JOIN public.profiles partner ON partner.user_id = pa.partner_id
LEFT JOIN public.companies comp ON comp.id = pa.company_id;

-- 2. Corriger la fonction create_default_availability_for_partner
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
    AND role = 'partenaire';  -- CORRIGÉ : 'role' au lieu de 'user_role'
    
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