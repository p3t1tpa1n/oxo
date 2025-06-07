-- Nettoyage final et radical pour éliminer tous les problèmes RLS
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Supprimer ALL les politiques sur toutes nos tables (méthode brutale)
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leurs conversations" ON public.conversations;
DROP POLICY IF EXISTS "Utilisateurs peuvent créer des conversations" ON public.conversations;
DROP POLICY IF EXISTS "Tout le monde peut créer des conversations" ON public.conversations;
DROP POLICY IF EXISTS "Accès total conversations" ON public.conversations;

DROP POLICY IF EXISTS "Participants peuvent voir leurs participations" ON public.conversation_participants;
DROP POLICY IF EXISTS "Tout le monde peut ajouter des participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Utilisateurs peuvent voir les participants de leurs conversations" ON public.conversation_participants;
DROP POLICY IF EXISTS "Utilisateurs peuvent ajouter des participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Accès total participants" ON public.conversation_participants;

DROP POLICY IF EXISTS "Utilisateurs peuvent voir les messages de leurs conversations" ON public.messages;
DROP POLICY IF EXISTS "Utilisateurs peuvent envoyer des messages" ON public.messages;
DROP POLICY IF EXISTS "Utilisateurs peuvent modifier leurs messages" ON public.messages;
DROP POLICY IF EXISTS "Utilisateurs peuvent modifier les messages dans leurs conversations" ON public.messages;
DROP POLICY IF EXISTS "Accès total messages" ON public.messages;

-- 2. Désactiver RLS sur TOUTES les tables
ALTER TABLE public.conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;

-- 3. Sauvegarder les messages existants
DROP TABLE IF EXISTS messages_backup;
CREATE TABLE messages_backup AS SELECT * FROM public.messages;

-- 4. Supprimer et recréer la table messages
DROP TABLE IF EXISTS public.messages CASCADE;

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id uuid REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT NOW()
);

-- 5. S'assurer que RLS est désactivé sur la nouvelle table
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;

-- 6. Test final : vérifier qu'il n'y a plus aucune politique
SELECT COUNT(*) as politiques_restantes
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('conversations', 'conversation_participants', 'messages');

-- 7. Vérifier les contraintes de la table messages
SELECT 
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'messages' AND tc.constraint_type = 'FOREIGN KEY'; 