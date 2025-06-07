-- Script ULTRA SIMPLE pour la messagerie - SANS AUCUNE SÉCURITÉ RLS
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. TOUT SUPPRIMER (approche radicale)
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.conversation_participants CASCADE;
DROP TABLE IF EXISTS public.conversations CASCADE;

-- 2. RECRÉER conversations (simple)
CREATE TABLE public.conversations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text,
    is_group boolean DEFAULT false,
    created_at timestamptz DEFAULT NOW(),
    updated_at timestamptz DEFAULT NOW()
);

-- 3. RECRÉER conversation_participants (simple)
CREATE TABLE public.conversation_participants (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id uuid REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at timestamptz DEFAULT NOW()
);

-- 4. RECRÉER messages (simple - SANS contrainte profiles)
CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id uuid REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT NOW()
);

-- 5. AUCUN RLS - ACCÈS TOTAL POUR TOUS
-- (temporaire pour les tests)

-- 6. Recréer les fonctions RPC
CREATE OR REPLACE FUNCTION create_conversation(p_user_id1 uuid, p_user_id2 uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conversation_id uuid;
BEGIN
    -- Chercher conversation existante
    SELECT c.id INTO v_conversation_id
    FROM public.conversations c
    WHERE c.is_group = false
    AND EXISTS (
        SELECT 1 FROM public.conversation_participants cp1
        WHERE cp1.conversation_id = c.id AND cp1.user_id = p_user_id1
    )
    AND EXISTS (
        SELECT 1 FROM public.conversation_participants cp2
        WHERE cp2.conversation_id = c.id AND cp2.user_id = p_user_id2
    )
    AND (
        SELECT COUNT(*)
        FROM public.conversation_participants cp
        WHERE cp.conversation_id = c.id
    ) = 2;

    -- Si pas trouvée, créer nouvelle conversation
    IF v_conversation_id IS NULL THEN
        INSERT INTO public.conversations (is_group, created_at, updated_at)
        VALUES (false, NOW(), NOW())
        RETURNING id INTO v_conversation_id;

        INSERT INTO public.conversation_participants (conversation_id, user_id)
        VALUES (v_conversation_id, p_user_id1), (v_conversation_id, p_user_id2);
    END IF;

    RETURN v_conversation_id;
END;
$$;

CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id uuid)
RETURNS TABLE (
    conversation_id uuid,
    conversation_name text,
    is_group boolean,
    last_message text,
    last_message_time timestamptz,
    unread_count bigint,
    other_user_email text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id as conversation_id,
        COALESCE(c.name, other_p.email, 'Conversation') as conversation_name,
        c.is_group,
        COALESCE(last_m.content, '') as last_message,
        COALESCE(last_m.created_at, c.created_at) as last_message_time,
        COALESCE(unread.count, 0) as unread_count,
        COALESCE(other_p.email, '') as other_user_email
    FROM public.conversations c
    INNER JOIN public.conversation_participants cp ON cp.conversation_id = c.id
    LEFT JOIN LATERAL (
        SELECT p.email
        FROM public.conversation_participants cp2
        INNER JOIN public.profiles p ON p.user_id = cp2.user_id
        WHERE cp2.conversation_id = c.id
        AND cp2.user_id != p_user_id
        LIMIT 1
    ) other_p ON c.is_group = false
    LEFT JOIN LATERAL (
        SELECT content, created_at
        FROM public.messages m
        WHERE m.conversation_id = c.id
        ORDER BY m.created_at DESC
        LIMIT 1
    ) last_m ON true
    LEFT JOIN LATERAL (
        SELECT COUNT(*) as count
        FROM public.messages m
        WHERE m.conversation_id = c.id
        AND m.sender_id != p_user_id
        AND m.is_read = false
    ) unread ON true
    WHERE cp.user_id = p_user_id
    ORDER BY COALESCE(last_m.created_at, c.created_at) DESC;
END;
$$; 