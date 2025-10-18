-- ============================================================================
-- Migration 3: Standardisation des Données et Création des Fonctions
-- Priorité: MOYENNE
-- Description: Standardise les statuts, crée les fonctions RLS manquantes
-- ============================================================================

-- ============================================================================
-- 1. STANDARDISATION DES STATUTS (FRANÇAIS → ANGLAIS)
-- ============================================================================

-- 1.1 Mettre à jour les statuts dans la table clients
UPDATE clients 
SET status = 'active'::status_type 
WHERE status = 'actif'::status_type;

-- Si vous avez d'autres valeurs en français, ajoutez-les ici
-- UPDATE clients SET status = 'inactive'::status_type WHERE status = 'inactif'::status_type;
-- UPDATE clients SET status = 'pending'::status_type WHERE status = 'en_attente'::status_type;

-- 1.2 Mettre à jour les statuts dans la table profiles (si nécessaire)
UPDATE profiles 
SET status = 'active'::status_type 
WHERE status = 'actif'::status_type;

-- 1.3 Vérifier si le type ENUM status_type contient des valeurs françaises
-- Note: Vous devrez peut-être recréer l'ENUM si des valeurs françaises y sont définies
-- Pour l'instant, on documente la recommandation

COMMENT ON TYPE status_type IS 
  'Statuts standards: active, inactive, pending, archived (utiliser uniquement l''anglais)';

-- ============================================================================
-- 2. CRÉATION DES FONCTIONS RLS MANQUANTES
-- ============================================================================

-- 2.1 Fonction: get_user_company_id()
-- Retourne le company_id de l'utilisateur courant
DROP FUNCTION IF EXISTS get_user_company_id() CASCADE;
CREATE FUNCTION get_user_company_id()
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT company_id 
  FROM profiles 
  WHERE user_id = auth.uid()
  LIMIT 1;
$$;

COMMENT ON FUNCTION get_user_company_id() IS 
  'Retourne le company_id de l''utilisateur authentifié';

-- 2.2 Fonction: can_message_user(sender_id, recipient_id)
-- Détermine si un utilisateur peut envoyer un message à un autre
DROP FUNCTION IF EXISTS can_message_user(uuid, uuid) CASCADE;
CREATE FUNCTION can_message_user(
  sender_id uuid,
  recipient_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  sender_role user_role;
  recipient_role user_role;
  sender_company_id bigint;
  recipient_company_id bigint;
BEGIN
  -- Récupérer les rôles et companies
  SELECT role, company_id INTO sender_role, sender_company_id
  FROM profiles WHERE user_id = sender_id;
  
  SELECT role, company_id INTO recipient_role, recipient_company_id
  FROM profiles WHERE user_id = recipient_id;
  
  -- Règles de messagerie:
  -- 1. Admins et associés peuvent envoyer des messages à tout le monde dans leur company
  IF sender_role IN ('admin', 'associe') AND sender_company_id = recipient_company_id THEN
    RETURN true;
  END IF;
  
  -- 2. Partenaires peuvent envoyer des messages aux admins/associés de leur company
  IF sender_role = 'partenaire' 
     AND recipient_role IN ('admin', 'associe')
     AND sender_company_id = recipient_company_id THEN
    RETURN true;
  END IF;
  
  -- 3. Clients peuvent envoyer des messages aux admins/associés de la company
  IF sender_role = 'client' 
     AND recipient_role IN ('admin', 'associe') THEN
    -- Vérifier si le client a un projet dans cette company
    IF EXISTS (
      SELECT 1 FROM projects p
      WHERE p.client_id = sender_id
        AND p.company_id = recipient_company_id
    ) THEN
      RETURN true;
    END IF;
  END IF;
  
  -- 4. Partenaires de la même company peuvent se parler
  IF sender_role = 'partenaire' 
     AND recipient_role = 'partenaire'
     AND sender_company_id = recipient_company_id THEN
    RETURN true;
  END IF;
  
  -- Par défaut, refuser
  RETURN false;
END;
$$;

COMMENT ON FUNCTION can_message_user(uuid, uuid) IS 
  'Détermine si sender_id peut envoyer un message à recipient_id selon les règles métier';

-- 2.3 Fonction: can_participate_in_conversation(user_id, conversation_id)
-- Vérifie si un utilisateur peut participer à une conversation
DROP FUNCTION IF EXISTS can_participate_in_conversation(uuid, uuid) CASCADE;
CREATE FUNCTION can_participate_in_conversation(
  p_user_id uuid,
  p_conversation_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  is_participant boolean;
  user_role user_role;
  user_company_id bigint;
BEGIN
  -- Vérifier si l'utilisateur est déjà participant
  SELECT EXISTS (
    SELECT 1 FROM conversation_participants
    WHERE conversation_id = p_conversation_id
      AND user_id = p_user_id
  ) INTO is_participant;
  
  IF is_participant THEN
    RETURN true;
  END IF;
  
  -- Récupérer le rôle de l'utilisateur
  SELECT role, company_id INTO user_role, user_company_id
  FROM profiles WHERE user_id = p_user_id;
  
  -- Admins et associés peuvent rejoindre les conversations de leur company
  IF user_role IN ('admin', 'associe') THEN
    -- Vérifier si la conversation contient des membres de leur company
    IF EXISTS (
      SELECT 1 
      FROM conversation_participants cp
      JOIN profiles p ON p.user_id = cp.user_id
      WHERE cp.conversation_id = p_conversation_id
        AND p.company_id = user_company_id
    ) THEN
      RETURN true;
    END IF;
  END IF;
  
  -- Par défaut, refuser
  RETURN false;
END;
$$;

COMMENT ON FUNCTION can_participate_in_conversation(uuid, uuid) IS 
  'Vérifie si un utilisateur peut participer à une conversation donnée';

-- 2.4 Fonction: get_user_role()
-- Retourne le rôle de l'utilisateur courant
DROP FUNCTION IF EXISTS get_user_role() CASCADE;
CREATE FUNCTION get_user_role()
RETURNS user_role
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT role 
  FROM profiles 
  WHERE user_id = auth.uid()
  LIMIT 1;
$$;

COMMENT ON FUNCTION get_user_role() IS 
  'Retourne le rôle de l''utilisateur authentifié';

-- 2.5 Fonction: is_admin_or_associate()
-- Vérifie si l'utilisateur courant est admin ou associé
DROP FUNCTION IF EXISTS is_admin_or_associate() CASCADE;
CREATE FUNCTION is_admin_or_associate()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles 
    WHERE user_id = auth.uid() 
      AND role IN ('admin', 'associe')
  );
$$;

COMMENT ON FUNCTION is_admin_or_associate() IS 
  'Retourne true si l''utilisateur est admin ou associé';

-- ============================================================================
-- 3. AJOUT DE COLONNES MANQUANTES (SOFT DELETE)
-- ============================================================================

-- 3.1 Ajouter deleted_at à projects (si pas déjà présent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'projects' 
      AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE projects ADD COLUMN deleted_at timestamptz NULL;
    CREATE INDEX idx_projects_deleted_at ON projects(deleted_at) WHERE deleted_at IS NULL;
    COMMENT ON COLUMN projects.deleted_at IS 'Soft delete timestamp';
  END IF;
END $$;

-- 3.2 Ajouter deleted_at à tasks (si pas déjà présent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'tasks' 
      AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE tasks ADD COLUMN deleted_at timestamptz NULL;
    CREATE INDEX idx_tasks_deleted_at ON tasks(deleted_at) WHERE deleted_at IS NULL;
    COMMENT ON COLUMN tasks.deleted_at IS 'Soft delete timestamp';
  END IF;
END $$;

-- 3.3 Ajouter deleted_at à commercial_actions (si pas déjà présent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'commercial_actions' 
      AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE commercial_actions ADD COLUMN deleted_at timestamptz NULL;
    CREATE INDEX idx_commercial_actions_deleted_at ON commercial_actions(deleted_at) WHERE deleted_at IS NULL;
    COMMENT ON COLUMN commercial_actions.deleted_at IS 'Soft delete timestamp';
  END IF;
END $$;

-- 3.4 Ajouter deleted_at à invoices (si pas déjà présent)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'invoices' 
      AND column_name = 'deleted_at'
  ) THEN
    ALTER TABLE invoices ADD COLUMN deleted_at timestamptz NULL;
    CREATE INDEX idx_invoices_deleted_at ON invoices(deleted_at) WHERE deleted_at IS NULL;
    COMMENT ON COLUMN invoices.deleted_at IS 'Soft delete timestamp';
  END IF;
END $$;

-- ============================================================================
-- 4. AJOUT DE TRIGGERS POUR updated_at
-- ============================================================================

-- 4.1 Fonction trigger générique pour updated_at
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
CREATE FUNCTION update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION update_updated_at_column() IS 
  'Trigger function pour mettre à jour automatiquement updated_at';

-- 4.2 Appliquer le trigger à toutes les tables pertinentes
DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public'
      AND tablename IN (
        'clients', 'projects', 'tasks', 'commercial_actions', 
        'invoices', 'profiles', 'companies', 'timesheet_entries',
        'partner_availability', 'project_proposals', 'conversations'
      )
  LOOP
    -- Vérifier si la colonne updated_at existe
    IF EXISTS (
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = 'public'
        AND table_name = table_record.tablename
        AND column_name = 'updated_at'
    ) THEN
      -- Supprimer le trigger s'il existe déjà
      EXECUTE format('DROP TRIGGER IF EXISTS update_%I_updated_at ON %I', 
        table_record.tablename, table_record.tablename);
      
      -- Créer le trigger
      EXECUTE format(
        'CREATE TRIGGER update_%I_updated_at 
         BEFORE UPDATE ON %I 
         FOR EACH ROW 
         EXECUTE FUNCTION update_updated_at_column()',
        table_record.tablename, table_record.tablename
      );
      
      RAISE NOTICE 'Trigger updated_at créé pour %', table_record.tablename;
    END IF;
  END LOOP;
END $$;

-- ============================================================================
-- 5. NETTOYAGE ET OPTIMISATIONS
-- ============================================================================

-- 5.1 Mettre à jour les politiques RLS pour exclure les enregistrements supprimés (soft delete)
-- Projects
DROP POLICY IF EXISTS "projects_select_policy" ON projects;
CREATE POLICY "projects_select_policy" ON projects
  FOR SELECT
  TO authenticated
  USING (
    deleted_at IS NULL AND (  -- Exclure les supprimés
      (client_id = auth.uid()) OR
      (company_id IN (
        SELECT p.company_id FROM profiles p WHERE p.user_id = auth.uid()
      )) OR
      (EXISTS (
        SELECT 1 FROM profiles p
        WHERE p.user_id = auth.uid() 
        AND p.role = ANY (ARRAY['admin'::user_role, 'associe'::user_role])
      ))
    )
  );

-- Tasks
DROP POLICY IF EXISTS "tasks_company_select_exclude_deleted" ON tasks;
CREATE POLICY "tasks_company_select_exclude_deleted" ON tasks
  FOR SELECT
  TO authenticated
  USING (
    deleted_at IS NULL AND (  -- Exclure les supprimés
      (EXISTS (
        SELECT 1 FROM profiles
        WHERE profiles.user_id = auth.uid() 
        AND profiles.role = ANY (ARRAY['admin'::user_role, 'associe'::user_role])
      )) OR
      (EXISTS (
        SELECT 1 FROM projects p
        WHERE p.id = tasks.project_id 
        AND p.company_id = get_user_company_id()
      )) OR
      (auth.uid() IN (user_id, assigned_to, partner_id))
    )
  );

-- 5.2 Créer des vues pour simplifier les requêtes
CREATE OR REPLACE VIEW active_projects AS
SELECT * FROM projects 
WHERE deleted_at IS NULL 
  AND status = 'active'::status_type;

COMMENT ON VIEW active_projects IS 
  'Vue des projets actifs (non supprimés)';

CREATE OR REPLACE VIEW active_tasks AS
SELECT * FROM tasks 
WHERE deleted_at IS NULL;

COMMENT ON VIEW active_tasks IS 
  'Vue des tâches actives (non supprimées)';

CREATE OR REPLACE VIEW active_clients AS
SELECT * FROM clients 
WHERE deleted_at IS NULL 
  AND status = 'active'::status_type;

COMMENT ON VIEW active_clients IS 
  'Vue des clients actifs (non supprimés)';

-- ============================================================================
-- 6. VALIDATION DES CONTRAINTES CHECK
-- ============================================================================

-- 6.1 Ajouter des contraintes de validation si manquantes

-- Validation email format (clients)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'clients_email_check'
  ) THEN
    ALTER TABLE clients 
    ADD CONSTRAINT clients_email_check 
    CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' OR email IS NULL);
  END IF;
END $$;

-- Validation dates (projects)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'projects_dates_check'
  ) THEN
    ALTER TABLE projects 
    ADD CONSTRAINT projects_dates_check 
    CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date);
  END IF;
END $$;

-- Validation montants (invoices)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'invoices_amounts_check'
  ) THEN
    ALTER TABLE invoices 
    ADD CONSTRAINT invoices_amounts_check 
    CHECK (amount >= 0 AND total_amount >= 0);
  END IF;
END $$;

-- ============================================================================
-- VÉRIFICATIONS POST-MIGRATION
-- ============================================================================

-- Vérifier que toutes les fonctions sont créées
DO $$
DECLARE
    functions_status TEXT;
BEGIN
    SELECT string_agg(proname::text, ', ')
    INTO functions_status
    FROM pg_proc
    WHERE proname IN (
      'get_user_company_id',
      'can_message_user',
      'can_participate_in_conversation',
      'get_user_role',
      'is_admin_or_associate',
      'update_updated_at_column'
    )
    AND pronamespace = 'public'::regnamespace;
    
    RAISE NOTICE 'Fonctions créées: %', functions_status;
END $$;

-- Vérifier les colonnes deleted_at
DO $$
DECLARE
    soft_delete_tables TEXT;
BEGIN
    SELECT string_agg(table_name, ', ')
    INTO soft_delete_tables
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND column_name = 'deleted_at';
    
    RAISE NOTICE 'Tables avec soft delete: %', soft_delete_tables;
END $$;

COMMENT ON SCHEMA public IS 'Migration 3 appliquée: Fonctions RLS, soft delete, standardisation';


