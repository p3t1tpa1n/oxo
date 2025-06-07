-- Vérifier et corriger la structure de la table conversations
DO $$
BEGIN
    -- Vérifier si la table conversations existe
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'conversations') THEN
        -- Créer la table si elle n'existe pas
        CREATE TABLE public.conversations (
            id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
            name text,
            is_group boolean DEFAULT false,
            created_at timestamptz DEFAULT NOW(),
            updated_at timestamptz DEFAULT NOW()
        );
    ELSE
        -- Ajouter les colonnes manquantes si elles n'existent pas
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'is_group') THEN
            ALTER TABLE public.conversations ADD COLUMN is_group boolean DEFAULT false;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'name') THEN
            ALTER TABLE public.conversations ADD COLUMN name text;
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'created_at') THEN
            ALTER TABLE public.conversations ADD COLUMN created_at timestamptz DEFAULT NOW();
        END IF;
        
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'conversations' AND column_name = 'updated_at') THEN
            ALTER TABLE public.conversations ADD COLUMN updated_at timestamptz DEFAULT NOW();
        END IF;
    END IF;
END
$$;

-- Vérifier et corriger la table conversation_participants
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'conversation_participants') THEN
        CREATE TABLE public.conversation_participants (
            id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
            conversation_id uuid REFERENCES public.conversations(id) ON DELETE CASCADE,
            user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
            joined_at timestamptz DEFAULT NOW(),
            UNIQUE(conversation_id, user_id)
        );
    END IF;
END
$$;

-- Vérifier et corriger la table messages
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'messages') THEN
        CREATE TABLE public.messages (
            id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
            conversation_id uuid REFERENCES public.conversations(id) ON DELETE CASCADE,
            sender_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
            content text NOT NULL,
            is_read boolean DEFAULT false,
            created_at timestamptz DEFAULT NOW()
        );
    END IF;
END
$$;

-- Recréer les fonctions RPC avec gestion d'erreur améliorée
DROP FUNCTION IF EXISTS create_conversation(uuid, uuid);
CREATE OR REPLACE FUNCTION create_conversation(p_user_id1 uuid, p_user_id2 uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_conversation_id uuid;
BEGIN
    -- Log des paramètres
    RAISE NOTICE 'create_conversation appelé avec: % et %', p_user_id1, p_user_id2;
    
    -- Vérifier s'il existe déjà une conversation entre ces deux utilisateurs
    SELECT c.id INTO v_conversation_id
    FROM public.conversations c
    WHERE COALESCE(c.is_group, false) = false
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
        RAISE NOTICE 'Création d une nouvelle conversation';
        
        -- Créer la conversation
        INSERT INTO public.conversations (is_group, created_at, updated_at)
        VALUES (false, NOW(), NOW())
        RETURNING id INTO v_conversation_id;

        RAISE NOTICE 'Conversation créée avec ID: %', v_conversation_id;

        -- Ajouter les participants
        INSERT INTO public.conversation_participants (conversation_id, user_id)
        VALUES (v_conversation_id, p_user_id1), (v_conversation_id, p_user_id2);
        
        RAISE NOTICE 'Participants ajoutés';
    ELSE
        RAISE NOTICE 'Conversation existante trouvée: %', v_conversation_id;
    END IF;

    RETURN v_conversation_id;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erreur dans create_conversation: %', SQLERRM;
END;
$$;

-- Recréer la fonction get_user_conversations avec gestion d'erreur
DROP FUNCTION IF EXISTS get_user_conversations(uuid);
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
    RAISE NOTICE 'get_user_conversations appelé pour: %', p_user_id;
    
    RETURN QUERY
    SELECT
        c.id as conversation_id,
        COALESCE(c.name, other_p.email, 'Conversation sans nom') as conversation_name,
        COALESCE(c.is_group, false) as is_group,
        COALESCE(last_m.content, '') as last_message,
        COALESCE(last_m.created_at, c.created_at) as last_message_time,
        COALESCE(unread.count, 0) as unread_count,
        COALESCE(other_p.email, '') as other_user_email
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
    ) other_p ON COALESCE(c.is_group, false) = false
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
        AND COALESCE(m.is_read, false) = false
    ) unread ON true
    WHERE cp.user_id = p_user_id
    ORDER BY COALESCE(last_m.created_at, c.created_at) DESC;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Erreur dans get_user_conversations: %', SQLERRM;
END;
$$; 