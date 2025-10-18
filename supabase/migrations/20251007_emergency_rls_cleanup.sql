-- ============================================================================
-- NETTOYAGE D'URGENCE DES POLITIQUES RLS - CORRECTION RÉCURSION INFINIE
-- Priorité: CRITIQUE - À exécuter immédiatement
-- ============================================================================

-- ============================================================================
-- 1. SUPPRESSION COMPLÈTE DE TOUTES LES POLITIQUES PROBLÉMATIQUES
-- ============================================================================

-- 1.1 Supprimer TOUTES les politiques profiles (sources de récursion)
DROP POLICY IF EXISTS "Users can view profiles in their company" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can manage company profiles" ON profiles;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON profiles;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON profiles;
DROP POLICY IF EXISTS "Enable update for profile owners and admins" ON profiles;
DROP POLICY IF EXISTS "Tout le monde peut lire les profils" ON profiles;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leur propre profil" ON profiles;
DROP POLICY IF EXISTS "Seuls les administrateurs peuvent créer des profils" ON profiles;
DROP POLICY IF EXISTS "Seuls les administrateurs peuvent supprimer des profils" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
DROP POLICY IF EXISTS "Users can insert their own profile." ON profiles;
DROP POLICY IF EXISTS "Users can update own profile." ON profiles;
DROP POLICY IF EXISTS "Profiles are viewable by users who created them." ON profiles;
DROP POLICY IF EXISTS "Les administrateurs ont tous les droits" ON profiles;
DROP POLICY IF EXISTS "Les utilisateurs peuvent voir leur propre profil" ON profiles;

-- 1.2 Supprimer les politiques conversations problématiques
DROP POLICY IF EXISTS "Restricted conversation access" ON conversations;
DROP POLICY IF EXISTS "Restricted conversation creation" ON conversations;
DROP POLICY IF EXISTS "conversations_select_simple" ON conversations;
DROP POLICY IF EXISTS "conversations_insert_simple" ON conversations;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON conversations;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON conversations;
DROP POLICY IF EXISTS "Enable update for conversation participants" ON conversations;
DROP POLICY IF EXISTS "Enable delete for conversation participants" ON conversations;

-- 1.3 Supprimer les politiques messages problématiques
DROP POLICY IF EXISTS "Restricted message access" ON messages;
DROP POLICY IF EXISTS "Restricted message sending" ON messages;
DROP POLICY IF EXISTS "Restricted message updates" ON messages;
DROP POLICY IF EXISTS "messages_select_simple" ON messages;
DROP POLICY IF EXISTS "messages_insert_simple" ON messages;
DROP POLICY IF EXISTS "messages_update_simple" ON messages;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON messages;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON messages;

-- 1.4 Supprimer les politiques conversation_participants problématiques
DROP POLICY IF EXISTS "Restricted participant access" ON conversation_participants;
DROP POLICY IF EXISTS "Restricted participant addition" ON conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_select_simple" ON conversation_participants;
DROP POLICY IF EXISTS "conversation_participants_insert_simple" ON conversation_participants;

-- 1.5 Supprimer les politiques timesheet problématiques
DROP POLICY IF EXISTS "timesheet_entries_select_simple" ON timesheet_entries;
DROP POLICY IF EXISTS "Voir ses propres entrées de temps" ON timesheet_entries;
DROP POLICY IF EXISTS "timesheet_entries_select_policy" ON timesheet_entries;
DROP POLICY IF EXISTS "timesheet_entries_insert_policy" ON timesheet_entries;
DROP POLICY IF EXISTS "timesheet_entries_update_policy" ON timesheet_entries;
DROP POLICY IF EXISTS "timesheet_entries_delete_policy" ON timesheet_entries;

-- ============================================================================
-- 2. DÉSACTIVATION TEMPORAIRE DE RLS POUR DIAGNOSTIC
-- ============================================================================

-- Désactiver RLS temporairement sur les tables problématiques
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants DISABLE ROW LEVEL SECURITY;
ALTER TABLE timesheet_entries DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3. CRÉATION DE POLITIQUES ULTRA-SIMPLES (SANS RÉCURSION)
-- ============================================================================

-- 3.1 Réactiver RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE timesheet_entries ENABLE ROW LEVEL SECURITY;

-- 3.2 Politiques profiles ultra-simples (PAS de référence à profiles)
DROP POLICY IF EXISTS "profiles_select_own" ON profiles;
CREATE POLICY "profiles_select_own" ON profiles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "profiles_update_own" ON profiles;
CREATE POLICY "profiles_update_own" ON profiles
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "profiles_insert_own" ON profiles;
CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 3.3 Politiques conversations ultra-simples
DROP POLICY IF EXISTS "conversations_select_participants" ON conversations;
CREATE POLICY "conversations_select_participants" ON conversations
  FOR SELECT
  TO authenticated
  USING (
    id IN (
      SELECT conversation_id FROM conversation_participants
      WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "conversations_insert_any" ON conversations;
CREATE POLICY "conversations_insert_any" ON conversations
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- 3.4 Politiques messages ultra-simples
DROP POLICY IF EXISTS "messages_select_participants" ON messages;
CREATE POLICY "messages_select_participants" ON messages
  FOR SELECT
  TO authenticated
  USING (
    conversation_id IN (
      SELECT conversation_id FROM conversation_participants
      WHERE user_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "messages_insert_own" ON messages;
CREATE POLICY "messages_insert_own" ON messages
  FOR INSERT
  TO authenticated
  WITH CHECK (
    sender_id = auth.uid() AND
    conversation_id IN (
      SELECT conversation_id FROM conversation_participants
      WHERE user_id = auth.uid()
    )
  );

-- 3.5 Politiques conversation_participants ultra-simples
DROP POLICY IF EXISTS "conversation_participants_select_own" ON conversation_participants;
CREATE POLICY "conversation_participants_select_own" ON conversation_participants
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "conversation_participants_insert_own" ON conversation_participants;
CREATE POLICY "conversation_participants_insert_own" ON conversation_participants
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- 3.6 Politiques timesheet ultra-simples
DROP POLICY IF EXISTS "timesheet_entries_select_own" ON timesheet_entries;
CREATE POLICY "timesheet_entries_select_own" ON timesheet_entries
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "timesheet_entries_insert_own" ON timesheet_entries;
CREATE POLICY "timesheet_entries_insert_own" ON timesheet_entries
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "timesheet_entries_update_own" ON timesheet_entries;
CREATE POLICY "timesheet_entries_update_own" ON timesheet_entries
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "timesheet_entries_delete_own" ON timesheet_entries;
CREATE POLICY "timesheet_entries_delete_own" ON timesheet_entries
  FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- ============================================================================
-- 4. SUPPRESSION DES FONCTIONS PROBLÉMATIQUES
-- ============================================================================

-- Supprimer les fonctions qui peuvent causer des problèmes
DROP FUNCTION IF EXISTS can_message_user(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS can_participate_in_conversation(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS get_user_company_id() CASCADE;

-- ============================================================================
-- 5. CRÉATION D'UNE FONCTION SIMPLE POUR LA MESSAGERIE
-- ============================================================================

-- Fonction ultra-simple pour vérifier les permissions de messagerie
CREATE FUNCTION can_send_message(
  p_sender_id uuid,
  p_recipient_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
BEGIN
  -- Pour l'instant, permettre à tous les utilisateurs authentifiés
  -- de s'envoyer des messages (sécurité basique)
  RETURN p_sender_id = auth.uid();
END;
$$;

COMMENT ON FUNCTION can_send_message(uuid, uuid) IS 
  'Fonction simple pour vérifier les permissions de messagerie';

-- ============================================================================
-- 6. VÉRIFICATIONS ET TESTS
-- ============================================================================

-- Test de base pour vérifier que les politiques fonctionnent
DO $$
DECLARE
  test_user_id uuid;
  test_result boolean;
BEGIN
  -- Vérifier qu'on peut lire son propre profil
  SELECT EXISTS(
    SELECT 1 FROM profiles 
    WHERE user_id = auth.uid()
  ) INTO test_result;
  
  IF test_result THEN
    RAISE NOTICE '✅ Test profiles: OK - Peut lire son propre profil';
  ELSE
    RAISE NOTICE '❌ Test profiles: ÉCHEC - Ne peut pas lire son propre profil';
  END IF;
  
  RAISE NOTICE '🔧 Nettoyage RLS terminé - Politiques ultra-simples appliquées';
  RAISE NOTICE '📝 Testez maintenant votre application';
  
END $$;

-- ============================================================================
-- 7. INSTRUCTIONS POST-NETTOYAGE
-- ============================================================================

COMMENT ON SCHEMA public IS 
'NETTOYAGE RLS APPLIQUÉ - Politiques ultra-simples sans récursion. 
Testez votre application maintenant. Si ça fonctionne, on pourra 
ajouter progressivement des politiques plus sophistiquées.';
