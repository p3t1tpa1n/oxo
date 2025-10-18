-- Script SQL pour implémenter les restrictions de messagerie par rôle
-- À exécuter dans l'éditeur SQL de Supabase

-- =====================================================
-- RESTRICTIONS DE MESSAGERIE PAR RÔLE
-- =====================================================
-- Règles :
-- - Associés et Admins : peuvent parler à tout le monde
-- - Clients et Partenaires : peuvent parler seulement aux associés et admins

-- 1. Supprimer les anciennes politiques RLS pour les recréer
DROP POLICY IF EXISTS "Users can view their conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can view conversation participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can add participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON public.messages;
DROP POLICY IF EXISTS "Users can send messages" ON public.messages;
DROP POLICY IF EXISTS "Users can update their messages" ON public.messages;

-- 2. Créer une fonction helper pour vérifier les restrictions de messagerie
CREATE OR REPLACE FUNCTION public.can_message_user(sender_id uuid, recipient_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    sender_role text;
    recipient_role text;
BEGIN
    -- Récupérer les rôles des deux utilisateurs
    SELECT p.role INTO sender_role
    FROM public.profiles p
    WHERE p.user_id = sender_id;
    
    SELECT p.role INTO recipient_role
    FROM public.profiles p
    WHERE p.user_id = recipient_id;
    
    -- Si on ne trouve pas les rôles, autoriser par défaut (compatibilité)
    IF sender_role IS NULL OR recipient_role IS NULL THEN
        RETURN true;
    END IF;
    
    -- Les associés et admins peuvent parler à tout le monde
    IF sender_role IN ('associe', 'admin') THEN
        RETURN true;
    END IF;
    
    -- Les clients et partenaires ne peuvent parler qu'aux associés et admins
    IF sender_role IN ('client', 'partenaire') AND recipient_role IN ('associe', 'admin') THEN
        RETURN true;
    END IF;
    
    -- Sinon, refuser
    RETURN false;
END;
$$;

-- 3. Créer une fonction pour vérifier si un utilisateur peut participer à une conversation
CREATE OR REPLACE FUNCTION public.can_participate_in_conversation(user_id uuid, conversation_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    other_user_id uuid;
    user_role text;
    other_role text;
BEGIN
    -- Récupérer l'autre utilisateur de la conversation (conversations 1-à-1 uniquement)
    SELECT cp.user_id INTO other_user_id
    FROM public.conversation_participants cp
    WHERE cp.conversation_id = can_participate_in_conversation.conversation_id
      AND cp.user_id != can_participate_in_conversation.user_id
    LIMIT 1;
    
    -- Si c'est une conversation de groupe ou si on ne trouve pas l'autre utilisateur, autoriser
    IF other_user_id IS NULL THEN
        RETURN true;
    END IF;
    
    -- Utiliser la fonction can_message_user pour vérifier les permissions
    RETURN public.can_message_user(can_participate_in_conversation.user_id, other_user_id);
END;
$$;

-- 4. Nouvelles politiques RLS pour les conversations
CREATE POLICY "Restricted conversation access"
ON public.conversations FOR SELECT
TO authenticated
USING (
    id IN (
        SELECT conversation_id 
        FROM public.conversation_participants 
        WHERE user_id = auth.uid()
          AND public.can_participate_in_conversation(auth.uid(), conversation_id)
    )
);

CREATE POLICY "Restricted conversation creation"
ON public.conversations FOR INSERT
TO authenticated
WITH CHECK (true); -- La vérification se fera au niveau des participants

-- 5. Nouvelles politiques RLS pour les participants
CREATE POLICY "Restricted participant access"
ON public.conversation_participants FOR SELECT
TO authenticated
USING (
    user_id = auth.uid() 
    OR public.can_participate_in_conversation(auth.uid(), conversation_id)
);

CREATE POLICY "Restricted participant addition"
ON public.conversation_participants FOR INSERT
TO authenticated
WITH CHECK (
    -- L'utilisateur peut s'ajouter lui-même
    user_id = auth.uid()
    OR 
    -- Ou il peut ajouter quelqu'un s'il a le droit de lui parler
    public.can_message_user(auth.uid(), user_id)
);

-- 6. Nouvelles politiques RLS pour les messages
CREATE POLICY "Restricted message access"
ON public.messages FOR SELECT
TO authenticated
USING (
    conversation_id IN (
        SELECT conversation_id
        FROM public.conversation_participants
        WHERE user_id = auth.uid()
          AND public.can_participate_in_conversation(auth.uid(), conversation_id)
    )
);

CREATE POLICY "Restricted message sending"
ON public.messages FOR INSERT
TO authenticated
WITH CHECK (
    sender_id = auth.uid() 
    AND conversation_id IN (
        SELECT conversation_id
        FROM public.conversation_participants
        WHERE user_id = auth.uid()
          AND public.can_participate_in_conversation(auth.uid(), conversation_id)
    )
);

CREATE POLICY "Restricted message updates"
ON public.messages FOR UPDATE
TO authenticated
USING (
    sender_id = auth.uid()
    AND conversation_id IN (
        SELECT conversation_id
        FROM public.conversation_participants
        WHERE user_id = auth.uid()
          AND public.can_participate_in_conversation(auth.uid(), conversation_id)
    )
);

-- 7. Mettre à jour la fonction create_conversation pour respecter les restrictions
CREATE OR REPLACE FUNCTION public.create_conversation(p_user_id1 uuid, p_user_id2 uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    conversation_uuid uuid;
    existing_conversation_id uuid;
BEGIN
    -- Vérifier si l'utilisateur peut envoyer un message à l'autre
    IF NOT public.can_message_user(p_user_id1, p_user_id2) THEN
        RAISE EXCEPTION 'Vous n''êtes pas autorisé à créer une conversation avec cet utilisateur';
    END IF;
    
    -- Vérifier s'il existe déjà une conversation entre ces deux utilisateurs
    SELECT c.id INTO existing_conversation_id
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
    LIMIT 1;
    
    -- Si une conversation existe déjà, la retourner
    IF existing_conversation_id IS NOT NULL THEN
        RETURN existing_conversation_id;
    END IF;
    
    -- Créer une nouvelle conversation
    INSERT INTO public.conversations (is_group, created_at, updated_at)
    VALUES (false, NOW(), NOW())
    RETURNING id INTO conversation_uuid;
    
    -- Ajouter les deux participants
    INSERT INTO public.conversation_participants (conversation_id, user_id, joined_at)
    VALUES 
        (conversation_uuid, p_user_id1, NOW()),
        (conversation_uuid, p_user_id2, NOW());
    
    RETURN conversation_uuid;
END;
$$;

-- 8. Messages de confirmation
SELECT '✅ Restrictions de messagerie par rôle implémentées avec succès!' as result;
SELECT '📋 Règles appliquées:' as info;
SELECT '   - Associés/Admins: peuvent parler à tout le monde' as rule1;
SELECT '   - Clients/Partenaires: peuvent parler seulement aux associés/admins' as rule2;

