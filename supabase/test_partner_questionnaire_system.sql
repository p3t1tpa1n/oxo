-- =============================================
-- SCRIPT DE TEST - SYSTÈME QUESTIONNAIRE PARTENAIRE
-- =============================================

-- 1. Vérifier que les tables existent
SELECT 'VERIFICATION DES TABLES' as test_section;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'partner_profiles') 
        THEN '✅ Table partner_profiles existe' 
        ELSE '❌ Table partner_profiles manquante' 
    END as partner_profiles_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mission_criteria') 
        THEN '✅ Table mission_criteria existe' 
        ELSE '❌ Table mission_criteria manquante' 
    END as mission_criteria_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'partner_mission_matches') 
        THEN '✅ Table partner_mission_matches existe' 
        ELSE '❌ Table partner_mission_matches manquante' 
    END as partner_mission_matches_status;

-- 2. Vérifier la vue partner_profiles_summary
SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'partner_profiles_summary') 
        THEN '✅ Vue partner_profiles_summary existe' 
        ELSE '❌ Vue partner_profiles_summary manquante' 
    END as view_status;

-- 3. Vérifier les fonctions
SELECT 'VERIFICATION DES FONCTIONS' as test_section;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'calculate_partner_match_score') 
        THEN '✅ Fonction calculate_partner_match_score existe' 
        ELSE '❌ Fonction calculate_partner_match_score manquante' 
    END as function_1_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'find_best_partners_for_mission') 
        THEN '✅ Fonction find_best_partners_for_mission existe' 
        ELSE '❌ Fonction find_best_partners_for_mission manquante' 
    END as function_2_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'has_completed_questionnaire') 
        THEN '✅ Fonction has_completed_questionnaire existe' 
        ELSE '❌ Fonction has_completed_questionnaire manquante' 
    END as function_3_status;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname = 'get_partner_profile') 
        THEN '✅ Fonction get_partner_profile existe' 
        ELSE '❌ Fonction get_partner_profile manquante' 
    END as function_4_status;

-- 4. Vérifier les politiques RLS
SELECT 'VERIFICATION DES POLITIQUES RLS' as test_section;

SELECT 
    COUNT(*) as policies_count,
    'Politiques RLS sur partner_profiles' as description
FROM pg_policies 
WHERE tablename = 'partner_profiles';

SELECT 
    COUNT(*) as policies_count,
    'Politiques RLS sur mission_criteria' as description
FROM pg_policies 
WHERE tablename = 'mission_criteria';

SELECT 
    COUNT(*) as policies_count,
    'Politiques RLS sur partner_mission_matches' as description
FROM pg_policies 
WHERE tablename = 'partner_mission_matches';

-- 5. Test d'insertion d'un profil partenaire (simulation)
SELECT 'TEST D_INSERTION' as test_section;

-- Note: Ce test ne sera exécuté que si vous avez un utilisateur connecté
-- Pour tester manuellement, utilisez l'interface Flutter

-- 6. Vérifier les index
SELECT 'VERIFICATION DES INDEX' as test_section;

SELECT 
    COUNT(*) as indexes_count,
    'Index sur partner_profiles' as description
FROM pg_indexes 
WHERE tablename = 'partner_profiles';

-- 7. Résumé final
SELECT 'RESUME FINAL' as test_section;

SELECT 
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_name IN ('partner_profiles', 'mission_criteria', 'partner_mission_matches')) as tables_count,
    (SELECT COUNT(*) FROM information_schema.views WHERE table_name = 'partner_profiles_summary') as views_count,
    (SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname = 'public' AND p.proname IN ('calculate_partner_match_score', 'find_best_partners_for_mission', 'has_completed_questionnaire', 'get_partner_profile')) as functions_count,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename IN ('partner_profiles', 'mission_criteria', 'partner_mission_matches')) as policies_count;
