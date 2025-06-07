-- Corriger le problème de récursion infinie dans les politiques RLS
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Désactiver temporairement RLS sur profiles pour éviter la récursion
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer toutes les politiques existantes sur tasks
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.tasks;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.tasks;
DROP POLICY IF EXISTS "Enable update for task owners and admins" ON public.tasks;
DROP POLICY IF EXISTS "Enable delete for task owners and admins" ON public.tasks;

-- 3. Créer des politiques simplifiées pour tasks sans dépendance sur profiles
CREATE POLICY "tasks_select_policy"
ON public.tasks FOR SELECT
TO authenticated
USING (
  auth.uid() = user_id OR
  auth.uid() = partner_id OR
  auth.uid() = assigned_to OR
  auth.uid() = created_by
);

CREATE POLICY "tasks_insert_policy"
ON public.tasks FOR INSERT
TO authenticated
WITH CHECK (
  auth.uid() = user_id OR
  auth.uid() = created_by
);

CREATE POLICY "tasks_update_policy"
ON public.tasks FOR UPDATE
TO authenticated
USING (
  auth.uid() = user_id OR
  auth.uid() = partner_id OR
  auth.uid() = assigned_to OR
  auth.uid() = created_by
)
WITH CHECK (
  auth.uid() = user_id OR
  auth.uid() = partner_id OR
  auth.uid() = assigned_to OR
  auth.uid() = created_by
);

CREATE POLICY "tasks_delete_policy"
ON public.tasks FOR DELETE
TO authenticated
USING (
  auth.uid() = user_id OR
  auth.uid() = created_by
);

-- 4. Réactiver RLS sur profiles avec des politiques simples
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques sur profiles
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;

-- Créer des politiques simples pour profiles (sans récursion)
CREATE POLICY "profiles_select_own"
ON public.profiles FOR SELECT
TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "profiles_update_own"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "profiles_insert_own"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = user_id);

-- 5. Vérifier que les politiques sont correctement configurées
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
WHERE tablename IN ('tasks', 'profiles')
ORDER BY tablename, policyname; 