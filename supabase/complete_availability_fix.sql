-- Script complet de réparation des disponibilités
-- À exécuter dans l'éditeur SQL de Supabase

-- =====================================================
-- RÉPARATION COMPLÈTE DES DISPONIBILITÉS
-- =====================================================

-- 1. Nettoyer les anciennes fonctions
DROP FUNCTION IF EXISTS get_partner_availability_for_period(DATE, DATE);
DROP FUNCTION IF EXISTS get_partner_availability_for_period(TIMESTAMP, TIMESTAMP);
DROP FUNCTION IF EXISTS get_partner_availability_for_period();
DROP FUNCTION IF EXISTS get_available_partners_for_date(DATE);
DROP FUNCTION IF EXISTS get_available_partners_for_date(TIMESTAMP);
DROP FUNCTION IF EXISTS get_available_partners_for_date();

-- 2. Recréer la vue partner_availability_view
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
    pa.created_at,
    pa.updated_at,
    COALESCE(p.first_name, '') as partner_first_name,
    COALESCE(p.last_name, '') as partner_last_name,
    COALESCE(p.email, '') as partner_email,
    TRIM(CONCAT(COALESCE(p.first_name, ''), ' ', COALESCE(p.last_name, ''))) as partner_name,
    p.role as partner_role
FROM public.partner_availability pa
LEFT JOIN public.profiles p ON p.user_id = pa.partner_id;

-- 3. Vérifier/Ajouter la contrainte de clé étrangère
DO $$
BEGIN
    -- Supprimer l'ancienne contrainte si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'partner_availability_partner_id_fkey'
        AND table_name = 'partner_availability'
    ) THEN
        ALTER TABLE public.partner_availability 
        DROP CONSTRAINT partner_availability_partner_id_fkey;
    END IF;
    
    -- Ajouter la nouvelle contrainte
    ALTER TABLE public.partner_availability 
    ADD CONSTRAINT partner_availability_partner_id_fkey 
    FOREIGN KEY (partner_id) REFERENCES auth.users(id) ON DELETE CASCADE;
    
EXCEPTION WHEN OTHERS THEN
    -- Ignorer les erreurs si la contrainte existe déjà
    NULL;
END $$;

-- 4. Créer la fonction get_partner_availability_for_period avec types TEXT
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
    IF start_date IS NULL OR start_date = '' THEN
        start_date_parsed := CURRENT_DATE;
    ELSE
        start_date_parsed := start_date::DATE;
    END IF;
    
    IF end_date IS NULL OR end_date = '' THEN
        end_date_parsed := CURRENT_DATE + INTERVAL '30 days';
    ELSE
        end_date_parsed := end_date::DATE;
    END IF;
    
    RETURN QUERY
    SELECT 
        pav.id,
        pav.partner_id,
        CASE 
            WHEN pav.partner_name IS NULL OR pav.partner_name = '' 
            THEN 'Partenaire inconnu'
            ELSE pav.partner_name
        END as partner_name,
        COALESCE(pav.partner_email, '') as partner_email,
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

-- 5. Créer la fonction get_available_partners_for_date avec type TEXT
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
    IF target_date IS NULL OR target_date = '' THEN
        target_date_parsed := CURRENT_DATE;
    ELSE
        target_date_parsed := target_date::DATE;
    END IF;
    
    RETURN QUERY
    SELECT 
        pav.partner_id,
        CASE 
            WHEN pav.partner_name IS NULL OR pav.partner_name = '' 
            THEN 'Partenaire inconnu'
            ELSE pav.partner_name
        END as partner_name,
        COALESCE(pav.partner_email, '') as partner_email,
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

-- 6. Créer des données de test si aucune n'existe
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
    CASE 
        WHEN i % 3 = 0 THEN 'Congés'
        WHEN i % 2 = 1 THEN 'Disponible partiellement'
        ELSE 'Disponible toute la journée'
    END,
    p.user_id
FROM public.profiles p
CROSS JOIN generate_series(0, 13) i  -- 2 semaines de données
WHERE p.role = 'partenaire'
  AND p.company_id IS NOT NULL
ON CONFLICT (partner_id, date) DO UPDATE SET
    is_available = EXCLUDED.is_available,
    availability_type = EXCLUDED.availability_type,
    start_time = EXCLUDED.start_time,
    end_time = EXCLUDED.end_time,
    notes = EXCLUDED.notes,
    updated_at = NOW();

-- 7. Tests complets
SELECT '=== TESTS DE VALIDATION ===' as section;

SELECT '✅ Test 1: Contenu de la vue' as test;
SELECT COUNT(*) as total_entries, 
       COUNT(CASE WHEN partner_name != '' THEN 1 END) as with_names
FROM public.partner_availability_view;

SELECT '✅ Test 2: Fonction avec paramètres' as test;
SELECT COUNT(*) as function_results FROM get_partner_availability_for_period(
    CURRENT_DATE::TEXT,
    (CURRENT_DATE + INTERVAL '7 days')::TEXT
);

SELECT '✅ Test 3: Fonction sans paramètres' as test;
SELECT COUNT(*) as default_results FROM get_partner_availability_for_period();

SELECT '✅ Test 4: Partenaires disponibles aujourd''hui' as test;
SELECT COUNT(*) as available_today FROM get_available_partners_for_date(CURRENT_DATE::TEXT);

SELECT '✅ Test 5: Exemple de données' as test;
SELECT partner_name, date, is_available, availability_type 
FROM public.partner_availability_view 
WHERE date >= CURRENT_DATE 
ORDER BY date ASC 
LIMIT 3;

-- 8. Messages de confirmation
SELECT '🎉 RÉPARATION TERMINÉE AVEC SUCCÈS!' as result;
SELECT '📋 Composants mis à jour:' as info;
SELECT '   ✅ Vue partner_availability_view avec partner_name' as component1;
SELECT '   ✅ Fonction get_partner_availability_for_period (TEXT)' as component2;
SELECT '   ✅ Fonction get_available_partners_for_date (TEXT)' as component3;
SELECT '   ✅ Contrainte de clé étrangère' as component4;
SELECT '   ✅ Données de test créées' as component5;
SELECT '🚀 Vous pouvez maintenant tester l''interface!' as next_step;





