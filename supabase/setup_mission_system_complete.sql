-- =============================================
-- SCRIPT COMPLET POUR LE SYSTÈME DE MISSIONS
-- =============================================
-- Ce script crée toutes les tables nécessaires et le système de missions

-- 1. Créer la table user_roles si elle n'existe pas
CREATE TABLE IF NOT EXISTS user_roles (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_role TEXT NOT NULL CHECK (user_role IN ('admin', 'associe', 'partenaire', 'client')),
    company_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- 2. Créer la table projects si elle n'existe pas
CREATE TABLE IF NOT EXISTS projects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    client_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Créer la table tasks si elle n'existe pas
CREATE TABLE IF NOT EXISTS tasks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Table des missions assignées
CREATE TABLE IF NOT EXISTS mission_assignments (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    assigned_to UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'in_progress', 'completed', 'cancelled')),
    priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    message TEXT, -- Message personnalisé de l'associé
    partner_response TEXT, -- Réponse du partenaire (optionnel)
    deadline DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    accepted_at TIMESTAMP WITH TIME ZONE,
    rejected_at TIMESTAMP WITH TIME ZONE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 5. Table des notifications de missions
CREATE TABLE IF NOT EXISTS mission_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL DEFAULT 'mission_available' CHECK (notification_type IN ('mission_available', 'mission_assigned', 'mission_reminder')),
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    sent_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    sent_to_all_partners BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE
);

-- 6. Table des notifications reçues par les utilisateurs
CREATE TABLE IF NOT EXISTS user_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    notification_id UUID REFERENCES mission_notifications(id) ON DELETE CASCADE,
    mission_assignment_id UUID REFERENCES mission_assignments(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('mission_assignment', 'mission_notification', 'mission_reminder', 'mission_update')),
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- =============================================
-- INDEX POUR PERFORMANCE
-- =============================================

CREATE INDEX IF NOT EXISTS idx_mission_assignments_assigned_to ON mission_assignments(assigned_to);
CREATE INDEX IF NOT EXISTS idx_mission_assignments_status ON mission_assignments(status);
CREATE INDEX IF NOT EXISTS idx_mission_assignments_project_id ON mission_assignments(project_id);
CREATE INDEX IF NOT EXISTS idx_mission_assignments_created_at ON mission_assignments(created_at);

CREATE INDEX IF NOT EXISTS idx_user_notifications_user_id ON user_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_user_notifications_is_read ON user_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_user_notifications_type ON user_notifications(type);

-- =============================================
-- FONCTIONS UTILITAIRES
-- =============================================

-- Fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION update_mission_assignment_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour mission_assignments
DROP TRIGGER IF EXISTS trigger_update_mission_assignment_updated_at ON mission_assignments;
CREATE TRIGGER trigger_update_mission_assignment_updated_at
    BEFORE UPDATE ON mission_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_mission_assignment_updated_at();

-- Fonction pour créer une notification utilisateur
CREATE OR REPLACE FUNCTION create_user_notification(
    p_user_id UUID,
    p_title TEXT,
    p_message TEXT,
    p_type TEXT,
    p_mission_assignment_id UUID DEFAULT NULL,
    p_notification_id UUID DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    notification_uuid UUID;
BEGIN
    INSERT INTO user_notifications (
        user_id, 
        title, 
        message, 
        type, 
        mission_assignment_id,
        notification_id
    ) VALUES (
        p_user_id, 
        p_title, 
        p_message, 
        p_type, 
        p_mission_assignment_id,
        p_notification_id
    ) RETURNING id INTO notification_uuid;
    
    RETURN notification_uuid;
END;
$$ LANGUAGE plpgsql;

-- Fonction pour notifier tous les partenaires d'une nouvelle mission disponible
CREATE OR REPLACE FUNCTION notify_all_partners_mission_available(
    p_project_id UUID,
    p_title TEXT,
    p_message TEXT,
    p_sent_by UUID
)
RETURNS UUID AS $$
DECLARE
    notification_uuid UUID;
    partner_record RECORD;
BEGIN
    -- Créer la notification générale
    INSERT INTO mission_notifications (
        project_id,
        notification_type,
        title,
        message,
        sent_by,
        sent_to_all_partners
    ) VALUES (
        p_project_id,
        'mission_available',
        p_title,
        p_message,
        p_sent_by,
        true
    ) RETURNING id INTO notification_uuid;
    
    -- Notifier chaque partenaire individuellement
    FOR partner_record IN 
        SELECT DISTINCT user_id 
        FROM user_roles 
        WHERE user_role = 'partenaire'
    LOOP
        PERFORM create_user_notification(
            partner_record.user_id,
            p_title,
            p_message,
            'mission_notification',
            NULL,
            notification_uuid
        );
    END LOOP;
    
    RETURN notification_uuid;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- RLS (ROW LEVEL SECURITY)
-- =============================================

-- Activer RLS sur toutes les tables
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE mission_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE mission_notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_notifications ENABLE ROW LEVEL SECURITY;

-- Politiques pour user_roles
DROP POLICY IF EXISTS "Users can view their own role" ON user_roles;
CREATE POLICY "Users can view their own role" ON user_roles
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can view all roles if admin or associate" ON user_roles;
CREATE POLICY "Users can view all roles if admin or associate" ON user_roles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role IN ('admin', 'associe')
        )
    );

-- Politiques pour projects
DROP POLICY IF EXISTS "Users can view all projects" ON projects;
CREATE POLICY "Users can view all projects" ON projects FOR SELECT USING (true);

-- Politiques pour tasks
DROP POLICY IF EXISTS "Users can view all tasks" ON tasks;
CREATE POLICY "Users can view all tasks" ON tasks FOR SELECT USING (true);

-- Politiques pour mission_assignments
DROP POLICY IF EXISTS "Users can view their own mission assignments" ON mission_assignments;
CREATE POLICY "Users can view their own mission assignments" ON mission_assignments
    FOR SELECT USING (
        assigned_to = auth.uid() OR 
        assigned_by = auth.uid() OR
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role IN ('admin', 'associe')
        )
    );

DROP POLICY IF EXISTS "Associates and admins can create mission assignments" ON mission_assignments;
CREATE POLICY "Associates and admins can create mission assignments" ON mission_assignments
    FOR INSERT WITH CHECK (
        assigned_by = auth.uid() AND
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role IN ('admin', 'associe')
        )
    );

DROP POLICY IF EXISTS "Partners can update their own mission assignments" ON mission_assignments;
CREATE POLICY "Partners can update their own mission assignments" ON mission_assignments
    FOR UPDATE USING (
        assigned_to = auth.uid() AND
        status IN ('pending', 'accepted', 'in_progress')
    );

DROP POLICY IF EXISTS "Associates and admins can update all mission assignments" ON mission_assignments;
CREATE POLICY "Associates and admins can update all mission assignments" ON mission_assignments
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role IN ('admin', 'associe')
        )
    );

-- Politiques pour mission_notifications
DROP POLICY IF EXISTS "Users can view mission notifications" ON mission_notifications;
CREATE POLICY "Users can view mission notifications" ON mission_notifications
    FOR SELECT USING (
        sent_by = auth.uid() OR
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role IN ('admin', 'associe', 'partenaire')
        )
    );

DROP POLICY IF EXISTS "Associates and admins can create mission notifications" ON mission_notifications;
CREATE POLICY "Associates and admins can create mission notifications" ON mission_notifications
    FOR INSERT WITH CHECK (
        sent_by = auth.uid() AND
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role IN ('admin', 'associe')
        )
    );

-- Politiques pour user_notifications
DROP POLICY IF EXISTS "Users can view their own notifications" ON user_notifications;
CREATE POLICY "Users can view their own notifications" ON user_notifications
    FOR SELECT USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can update their own notifications" ON user_notifications;
CREATE POLICY "Users can update their own notifications" ON user_notifications
    FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "System can create notifications for users" ON user_notifications;
CREATE POLICY "System can create notifications for users" ON user_notifications
    FOR INSERT WITH CHECK (true);

-- =============================================
-- VUES UTILES
-- =============================================

-- Vue des missions assignées avec détails
CREATE OR REPLACE VIEW mission_assignments_with_details AS
SELECT 
    ma.*,
    p.name as project_name,
    t.title as task_title,
    t.description as task_description,
    assigned_to_user.email as assigned_to_email,
    assigned_to_user.raw_user_meta_data->>'first_name' as assigned_to_first_name,
    assigned_to_user.raw_user_meta_data->>'last_name' as assigned_to_last_name,
    assigned_by_user.email as assigned_by_email,
    assigned_by_user.raw_user_meta_data->>'first_name' as assigned_by_first_name,
    assigned_by_user.raw_user_meta_data->>'last_name' as assigned_by_last_name
FROM mission_assignments ma
LEFT JOIN projects p ON ma.project_id = p.id
LEFT JOIN tasks t ON ma.task_id = t.id
LEFT JOIN auth.users assigned_to_user ON ma.assigned_to = assigned_to_user.id
LEFT JOIN auth.users assigned_by_user ON ma.assigned_by = assigned_by_user.id;

-- Vue des notifications non lues par utilisateur
CREATE OR REPLACE VIEW unread_notifications_count AS
SELECT 
    user_id,
    COUNT(*) as unread_count
FROM user_notifications 
WHERE is_read = false
GROUP BY user_id;

-- =============================================
-- DONNÉES DE TEST (OPTIONNEL)
-- =============================================

-- Insérer quelques données de test si nécessaire
-- (À décommenter pour les tests)

/*
-- Exemple de notification pour tous les partenaires
SELECT notify_all_partners_mission_available(
    (SELECT id FROM projects LIMIT 1),
    'Nouvelle mission disponible',
    'Une nouvelle mission importante est disponible. Veuillez mettre à jour vos disponibilités.',
    (SELECT id FROM auth.users WHERE email LIKE '%associe%' LIMIT 1)
);
*/

-- =============================================
-- MESSAGE DE CONFIRMATION
-- =============================================

DO $$
BEGIN
    RAISE NOTICE '✅ Système de missions créé avec succès !';
    RAISE NOTICE '📋 Tables créées: user_roles, projects, tasks, mission_assignments, mission_notifications, user_notifications';
    RAISE NOTICE '🔧 Fonctions créées: create_user_notification, notify_all_partners_mission_available';
    RAISE NOTICE '👁️ Vues créées: mission_assignments_with_details, unread_notifications_count';
    RAISE NOTICE '🔒 RLS activé sur toutes les tables avec politiques de sécurité';
    RAISE NOTICE '🚀 Le système est prêt à être utilisé !';
END $$;


