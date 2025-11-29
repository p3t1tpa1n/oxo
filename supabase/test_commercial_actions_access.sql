-- ============================================================================
-- TEST: Accès aux actions commerciales - Diagnostic complet
-- ============================================================================
-- Ce script teste l'accès aux actions commerciales avec et sans RLS
-- ============================================================================

-- 1. Vérifier l'état actuel de RLS
SELECT 
    'RLS Status' as check_type,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE schemaname = 'public' 
AND tablename = 'commercial_actions';

-- 2. Compter les actions commerciales SANS RLS (temporaire)
ALTER TABLE public.commercial_actions DISABLE ROW LEVEL SECURITY;

SELECT 
    'Count without RLS' as method,
    COUNT(*) as total_actions
FROM public.commercial_actions;

-- 3. Voir toutes les actions SANS RLS
SELECT 
    'All actions without RLS' as info,
    id,
    title,
    company_id,
    created_by,
    assigned_to,
    partner_id,
    status
FROM public.commercial_actions
ORDER BY created_at DESC
LIMIT 20;

-- 4. Vérifier les company_id dans les actions
SELECT 
    'Company IDs in actions' as info,
    company_id,
    COUNT(*) as action_count
FROM public.commercial_actions
GROUP BY company_id
ORDER BY action_count DESC;

-- 5. Vérifier les company_id dans profiles pour l'utilisateur actuel
SELECT 
    'User company_id in profiles' as info,
    p.user_id,
    p.company_id,
    p.role,
    u.email
FROM public.profiles p
LEFT JOIN auth.users u ON p.user_id = u.id
WHERE p.user_id = auth.uid();

-- 6. Tester l'accès avec RLS réactivé
ALTER TABLE public.commercial_actions ENABLE ROW LEVEL SECURITY;

SELECT 
    'Count with RLS' as method,
    COUNT(*) as total_actions
FROM public.commercial_actions;

-- 7. Voir les actions accessibles AVEC RLS
SELECT 
    'Accessible actions with RLS' as info,
    id,
    title,
    company_id,
    created_by,
    assigned_to,
    partner_id,
    status
FROM public.commercial_actions
ORDER BY created_at DESC
LIMIT 20;

-- 8. Lister toutes les politiques RLS
SELECT 
    'RLS Policies' as info,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'commercial_actions'
ORDER BY policyname;

-- 9. Test de la fonction RPC (seulement si utilisateur authentifié)
-- Note: Cette fonction nécessite un contexte d'authentification
-- Elle retournera une liste vide si auth.uid() est NULL
DO $$
BEGIN
    IF auth.uid() IS NOT NULL THEN
        RAISE NOTICE 'Test de la fonction RPC avec utilisateur: %', auth.uid();
    ELSE
        RAISE NOTICE '⚠️ Pas d''utilisateur authentifié - la fonction RPC ne peut pas être testée ici';
        RAISE NOTICE '💡 Testez la fonction RPC depuis l''application Flutter où l''utilisateur est authentifié';
    END IF;
END $$;

-- 10. Voir les résultats de la fonction RPC (uniquement si auth.uid() existe)
-- Cette requête échouera silencieusement si pas d'utilisateur authentifié
SELECT 
    'RPC Function Results' as info,
    COUNT(*) as actions_count
FROM get_commercial_actions_for_company()
WHERE EXISTS (SELECT 1 WHERE auth.uid() IS NOT NULL);

-- 11. Message final
SELECT '✅ Diagnostic terminé. Vérifiez les résultats ci-dessus.' as status;

