-- Script de diagnostic pour les disponibilités des partenaires
-- À exécuter dans l'éditeur SQL de Supabase

-- =====================================================
-- DIAGNOSTIC DES DISPONIBILITÉS
-- =====================================================

-- 1. Vérifier si la table partner_availability existe et contient des données
SELECT '1. Contenu de la table partner_availability:' as diagnostic;
SELECT 
    COUNT(*) as total_entries,
    COUNT(CASE WHEN is_available = true THEN 1 END) as available_count,
    COUNT(CASE WHEN is_available = false THEN 1 END) as unavailable_count,
    MIN(date) as earliest_date,
    MAX(date) as latest_date
FROM public.partner_availability;

-- 2. Afficher quelques exemples de données
SELECT '2. Exemples de données dans partner_availability:' as diagnostic;
SELECT 
    partner_id,
    company_id,
    date,
    is_available,
    availability_type,
    start_time,
    end_time,
    notes,
    created_at
FROM public.partner_availability 
ORDER BY date DESC 
LIMIT 5;

-- 3. Vérifier si la vue partner_availability_view existe et fonctionne
SELECT '3. Test de la vue partner_availability_view:' as diagnostic;
SELECT 
    COUNT(*) as total_in_view,
    COUNT(DISTINCT partner_id) as unique_partners
FROM public.partner_availability_view;

-- 4. Afficher quelques exemples de la vue
SELECT '4. Exemples de données dans partner_availability_view:' as diagnostic;
SELECT 
    partner_id,
    partner_name,
    partner_email,
    date,
    is_available,
    availability_type
FROM public.partner_availability_view 
ORDER BY date DESC 
LIMIT 5;

-- 5. Vérifier les profils des partenaires
SELECT '5. Profils des partenaires:' as diagnostic;
SELECT 
    p.user_id,
    p.first_name,
    p.last_name,
    p.email,
    p.role,
    p.company_id
FROM public.profiles p
WHERE p.role = 'partenaire'
ORDER BY p.created_at DESC
LIMIT 5;

-- 6. Tester la fonction get_partner_availability_for_period
SELECT '6. Test de la fonction get_partner_availability_for_period:' as diagnostic;
SELECT * FROM get_partner_availability_for_period(
    CURRENT_DATE - INTERVAL '7 days',
    CURRENT_DATE + INTERVAL '7 days'
)
LIMIT 5;

-- 7. Vérifier les permissions RLS
SELECT '7. Vérification des politiques RLS:' as diagnostic;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'partner_availability';

-- 8. Compter les données par entreprise
SELECT '8. Données par entreprise:' as diagnostic;
SELECT 
    pa.company_id,
    COUNT(*) as availability_count,
    COUNT(DISTINCT pa.partner_id) as unique_partners,
    MIN(pa.date) as earliest_date,
    MAX(pa.date) as latest_date
FROM public.partner_availability pa
GROUP BY pa.company_id
ORDER BY availability_count DESC;

-- 9. Vérifier les données récentes
SELECT '9. Données des 7 derniers jours:' as diagnostic;
SELECT 
    date,
    COUNT(*) as entries_count,
    COUNT(CASE WHEN is_available = true THEN 1 END) as available_count
FROM public.partner_availability 
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY date
ORDER BY date DESC;

-- 10. Message de fin
SELECT '✅ Diagnostic terminé! Vérifiez les résultats ci-dessus.' as result;

