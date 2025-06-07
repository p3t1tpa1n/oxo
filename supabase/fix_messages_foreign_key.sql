-- Corriger la contrainte de clé étrangère de la table messages
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Supprimer la contrainte problématique qui référence 'profiles'
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_sender_id_fkey;

-- 2. Recréer la contrainte pour référencer auth.users au lieu de profiles
ALTER TABLE public.messages 
ADD CONSTRAINT messages_sender_id_fkey 
FOREIGN KEY (sender_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 3. Vérifier la nouvelle contrainte
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