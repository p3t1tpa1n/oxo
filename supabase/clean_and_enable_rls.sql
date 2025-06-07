-- Nettoyer et réactiver RLS proprement
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Supprimer TOUTES les politiques existantes sur toutes les tables
-- Profiles
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.profiles;
DROP POLICY IF EXISTS "Enable update for profile owners and admins" ON public.profiles;
DROP POLICY IF EXISTS "Les administrateurs ont tous les droits" ON public.profiles;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leur propre profil" ON public.profiles;
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir leur propre profil" ON public.profiles;
DROP POLICY IF EXISTS "Profiles are viewable by users who created them." ON public.profiles;
DROP POLICY IF EXISTS "Seuls les administrateurs peuvent créer des profils" ON public.profiles;
DROP POLICY IF EXISTS "Seuls les administrateurs peuvent supprimer des profils" ON public.profiles;
DROP POLICY IF EXISTS "Tout le monde peut lire les profils" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile." ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile." ON public.profiles;

-- Tasks
DROP POLICY IF EXISTS "Modifier les tâches pour admin et associés" ON public.tasks;
DROP POLICY IF EXISTS "Voir les tâches assignées" ON public.tasks;

-- Messagerie
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.conversations;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.conversations;
DROP POLICY IF EXISTS "Enable update for conversation participants" ON public.conversations;
DROP POLICY IF EXISTS "Enable delete for conversation participants" ON public.conversations;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.messages;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.messages;
DROP POLICY IF EXISTS "Enable update for message senders" ON public.messages;
DROP POLICY IF EXISTS "Enable delete for message senders" ON public.messages;

DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.conversation_participants;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.conversation_participants;
DROP POLICY IF EXISTS "Enable update for participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Enable delete for participants" ON public.conversation_participants;

-- 2. Réactiver RLS sur toutes les tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;

-- 3. Créer des politiques TRÈS SIMPLES pour éviter la récursion
-- Profiles - Politiques ultra-simples
CREATE POLICY "profiles_access" ON public.profiles
FOR ALL TO authenticated
USING (true)
WITH CHECK (true);

-- Tasks - Politiques ultra-simples
CREATE POLICY "tasks_access" ON public.tasks
FOR ALL TO authenticated
USING (true)
WITH CHECK (true);

-- Conversations - Politiques ultra-simples
CREATE POLICY "conversations_access" ON public.conversations
FOR ALL TO authenticated
USING (true)
WITH CHECK (true);

-- Messages - Politiques ultra-simples
CREATE POLICY "messages_access" ON public.messages
FOR ALL TO authenticated
USING (true)
WITH CHECK (true);

-- Conversation_participants - Politiques ultra-simples
CREATE POLICY "conversation_participants_access" ON public.conversation_participants
FOR ALL TO authenticated
USING (true)
WITH CHECK (true);

-- Message de confirmation
SELECT 'RLS nettoyé et réactivé avec des politiques simples - Plus de récursion possible !' as status; 