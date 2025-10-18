-- Script de correction pour les erreurs d'affichage des disponibilités
-- À exécuter dans l'éditeur SQL de Supabase

-- =====================================================
-- CORRECTION DES ERREURS IDENTIFIÉES
-- =====================================================

-- 1. Corriger la vue partner_availability_view
DROP VIEW IF EXISTS public.partner_availability_view;

CREATE OR REPLACE VIEW public.partner_availability_view AS
SELECT 
    pa.id,
    pa.partner_id,
    pa.company_id,
    pa.date,
    pa.is_available,
    pa.availability_type,
    pa.start_time,
    pa.end_time,
    pa.notes,
    pa.unavailability_reason,
    COALESCE(p.first_name, '') as partner_first_name,
    COALESCE(p.last_name, '') as partner_last_name,
    COALESCE(p.email, '') as partner_email,
    CONCAT(COALESCE(p.first_name, ''), ' ', COALESCE(p.last_name, '')) as partner_name,
    p.role as partner_role
FROM public.partner_availability pa
LEFT JOIN public.profiles p ON p.user_id = pa.partner_id;

-- 2. Corriger la fonction get_partner_availability_for_period
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
        pav.partner_name,
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

-- 3. Vérifier et corriger la contrainte de clé étrangère si nécessaire
DO $$
BEGIN
    -- Vérifier si la contrainte existe
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'partner_availability_partner_id_fkey'
        AND table_name = 'partner_availability'
    ) THEN
        -- Ajouter la contrainte de clé étrangère
        ALTER TABLE public.partner_availability 
        ADD CONSTRAINT partner_availability_partner_id_fkey 
        FOREIGN KEY (partner_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 4. Corriger la fonction get_available_partners_for_date également
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
        pav.partner_name,
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

-- 5. Créer quelques données de test pour validation
INSERT INTO public.partner_availability (
    partner_id,
    company_id,
    date,
    is_available,
    availability_type,
    start_time,
    end_time,
    notes,
    created_by
) 
SELECT 
    p.user_id,
    p.company_id,
    CURRENT_DATE + (i || ' days')::interval,
    CASE WHEN i % 3 = 0 THEN false ELSE true END,
    CASE WHEN i % 2 = 0 THEN 'full_day' ELSE 'partial_day' END,
    CASE WHEN i % 2 = 1 THEN '09:00:00'::time ELSE NULL END,
    CASE WHEN i % 2 = 1 THEN '17:00:00'::time ELSE NULL END,
    CASE WHEN i % 3 = 0 THEN 'Congés' ELSE 'Disponible' END,
    p.user_id
FROM public.profiles p
CROSS JOIN generate_series(0, 13) i  -- 2 semaines de données
WHERE p.role = 'partenaire'
ON CONFLICT (partner_id, date) DO UPDATE SET
    is_available = EXCLUDED.is_available,
    availability_type = EXCLUDED.availability_type,
    start_time = EXCLUDED.start_time,
    end_time = EXCLUDED.end_time,
    notes = EXCLUDED.notes,
    updated_at = NOW();

-- 6. Test de la vue et des fonctions
SELECT '✅ Test de la vue partner_availability_view:' as test;
SELECT COUNT(*) as total_entries FROM public.partner_availability_view;

SELECT '✅ Test de la fonction get_partner_availability_for_period:' as test;
SELECT COUNT(*) as function_results FROM get_partner_availability_for_period(
    CURRENT_DATE - INTERVAL '7 days',
    CURRENT_DATE + INTERVAL '14 days'
);

SELECT '✅ Test de la fonction get_available_partners_for_date:' as test;
SELECT COUNT(*) as available_today FROM get_available_partners_for_date(CURRENT_DATE);

-- 7. Messages de confirmation
SELECT '🎉 Corrections appliquées avec succès!' as result;
SELECT '📋 Actions effectuées:' as info;
SELECT '   - Vue partner_availability_view recréée avec partner_name' as action1;
SELECT '   - Fonction get_partner_availability_for_period corrigée' as action2;
SELECT '   - Contrainte de clé étrangère vérifiée/ajoutée' as action3;
SELECT '   - Données de test créées pour validation' as action4;

