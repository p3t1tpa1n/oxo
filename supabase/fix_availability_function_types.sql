-- Correction des types de paramètres pour les fonctions de disponibilité
-- À exécuter dans l'éditeur SQL de Supabase

-- =====================================================
-- CORRECTION DES TYPES DE PARAMÈTRES
-- =====================================================

-- 1. Supprimer l'ancienne fonction get_partner_availability_for_period
DROP FUNCTION IF EXISTS get_partner_availability_for_period(DATE, DATE);
DROP FUNCTION IF EXISTS get_partner_availability_for_period(TIMESTAMP, TIMESTAMP);
DROP FUNCTION IF EXISTS get_partner_availability_for_period();

-- 2. Recréer la fonction avec gestion flexible des types
CREATE OR REPLACE FUNCTION get_partner_availability_for_period(
    start_date TEXT DEFAULT NULL,
    end_date TEXT DEFAULT NULL
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
DECLARE
    start_date_parsed DATE;
    end_date_parsed DATE;
BEGIN
    -- Gérer les paramètres par défaut
    IF start_date IS NULL THEN
        start_date_parsed := CURRENT_DATE;
    ELSE
        start_date_parsed := start_date::DATE;
    END IF;
    
    IF end_date IS NULL THEN
        end_date_parsed := CURRENT_DATE + INTERVAL '30 days';
    ELSE
        end_date_parsed := end_date::DATE;
    END IF;
    
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
    AND pav.date BETWEEN start_date_parsed AND end_date_parsed
    ORDER BY pav.date ASC, pav.partner_name ASC;
END;
$$;

-- 3. Corriger également get_available_partners_for_date
DROP FUNCTION IF EXISTS get_available_partners_for_date(DATE);
DROP FUNCTION IF EXISTS get_available_partners_for_date(TIMESTAMP);
DROP FUNCTION IF EXISTS get_available_partners_for_date();

CREATE OR REPLACE FUNCTION get_available_partners_for_date(
    target_date TEXT DEFAULT NULL
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
DECLARE
    target_date_parsed DATE;
BEGIN
    -- Gérer le paramètre par défaut
    IF target_date IS NULL THEN
        target_date_parsed := CURRENT_DATE;
    ELSE
        target_date_parsed := target_date::DATE;
    END IF;
    
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
    AND pav.date = target_date_parsed
    AND pav.is_available = true
    ORDER BY pav.partner_name ASC;
END;
$$;

-- 4. Tests avec les nouveaux types
SELECT '✅ Test 1: Fonction avec paramètres string' as test;
SELECT COUNT(*) as function_results FROM get_partner_availability_for_period(
    CURRENT_DATE::TEXT,
    (CURRENT_DATE + INTERVAL '14 days')::TEXT
);

SELECT '✅ Test 2: Fonction sans paramètres (défaut)' as test;
SELECT COUNT(*) as default_results FROM get_partner_availability_for_period();

SELECT '✅ Test 3: Partenaires disponibles aujourd''hui' as test;
SELECT COUNT(*) as available_today FROM get_available_partners_for_date(CURRENT_DATE::TEXT);

SELECT '✅ Test 4: Partenaires disponibles (défaut)' as test;
SELECT COUNT(*) as available_default FROM get_available_partners_for_date();

-- 5. Vérifier que la vue fonctionne toujours
SELECT '✅ Test 5: Vue partner_availability_view' as test;
SELECT COUNT(*) as view_count FROM public.partner_availability_view;

-- 6. Messages de confirmation
SELECT '🎉 Fonctions corrigées avec succès!' as result;
SELECT '📋 Types de paramètres mis à jour:' as info;
SELECT '   - get_partner_availability_for_period: TEXT, TEXT' as param1;
SELECT '   - get_available_partners_for_date: TEXT' as param2;
SELECT '   - Conversion automatique vers DATE en interne' as conversion;





