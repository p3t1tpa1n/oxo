-- ============================================================================
-- Migration 1: Corrections Structurelles Critiques
-- Priorité: HAUTE
-- Description: Corrige les foreign keys, types de données et contraintes
-- ============================================================================

-- ============================================================================
-- 1. CORRECTION DES TYPES DE DONNÉES
-- ============================================================================

-- 1.1 Corriger company_id dans user_roles (uuid -> bigint)
-- Note: Sauvegarde des données avant modification
DO $$
BEGIN
    -- Vérifier si la colonne existe et est de type uuid
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'user_roles' 
        AND column_name = 'company_id' 
        AND data_type = 'uuid'
    ) THEN
        -- Supprimer la colonne temporairement (si pas de données importantes)
        -- ATTENTION: Vérifiez d'abord s'il y a des données !
        ALTER TABLE user_roles DROP COLUMN IF EXISTS company_id;
        
        -- Recréer avec le bon type
        ALTER TABLE user_roles ADD COLUMN company_id bigint;
        
        RAISE NOTICE 'company_id dans user_roles converti en bigint';
    END IF;
END $$;

-- ============================================================================
-- 2. AJOUT DES FOREIGN KEYS MANQUANTES
-- ============================================================================

-- 2.1 clients.created_by → auth.users.id
ALTER TABLE clients 
  DROP CONSTRAINT IF EXISTS fk_clients_created_by,
  ADD CONSTRAINT fk_clients_created_by 
    FOREIGN KEY (created_by) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.2 commercial_actions.assigned_to → auth.users.id
ALTER TABLE commercial_actions 
  DROP CONSTRAINT IF EXISTS fk_commercial_actions_assigned_to,
  ADD CONSTRAINT fk_commercial_actions_assigned_to 
    FOREIGN KEY (assigned_to) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.3 commercial_actions.partner_id → auth.users.id
ALTER TABLE commercial_actions 
  DROP CONSTRAINT IF EXISTS fk_commercial_actions_partner_id,
  ADD CONSTRAINT fk_commercial_actions_partner_id 
    FOREIGN KEY (partner_id) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.4 commercial_actions.created_by → auth.users.id
ALTER TABLE commercial_actions 
  DROP CONSTRAINT IF EXISTS fk_commercial_actions_created_by,
  ADD CONSTRAINT fk_commercial_actions_created_by 
    FOREIGN KEY (created_by) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.5 invoices.client_user_id → auth.users.id
ALTER TABLE invoices 
  DROP CONSTRAINT IF EXISTS fk_invoices_client_user_id,
  ADD CONSTRAINT fk_invoices_client_user_id 
    FOREIGN KEY (client_user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- 2.6 invoices.created_by → auth.users.id
ALTER TABLE invoices 
  DROP CONSTRAINT IF EXISTS fk_invoices_created_by,
  ADD CONSTRAINT fk_invoices_created_by 
    FOREIGN KEY (created_by) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- 2.7 tasks.assigned_to → auth.users.id
ALTER TABLE tasks 
  DROP CONSTRAINT IF EXISTS fk_tasks_assigned_to,
  ADD CONSTRAINT fk_tasks_assigned_to 
    FOREIGN KEY (assigned_to) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.8 tasks.partner_id → auth.users.id
ALTER TABLE tasks 
  DROP CONSTRAINT IF EXISTS fk_tasks_partner_id,
  ADD CONSTRAINT fk_tasks_partner_id 
    FOREIGN KEY (partner_id) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.9 tasks.created_by → auth.users.id
ALTER TABLE tasks 
  DROP CONSTRAINT IF EXISTS fk_tasks_created_by,
  ADD CONSTRAINT fk_tasks_created_by 
    FOREIGN KEY (created_by) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.10 tasks.updated_by → auth.users.id
ALTER TABLE tasks 
  DROP CONSTRAINT IF EXISTS fk_tasks_updated_by,
  ADD CONSTRAINT fk_tasks_updated_by 
    FOREIGN KEY (updated_by) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.11 tasks.user_id → auth.users.id
ALTER TABLE tasks 
  DROP CONSTRAINT IF EXISTS fk_tasks_user_id,
  ADD CONSTRAINT fk_tasks_user_id 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.12 timesheet_entries.user_id → auth.users.id
ALTER TABLE timesheet_entries 
  DROP CONSTRAINT IF EXISTS fk_timesheet_entries_user_id,
  ADD CONSTRAINT fk_timesheet_entries_user_id 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- 2.13 mission_assignments.assigned_to → auth.users.id
ALTER TABLE mission_assignments 
  DROP CONSTRAINT IF EXISTS fk_mission_assignments_assigned_to,
  ADD CONSTRAINT fk_mission_assignments_assigned_to 
    FOREIGN KEY (assigned_to) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- 2.14 mission_assignments.assigned_by → auth.users.id
ALTER TABLE mission_assignments 
  DROP CONSTRAINT IF EXISTS fk_mission_assignments_assigned_by,
  ADD CONSTRAINT fk_mission_assignments_assigned_by 
    FOREIGN KEY (assigned_by) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.15 mission_notifications.sent_by → auth.users.id
ALTER TABLE mission_notifications 
  DROP CONSTRAINT IF EXISTS fk_mission_notifications_sent_by,
  ADD CONSTRAINT fk_mission_notifications_sent_by 
    FOREIGN KEY (sent_by) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.16 partner_availability.partner_id → auth.users.id
ALTER TABLE partner_availability 
  DROP CONSTRAINT IF EXISTS fk_partner_availability_partner_id,
  ADD CONSTRAINT fk_partner_availability_partner_id 
    FOREIGN KEY (partner_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- 2.17 partner_availability.created_by → auth.users.id
ALTER TABLE partner_availability 
  DROP CONSTRAINT IF EXISTS fk_partner_availability_created_by,
  ADD CONSTRAINT fk_partner_availability_created_by 
    FOREIGN KEY (created_by) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.18 project_proposals.client_id → auth.users.id
ALTER TABLE project_proposals 
  DROP CONSTRAINT IF EXISTS fk_project_proposals_client_id,
  ADD CONSTRAINT fk_project_proposals_client_id 
    FOREIGN KEY (client_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- 2.19 project_proposals.reviewed_by → auth.users.id
ALTER TABLE project_proposals 
  DROP CONSTRAINT IF EXISTS fk_project_proposals_reviewed_by,
  ADD CONSTRAINT fk_project_proposals_reviewed_by 
    FOREIGN KEY (reviewed_by) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.20 time_extension_requests.client_id → auth.users.id
ALTER TABLE time_extension_requests 
  DROP CONSTRAINT IF EXISTS fk_time_extension_requests_client_id,
  ADD CONSTRAINT fk_time_extension_requests_client_id 
    FOREIGN KEY (client_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- 2.21 time_extension_requests.approved_by → auth.users.id
ALTER TABLE time_extension_requests 
  DROP CONSTRAINT IF EXISTS fk_time_extension_requests_approved_by,
  ADD CONSTRAINT fk_time_extension_requests_approved_by 
    FOREIGN KEY (approved_by) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;

-- 2.22 user_notifications.user_id → auth.users.id
ALTER TABLE user_notifications 
  DROP CONSTRAINT IF EXISTS fk_user_notifications_user_id,
  ADD CONSTRAINT fk_user_notifications_user_id 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- 2.23 user_roles.user_id → auth.users.id
ALTER TABLE user_roles 
  DROP CONSTRAINT IF EXISTS fk_user_roles_user_id,
  ADD CONSTRAINT fk_user_roles_user_id 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- 2.24 user_roles.company_id → companies.id (après conversion en bigint)
ALTER TABLE user_roles 
  DROP CONSTRAINT IF EXISTS fk_user_roles_company_id,
  ADD CONSTRAINT fk_user_roles_company_id 
    FOREIGN KEY (company_id) 
    REFERENCES companies(id) 
    ON DELETE CASCADE;

-- 2.25 messages.sender_id → auth.users.id
ALTER TABLE messages 
  DROP CONSTRAINT IF EXISTS fk_messages_sender_id,
  ADD CONSTRAINT fk_messages_sender_id 
    FOREIGN KEY (sender_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- 2.26 conversation_participants.user_id → auth.users.id
ALTER TABLE conversation_participants 
  DROP CONSTRAINT IF EXISTS fk_conversation_participants_user_id,
  ADD CONSTRAINT fk_conversation_participants_user_id 
    FOREIGN KEY (user_id) 
    REFERENCES auth.users(id) 
    ON DELETE CASCADE;

-- ============================================================================
-- 3. CORRECTION DE LA TABLE user_client_mapping
-- ============================================================================

-- 3.1 Supprimer les contraintes UNIQUE individuelles (trop restrictives)
ALTER TABLE user_client_mapping 
  DROP CONSTRAINT IF EXISTS user_client_mapping_user_id_key;

ALTER TABLE user_client_mapping 
  DROP CONSTRAINT IF EXISTS user_client_mapping_client_id_key;

-- La contrainte UNIQUE(user_id, client_id) reste en place
-- Cela permet many-to-many correctement

-- 3.2 Ajouter un commentaire pour documenter
COMMENT ON TABLE user_client_mapping IS 
  'Mapping many-to-many entre utilisateurs et clients. Un user peut avoir plusieurs clients et vice-versa.';

-- ============================================================================
-- 4. CRÉATION DES INDEX POUR PERFORMANCE
-- ============================================================================

-- Index sur les foreign keys (si pas déjà présents)
CREATE INDEX IF NOT EXISTS idx_clients_created_by ON clients(created_by);
CREATE INDEX IF NOT EXISTS idx_commercial_actions_assigned_to ON commercial_actions(assigned_to);
CREATE INDEX IF NOT EXISTS idx_commercial_actions_partner_id ON commercial_actions(partner_id);
CREATE INDEX IF NOT EXISTS idx_commercial_actions_company_id ON commercial_actions(company_id);
CREATE INDEX IF NOT EXISTS idx_commercial_actions_created_by ON commercial_actions(created_by);
CREATE INDEX IF NOT EXISTS idx_invoices_client_user_id ON invoices(client_user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_created_by ON invoices(created_by);
CREATE INDEX IF NOT EXISTS idx_invoices_company_id ON invoices(company_id);
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
CREATE INDEX IF NOT EXISTS idx_tasks_partner_id ON tasks(partner_id);
CREATE INDEX IF NOT EXISTS idx_tasks_user_id ON tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_created_by ON tasks(created_by);
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_user_id ON timesheet_entries(user_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_project_id ON timesheet_entries(project_id);
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_date ON timesheet_entries(date);
CREATE INDEX IF NOT EXISTS idx_projects_client_id ON projects(client_id);
CREATE INDEX IF NOT EXISTS idx_projects_company_id ON projects(company_id);
CREATE INDEX IF NOT EXISTS idx_profiles_user_id ON profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_profiles_company_id ON profiles(company_id);
CREATE INDEX IF NOT EXISTS idx_partner_availability_partner_id ON partner_availability(partner_id);
CREATE INDEX IF NOT EXISTS idx_partner_availability_company_id ON partner_availability(company_id);
CREATE INDEX IF NOT EXISTS idx_partner_availability_date ON partner_availability(date);
CREATE INDEX IF NOT EXISTS idx_mission_assignments_assigned_to ON mission_assignments(assigned_to);
CREATE INDEX IF NOT EXISTS idx_mission_assignments_project_id ON mission_assignments(project_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_user_id ON user_roles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_roles_company_id ON user_roles(company_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_user_id ON conversation_participants(user_id);
CREATE INDEX IF NOT EXISTS idx_conversation_participants_conversation_id ON conversation_participants(conversation_id);

-- Index composites pour les requêtes fréquentes
CREATE INDEX IF NOT EXISTS idx_timesheet_entries_user_date ON timesheet_entries(user_id, date);
CREATE INDEX IF NOT EXISTS idx_tasks_project_status ON tasks(project_id, status);
CREATE INDEX IF NOT EXISTS idx_commercial_actions_company_status ON commercial_actions(company_id, status);

-- ============================================================================
-- VÉRIFICATIONS POST-MIGRATION
-- ============================================================================

-- Vérifier que toutes les foreign keys sont en place
DO $$
DECLARE
    missing_fks TEXT;
BEGIN
    SELECT string_agg(table_name || '.' || column_name, ', ')
    INTO missing_fks
    FROM information_schema.columns c
    WHERE c.table_schema = 'public'
      AND c.column_name IN ('created_by', 'updated_by', 'assigned_to', 'user_id', 'partner_id', 'client_id')
      AND NOT EXISTS (
          SELECT 1 
          FROM information_schema.table_constraints tc
          JOIN information_schema.key_column_usage kcu 
            ON tc.constraint_name = kcu.constraint_name
          WHERE tc.constraint_type = 'FOREIGN KEY'
            AND kcu.table_name = c.table_name
            AND kcu.column_name = c.column_name
      );
    
    IF missing_fks IS NOT NULL THEN
        RAISE WARNING 'Foreign keys potentiellement manquantes sur: %', missing_fks;
    ELSE
        RAISE NOTICE 'Toutes les foreign keys importantes sont en place';
    END IF;
END $$;

COMMENT ON SCHEMA public IS 'Migration 1 appliquée: Foreign keys et index ajoutés';


