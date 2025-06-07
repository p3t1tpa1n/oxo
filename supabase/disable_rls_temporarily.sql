-- Désactiver temporairement RLS pour éliminer la récursion infinie
-- À exécuter dans l'éditeur SQL de Supabase

-- ATTENTION: Cette solution désactive la sécurité RLS temporairement
-- À utiliser uniquement pour le développement/test

-- 1. Désactiver RLS sur toutes les tables problématiques
ALTER TABLE public.tasks DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer toutes les politiques existantes pour éviter les conflits futurs
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.tasks;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.tasks;
DROP POLICY IF EXISTS "Enable update for task owners and admins" ON public.tasks;
DROP POLICY IF EXISTS "Enable delete for task owners and admins" ON public.tasks;
DROP POLICY IF EXISTS "tasks_select_policy" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert_policy" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update_policy" ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete_policy" ON public.tasks;

DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "profiles_select_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_update_own" ON public.profiles;
DROP POLICY IF EXISTS "profiles_insert_own" ON public.profiles;

-- 3. Vérifier que RLS est désactivé
SELECT 
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('tasks', 'profiles');

-- 4. Vérifier qu'il n'y a plus de politiques actives
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
SELECT 'RLS désactivé temporairement sur tasks et profiles. La récursion devrait être résolue.' as status; 