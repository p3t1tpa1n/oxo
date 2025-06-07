-- Corriger les politiques RLS qui causent une récursion infinie
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Supprimer toutes les politiques existantes pour repartir à zéro
DROP POLICY IF EXISTS "Utilisateurs peuvent voir leurs conversations" ON public.conversations;
DROP POLICY IF EXISTS "Utilisateurs peuvent créer des conversations" ON public.conversations;
DROP POLICY IF EXISTS "Utilisateurs peuvent voir les participants de leurs conversations" ON public.conversation_participants;
DROP POLICY IF EXISTS "Utilisateurs peuvent ajouter des participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Utilisateurs peuvent voir les messages de leurs conversations" ON public.messages;
DROP POLICY IF EXISTS "Utilisateurs peuvent envoyer des messages" ON public.messages;
DROP POLICY IF EXISTS "Utilisateurs peuvent modifier leurs messages" ON public.messages;

-- 2. Créer des politiques simples et non-récursives

-- Politiques pour conversation_participants (les plus simples en premier)
CREATE POLICY "Participants peuvent voir leurs participations" ON public.conversation_participants
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Tout le monde peut ajouter des participants" ON public.conversation_participants
    FOR INSERT WITH CHECK (true);

-- Politiques pour conversations (en utilisant les politiques de participants)
CREATE POLICY "Utilisateurs peuvent voir leurs conversations" ON public.conversations
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.conversation_id = id AND cp.user_id = auth.uid()
        )
    );

CREATE POLICY "Tout le monde peut créer des conversations" ON public.conversations
    FOR INSERT WITH CHECK (true);

-- Politiques pour messages (en utilisant les politiques de participants)
CREATE POLICY "Utilisateurs peuvent voir les messages de leurs conversations" ON public.messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.conversation_id = conversation_id AND cp.user_id = auth.uid()
        )
    );

CREATE POLICY "Utilisateurs peuvent envoyer des messages" ON public.messages
    FOR INSERT WITH CHECK (
        sender_id = auth.uid() AND
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.conversation_id = conversation_id AND cp.user_id = auth.uid()
        )
    );

CREATE POLICY "Utilisateurs peuvent modifier les messages dans leurs conversations" ON public.messages
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.conversation_participants cp
            WHERE cp.conversation_id = conversation_id AND cp.user_id = auth.uid()
        )
    ); 