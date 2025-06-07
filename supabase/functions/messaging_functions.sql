-- Tables pour la messagerie
CREATE TABLE IF NOT EXISTS public.conversations (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    name text,
    is_group boolean DEFAULT false,
    created_at timestamptz DEFAULT NOW(),
    updated_at timestamptz DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.conversation_participants (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id uuid REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    joined_at timestamptz DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id uuid REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT NOW()
);

-- Index pour optimiser les performances
CREATE INDEX IF NOT EXISTS conversations_updated_at_idx ON public.conversations(updated_at);
CREATE INDEX IF NOT EXISTS conversation_participants_conversation_id_idx ON public.conversation_participants(conversation_id);
CREATE INDEX IF NOT EXISTS conversation_participants_user_id_idx ON public.conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS messages_conversation_id_idx ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS messages_sender_id_idx ON public.messages(sender_id);
CREATE INDEX IF NOT EXISTS messages_created_at_idx ON public.messages(created_at);

-- Politiques de sécurité
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Politiques pour conversations
DROP POLICY IF EXISTS "Users can view their conversations" ON public.conversations;
CREATE POLICY "Users can view their conversations"
ON public.conversations FOR SELECT
TO authenticated
USING (
    id IN (
        SELECT conversation_id
        FROM public.conversation_participants
        WHERE user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
CREATE POLICY "Users can create conversations"
ON public.conversations FOR INSERT
TO authenticated
WITH CHECK (true);

-- Politiques pour conversation_participants
DROP POLICY IF EXISTS "Users can view conversation participants" ON public.conversation_participants;
CREATE POLICY "Users can view conversation participants"
ON public.conversation_participants FOR SELECT
TO authenticated
USING (
    conversation_id IN (
        SELECT conversation_id
        FROM public.conversation_participants
        WHERE user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can add participants" ON public.conversation_participants;
CREATE POLICY "Users can add participants"
ON public.conversation_participants FOR INSERT
TO authenticated
WITH CHECK (true);

-- Politiques pour messages
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON public.messages;
CREATE POLICY "Users can view messages in their conversations"
ON public.messages FOR SELECT
TO authenticated
USING (
    conversation_id IN (
        SELECT conversation_id
        FROM public.conversation_participants
        WHERE user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
CREATE POLICY "Users can send messages"
ON public.messages FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = auth.uid() AND
    conversation_id IN (
        SELECT conversation_id
        FROM public.conversation_participants
        WHERE user_id = auth.uid()
    )
);

DROP POLICY IF EXISTS "Users can update their messages" ON public.messages;
CREATE POLICY "Users can update their messages"
ON public.messages FOR UPDATE
TO authenticated
USING (
    conversation_id IN (
        SELECT conversation_id
        FROM public.conversation_participants
        WHERE user_id = auth.uid()
    )
);

-- Fonction pour créer ou récupérer une conversation entre deux utilisateurs
CREATE OR REPLACE FUNCTION create_conversation(p_user_id1 uuid, p_user_id2 uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conversation_id uuid;
BEGIN
    -- Vérifier s'il existe déjà une conversation entre ces deux utilisateurs
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

    -- Si aucune conversation n'existe, en créer une nouvelle
    IF v_conversation_id IS NULL THEN
        -- Créer la conversation
        INSERT INTO public.conversations (is_group, created_at, updated_at)
        VALUES (false, NOW(), NOW())
        RETURNING id INTO v_conversation_id;

        -- Ajouter les participants
        INSERT INTO public.conversation_participants (conversation_id, user_id)
        VALUES (v_conversation_id, p_user_id1), (v_conversation_id, p_user_id2);
    END IF;

    RETURN v_conversation_id;
END;
$$;

-- Fonction pour récupérer les conversations d'un utilisateur
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
        COALESCE(c.name, other_p.email) as conversation_name,
        c.is_group,
        COALESCE(last_m.content, '') as last_message,
        COALESCE(last_m.created_at, c.created_at) as last_message_time,
        COALESCE(unread.count, 0) as unread_count,
        other_p.email as other_user_email
    FROM public.conversations c
    INNER JOIN public.conversation_participants cp ON cp.conversation_id = c.id
    LEFT JOIN LATERAL (
        -- Récupérer l'autre utilisateur pour les conversations 1-à-1
        SELECT p.email
        FROM public.conversation_participants cp2
        INNER JOIN public.profiles p ON p.user_id = cp2.user_id
        WHERE cp2.conversation_id = c.id
        AND cp2.user_id != p_user_id
        LIMIT 1
    ) other_p ON NOT c.is_group
    LEFT JOIN LATERAL (
        -- Récupérer le dernier message
        SELECT content, created_at
        FROM public.messages m
        WHERE m.conversation_id = c.id
        ORDER BY m.created_at DESC
        LIMIT 1
    ) last_m ON true
    LEFT JOIN LATERAL (
        -- Compter les messages non lus
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