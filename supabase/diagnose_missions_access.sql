-- ============================================
-- Script de diagnostic pour comprendre pourquoi les missions ne sont pas accessibles
-- ============================================

-- 1. Vérifier que la table missions existe et contient des données
SELECT 
    'Total missions dans la table' as info,
    COUNT(*) as count
FROM missions;

-- 2. Voir quelques exemples de missions
SELECT 
    id,
    title,
    status,
    progress_status,
    company_id,
    partner_id,
    client_id,
    created_at
FROM missions
ORDER BY created_at DESC
LIMIT 5;

-- 3. Vérifier si RLS est activé sur la table missions
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables
WHERE tablename = 'missions';

-- 4. Lister toutes les politiques RLS sur missions
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'missions'
ORDER BY policyname;

-- 5. Vérifier l'utilisateur actuel et son rôle
SELECT 
    auth.uid() as current_user_id,
    ur.role,
    ur.company_id
FROM user_roles ur
WHERE ur.user_id = auth.uid();

-- 6. Tester l'accès aux missions avec l'utilisateur actuel
-- Cette requête simule ce que fait l'application
SELECT 
    COUNT(*) as missions_accessibles
FROM missions
WHERE true; -- Supabase appliquera automatiquement les politiques RLS

-- 7. Vérifier si les missions ont un company_id
SELECT 
    CASE 
        WHEN company_id IS NULL THEN 'Sans company_id'
        ELSE 'Avec company_id'
    END as type,
    COUNT(*) as count
FROM missions
GROUP BY (company_id IS NULL);

-- 8. Comparer le company_id de l'utilisateur avec celui des missions
SELECT 
    'Missions avec le même company_id que l\'utilisateur' as info,
    COUNT(*) as count
FROM missions m
WHERE m.company_id = (
    SELECT company_id 
    FROM user_roles 
    WHERE user_id = auth.uid() 
    LIMIT 1
);

-- 9. Vérifier les missions par progress_status
SELECT 
    COALESCE(progress_status::text, 'NULL') as progress_status,
    COUNT(*) as count
FROM missions
GROUP BY progress_status
ORDER BY count DESC;

-- 10. Test : Désactiver temporairement RLS pour voir si c'est le problème
-- ⚠️ NE PAS EXÉCUTER EN PRODUCTION - JUSTE POUR DIAGNOSTIC
-- ALTER TABLE missions DISABLE ROW LEVEL SECURITY;
-- SELECT COUNT(*) FROM missions;
-- ALTER TABLE missions ENABLE ROW LEVEL SECURITY;

COMMIT;

