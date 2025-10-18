-- ============================================================================
-- Migration 4: Nettoyage Optionnel - Suppression du Système user_roles Dupliqué
-- Priorité: OPTIONNELLE (À EXÉCUTER APRÈS VALIDATION)
-- Description: Supprime la table user_roles pour utiliser uniquement profiles.role
-- ============================================================================

-- ⚠️ ATTENTION: Cette migration est OPTIONNELLE et DESTRUCTIVE
-- Exécutez-la UNIQUEMENT si vous êtes sûr de vouloir supprimer le système user_roles
-- et utiliser uniquement profiles.role

-- Avant d'exécuter ce script:
-- 1. Vérifiez que votre code Dart n'utilise pas la table user_roles
-- 2. Migrez toutes les données de user_roles vers profiles si nécessaire
-- 3. Testez sur un environnement de développement d'abord
-- 4. Faites une sauvegarde complète de votre base de données

-- ============================================================================
-- SECTION 0: SAUVEGARDE ET VÉRIFICATION
-- ============================================================================

-- 0.1 Créer une table de sauvegarde
CREATE TABLE IF NOT EXISTS _backup_user_roles_20251007 AS
SELECT * FROM user_roles;

COMMENT ON TABLE _backup_user_roles_20251007 IS 
  'Sauvegarde de user_roles avant suppression - NE PAS SUPPRIMER';

-- 0.2 Vérifier les divergences entre user_roles et profiles
DO $$
DECLARE
  divergent_count INTEGER;
  missing_in_profiles INTEGER;
  rec RECORD;
BEGIN
  -- Compter les utilisateurs avec des rôles différents
  SELECT COUNT(*)
  INTO divergent_count
  FROM user_roles ur
  JOIN profiles p ON p.user_id = ur.user_id
  WHERE ur.user_role::text != p.role::text;
  
  IF divergent_count > 0 THEN
    RAISE WARNING '⚠️  % utilisateurs ont des rôles différents entre user_roles et profiles', divergent_count;
    
    -- Afficher les détails
    RAISE NOTICE 'Utilisateurs avec divergences:';
    FOR rec IN 
      SELECT ur.user_id, ur.user_role as role_in_user_roles, p.role as role_in_profiles
      FROM user_roles ur
      JOIN profiles p ON p.user_id = ur.user_id
      WHERE ur.user_role::text != p.role::text
    LOOP
      RAISE NOTICE 'User: %, user_roles: %, profiles: %', rec.user_id, rec.role_in_user_roles, rec.role_in_profiles;
    END LOOP;
  ELSE
    RAISE NOTICE '✓ Tous les rôles sont cohérents entre user_roles et profiles';
  END IF;
  
  -- Compter les utilisateurs dans user_roles mais pas dans profiles
  SELECT COUNT(*)
  INTO missing_in_profiles
  FROM user_roles ur
  WHERE NOT EXISTS (SELECT 1 FROM profiles p WHERE p.user_id = ur.user_id);
  
  IF missing_in_profiles > 0 THEN
    RAISE WARNING '⚠️  % utilisateurs dans user_roles n''ont pas de profil dans profiles', missing_in_profiles;
  ELSE
    RAISE NOTICE '✓ Tous les utilisateurs de user_roles ont un profil';
  END IF;
END $$;

-- ============================================================================
-- SECTION 1: MIGRATION DES DONNÉES (SI NÉCESSAIRE)
-- ============================================================================

-- 1.1 Synchroniser les rôles de user_roles vers profiles (si profiles.role est vide)
-- DÉCOMMENTEZ SI VOUS VOULEZ UTILISER user_roles COMME SOURCE DE VÉRITÉ
/*
UPDATE profiles p
SET role = ur.user_role::user_role
FROM user_roles ur
WHERE p.user_id = ur.user_id
  AND (p.role IS NULL OR p.role != ur.user_role::user_role);
*/

-- 1.2 OU synchroniser les rôles de profiles vers user_roles (si user_roles est la cible)
-- DÉCOMMENTEZ SI VOUS VOULEZ UTILISER profiles COMME SOURCE DE VÉRITÉ
/*
UPDATE user_roles ur
SET user_role = p.role::text
FROM profiles p
WHERE ur.user_id = p.user_id
  AND ur.user_role != p.role::text;
*/

-- ============================================================================
-- SECTION 2: MISE À JOUR DES POLITIQUES RLS
-- ============================================================================

-- Avant de supprimer user_roles, mettre à jour toutes les politiques qui l'utilisent

-- 2.1 Identifier les politiques utilisant user_roles
DO $$
DECLARE
  policy_record RECORD;
  policies_count INTEGER := 0;
BEGIN
  FOR policy_record IN
    SELECT schemaname, tablename, policyname, definition
    FROM pg_policies
    WHERE schemaname = 'public'
      AND definition LIKE '%user_roles%'
  LOOP
    policies_count := policies_count + 1;
    RAISE NOTICE 'Politique à mettre à jour: %.% - %', 
      policy_record.tablename, policy_record.policyname, 
      substring(policy_record.definition for 100);
  END LOOP;
  
  IF policies_count > 0 THEN
    RAISE WARNING '⚠️  % politiques utilisent encore user_roles et doivent être mises à jour', policies_count;
  ELSE
    RAISE NOTICE '✓ Aucune politique n''utilise user_roles';
  END IF;
END $$;

-- 2.2 Exemples de remplacement dans les politiques
-- Remplacer:
--   SELECT 1 FROM user_roles WHERE user_id = auth.uid() AND user_role = 'admin'
-- Par:
--   SELECT 1 FROM profiles WHERE user_id = auth.uid() AND role = 'admin'::user_role

-- Ces politiques ont déjà été mises à jour dans la migration 2, mais vérifiez votre code

-- ============================================================================
-- SECTION 3: SUPPRESSION DE LA TABLE user_roles
-- ============================================================================

-- ⚠️ DÉCOMMENTEZ UNIQUEMENT APRÈS AVOIR VÉRIFIÉ TOUT CE QUI PRÉCÈDE

-- 3.1 Supprimer les foreign keys pointant vers user_roles (si elles existent)
-- DO $$
-- DECLARE
--   fk_record RECORD;
-- BEGIN
--   FOR fk_record IN
--     SELECT tc.table_name, tc.constraint_name
--     FROM information_schema.table_constraints tc
--     JOIN information_schema.constraint_column_usage ccu 
--       ON tc.constraint_name = ccu.constraint_name
--     WHERE tc.constraint_type = 'FOREIGN KEY'
--       AND ccu.table_name = 'user_roles'
--   LOOP
--     EXECUTE format('ALTER TABLE %I DROP CONSTRAINT %I', 
--       fk_record.table_name, fk_record.constraint_name);
--     RAISE NOTICE 'FK supprimée: %.%', fk_record.table_name, fk_record.constraint_name;
--   END LOOP;
-- END $$;

-- 3.2 Supprimer la table user_roles
-- DROP TABLE IF EXISTS user_roles CASCADE;
-- RAISE NOTICE '✓ Table user_roles supprimée';

-- ============================================================================
-- SECTION 4: SIMPLIFICATION DE LA STRUCTURE conversations
-- ============================================================================

-- La table conversations a une structure rigide (user1_id, user2_id) mais aussi
-- is_group et name. Il faut choisir une approche.

-- Option A: Supprimer user1_id et user2_id, utiliser uniquement conversation_participants
-- DÉCOMMENTEZ SI VOUS VOULEZ CETTE APPROCHE

-- 4.1 Vérifier que tous les participants sont dans conversation_participants
/*
DO $$
BEGIN
  -- Insérer user1_id dans conversation_participants s'il n'y est pas
  INSERT INTO conversation_participants (conversation_id, user_id)
  SELECT id, user1_id
  FROM conversations
  WHERE user1_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = conversations.id
        AND cp.user_id = conversations.user1_id
    );
  
  -- Insérer user2_id dans conversation_participants s'il n'y est pas
  INSERT INTO conversation_participants (conversation_id, user_id)
  SELECT id, user2_id
  FROM conversations
  WHERE user2_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM conversation_participants cp
      WHERE cp.conversation_id = conversations.id
        AND cp.user_id = conversations.user2_id
    );
  
  RAISE NOTICE '✓ Participants migrés vers conversation_participants';
END $$;

-- 4.2 Supprimer les colonnes user1_id et user2_id
ALTER TABLE conversations DROP COLUMN IF EXISTS user1_id CASCADE;
ALTER TABLE conversations DROP COLUMN IF EXISTS user2_id CASCADE;

RAISE NOTICE '✓ Colonnes user1_id et user2_id supprimées de conversations';
*/

-- ============================================================================
-- SECTION 5: CLARIFICATION DES COLONNES tasks
-- ============================================================================

-- La table tasks a plusieurs colonnes d'assignation: assigned_to, partner_id, user_id
-- Il faut clarifier leur utilisation

-- Recommandation: Utiliser uniquement assigned_to et supprimer les doublons

-- 5.1 Documenter l'utilisation actuelle
COMMENT ON COLUMN tasks.assigned_to IS 
  'Utilisateur principal assigné à la tâche (peut être admin, associé, partenaire ou client)';

COMMENT ON COLUMN tasks.partner_id IS 
  '[DEPRECATED] Utiliser assigned_to à la place. Sera supprimé dans une version future.';

COMMENT ON COLUMN tasks.user_id IS 
  '[DEPRECATED] Utiliser assigned_to à la place. Sera supprimé dans une version future.';

-- 5.2 Migration des données (si vous voulez nettoyer)
-- DÉCOMMENTEZ APRÈS VALIDATION

/*
-- Copier partner_id vers assigned_to si assigned_to est NULL
UPDATE tasks
SET assigned_to = partner_id
WHERE assigned_to IS NULL AND partner_id IS NOT NULL;

-- Copier user_id vers assigned_to si assigned_to est encore NULL
UPDATE tasks
SET assigned_to = user_id
WHERE assigned_to IS NULL AND user_id IS NOT NULL;

-- Après validation dans votre application:
-- ALTER TABLE tasks DROP COLUMN partner_id;
-- ALTER TABLE tasks DROP COLUMN user_id;
*/

-- ============================================================================
-- SECTION 6: CORRECTION DE LA RELATION invoices.client
-- ============================================================================

-- invoices.client_user_id devrait probablement pointer vers clients.id
-- plutôt que auth.users.id directement

-- Option: Ajouter une colonne client_id et la populer
/*
-- 6.1 Ajouter la colonne
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS client_id uuid;

-- 6.2 Populer depuis la relation project → client
UPDATE invoices i
SET client_id = p.client_id
FROM projects p
WHERE i.project_id = p.id
  AND i.client_id IS NULL;

-- 6.3 Ajouter la foreign key
ALTER TABLE invoices
ADD CONSTRAINT fk_invoices_client_id
FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE RESTRICT;

-- 6.4 Marquer client_user_id comme deprecated
COMMENT ON COLUMN invoices.client_user_id IS 
  '[DEPRECATED] Utiliser client_id à la place. Sera supprimé dans une version future.';

-- Après validation:
-- ALTER TABLE invoices DROP COLUMN client_user_id;
*/

-- ============================================================================
-- VÉRIFICATIONS FINALES
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '================================================';
  RAISE NOTICE 'Migration 4 (OPTIONNELLE) préparée';
  RAISE NOTICE '================================================';
  RAISE NOTICE 'ACTIONS REQUISES:';
  RAISE NOTICE '1. Vérifiez la sauvegarde: SELECT * FROM _backup_user_roles_20251007';
  RAISE NOTICE '2. Vérifiez les divergences de rôles ci-dessus';
  RAISE NOTICE '3. Décommentez les sections que vous voulez appliquer';
  RAISE NOTICE '4. Testez d''abord sur un environnement de développement';
  RAISE NOTICE '5. Mettez à jour votre code Dart en conséquence';
  RAISE NOTICE '================================================';
END $$;

COMMENT ON SCHEMA public IS 'Migration 4 (OPTIONNELLE) préparée: user_roles, conversations, tasks cleanup';


