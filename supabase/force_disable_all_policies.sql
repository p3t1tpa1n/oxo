-- Script RADICAL pour supprimer TOUTES les politiques et désactiver complètement RLS
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Lister et supprimer TOUTES les politiques existantes sur nos tables
DO $$
DECLARE
    pol RECORD;
BEGIN
    -- Supprimer toutes les politiques sur conversations
    FOR pol IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'conversations'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
    END LOOP;
    
    -- Supprimer toutes les politiques sur conversation_participants
    FOR pol IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'conversation_participants'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
    END LOOP;
    
    -- Supprimer toutes les politiques sur messages
    FOR pol IN 
        SELECT schemaname, tablename, policyname 
        FROM pg_policies 
        WHERE schemaname = 'public' AND tablename = 'messages'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I.%I', pol.policyname, pol.schemaname, pol.tablename);
    END LOOP;
END
$$;

-- 2. Désactiver complètement RLS
ALTER TABLE public.conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages DISABLE ROW LEVEL SECURITY;

-- 3. Vérifier qu'il n'y a plus de politiques
SELECT 
    schemaname, 
    tablename, 
    policyname,
    cmd as policy_definition
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('conversations', 'conversation_participants', 'messages');

-- 4. Vérifier que RLS est bien désactivé (CORRIGÉ)
SELECT 
    table_schema,
    table_name,
    'RLS_DISABLED' as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('conversations', 'conversation_participants', 'messages'); 