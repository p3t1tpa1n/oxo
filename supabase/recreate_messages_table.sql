-- Recréer complètement la table messages avec les bonnes contraintes
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Sauvegarder les messages existants (optionnel)
CREATE TEMP TABLE messages_backup AS SELECT * FROM public.messages;

-- 2. Supprimer complètement la table messages
DROP TABLE IF EXISTS public.messages CASCADE;

-- 3. Recréer la table messages avec les bonnes contraintes
CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    conversation_id uuid REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
    content text NOT NULL,
    is_read boolean DEFAULT false,
    created_at timestamptz DEFAULT NOW()
);

-- 4. Désactiver RLS sur la nouvelle table
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;

-- 5. Vérifier les contraintes de la nouvelle table
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'messages' AND tc.constraint_type = 'FOREIGN KEY';

-- 6. Vérifier que RLS est désactivé
SELECT 
    table_name,
    row_security
FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'messages'; 