-- Script pour créer le système de missions et notifications

-- 1. Table des missions
CREATE TABLE IF NOT EXISTS missions (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    partner_id UUID NOT NULL,
    assigned_by UUID NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    budget DECIMAL(10,2),
    priority TEXT DEFAULT 'Moyenne' CHECK (priority IN ('Faible', 'Moyenne', 'Élevée', 'Critique')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected', 'in_progress', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    notes TEXT,
    completion_notes TEXT
);

-- 2. Table des notifications
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID NOT NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'general' CHECK (type IN ('mission_assignment', 'mission_update', 'availability_request', 'general')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    read_at TIMESTAMP WITH TIME ZONE,
    data JSONB -- Données supplémentaires (ex: ID de mission)
);

-- 3. Table des disponibilités des partenaires
CREATE TABLE IF NOT EXISTS partner_availability (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    partner_id UUID NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    is_available BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 4. Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_missions_partner_id ON missions(partner_id);
CREATE INDEX IF NOT EXISTS idx_missions_assigned_by ON missions(assigned_by);
CREATE INDEX IF NOT EXISTS idx_missions_status ON missions(status);
CREATE INDEX IF NOT EXISTS idx_missions_dates ON missions(start_date, end_date);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

CREATE INDEX IF NOT EXISTS idx_availability_partner_id ON partner_availability(partner_id);
CREATE INDEX IF NOT EXISTS idx_availability_times ON partner_availability(start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_availability_is_available ON partner_availability(is_available);

-- 5. Politiques RLS pour les missions
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;

-- Les partenaires peuvent voir leurs missions
CREATE POLICY "Partners can view their missions" ON missions
    FOR SELECT USING (partner_id = auth.uid());

-- Les partenaires peuvent mettre à jour leurs missions
CREATE POLICY "Partners can update their missions" ON missions
    FOR UPDATE USING (partner_id = auth.uid());

-- Les associés peuvent voir toutes les missions
CREATE POLICY "Associates can view all missions" ON missions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'associe'
        )
    );

-- Les associés peuvent créer des missions
CREATE POLICY "Associates can create missions" ON missions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'associe'
        )
    );

-- Les associés peuvent mettre à jour les missions
CREATE POLICY "Associates can update missions" ON missions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'associe'
        )
    );

-- 6. Politiques RLS pour les notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Les utilisateurs peuvent voir leurs notifications
CREATE POLICY "Users can view their notifications" ON notifications
    FOR SELECT USING (user_id = auth.uid());

-- Les utilisateurs peuvent marquer leurs notifications comme lues
CREATE POLICY "Users can update their notifications" ON notifications
    FOR UPDATE USING (user_id = auth.uid());

-- Les associés peuvent créer des notifications
CREATE POLICY "Associates can create notifications" ON notifications
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'associe'
        )
    );

-- 7. Politiques RLS pour les disponibilités
ALTER TABLE partner_availability ENABLE ROW LEVEL SECURITY;

-- Les partenaires peuvent gérer leurs disponibilités
CREATE POLICY "Partners can manage their availability" ON partner_availability
    FOR ALL USING (partner_id = auth.uid());

-- Les associés peuvent voir les disponibilités des partenaires
CREATE POLICY "Associates can view partner availability" ON partner_availability
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'associe'
        )
    );

-- 8. Fonctions utilitaires
CREATE OR REPLACE FUNCTION update_mission_status()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_availability_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 9. Triggers
CREATE TRIGGER update_missions_updated_at
    BEFORE UPDATE ON missions
    FOR EACH ROW
    EXECUTE FUNCTION update_mission_status();

CREATE TRIGGER update_availability_updated_at
    BEFORE UPDATE ON partner_availability
    FOR EACH ROW
    EXECUTE FUNCTION update_availability_updated_at();

-- 10. Vérification finale
SELECT 
    'Tables créées' as info,
    COUNT(*) as count
FROM information_schema.tables 
WHERE table_name IN ('missions', 'notifications', 'partner_availability')
AND table_schema = 'public';

SELECT 
    'Politiques RLS créées' as info,
    COUNT(*) as count
FROM pg_policies 
WHERE tablename IN ('missions', 'notifications', 'partner_availability');
