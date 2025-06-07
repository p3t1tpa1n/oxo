-- Réactiver RLS avec des politiques très simples
-- À exécuter après avoir testé que l'application fonctionne sans RLS

-- 1. Réactiver RLS sur les tables
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. Créer des politiques très permissives pour les utilisateurs authentifiés
-- Politiques pour tasks
CREATE POLICY "tasks_all_authenticated"
ON public.tasks
TO authenticated
USING (true)
WITH CHECK (true);

-- Politiques pour profiles
CREATE POLICY "profiles_all_authenticated"
ON public.profiles
TO authenticated
USING (true)
WITH CHECK (true);

-- 3. Vérifier que RLS est activé
SELECT 
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('tasks', 'profiles');

-- 4. Vérifier les nouvelles politiques
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename IN ('tasks', 'profiles')
ORDER BY tablename, policyname;

-- Message d'information
SELECT 'RLS réactivé avec des politiques très permissives. Vous pouvez maintenant implémenter des politiques plus strictes si nécessaire.' as status; 