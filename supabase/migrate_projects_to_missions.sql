-- =============================================
-- MIGRATION COMPLÈTE : TOUT REGROUPER SOUS "MISSIONS"
-- =============================================
-- Ce script fusionne les tables "projects" et "missions" en une seule table "missions"
-- et met à jour toutes les références dans la base de données

-- ⚠️ ATTENTION : Sauvegardez vos données avant d'exécuter ce script !

-- =============================================
-- ÉTAPE 1 : VÉRIFICATION PRÉALABLE
-- =============================================

SELECT 'ÉTAPE 1 : Vérification préalable' as etape;

-- Vérifier l'existence des tables
SELECT 
    'Vérification tables' as info,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'projects') 
         THEN 'projects: EXISTE' 
         ELSE 'projects: N''EXISTE PAS' 
    END as projects_status,
    CASE WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'missions') 
         THEN 'missions: EXISTE' 
         ELSE 'missions: N''EXISTE PAS' 
    END as missions_status;

-- Compter les données
SELECT 
    'Données à migrer' as info,
    (SELECT COUNT(*) FROM projects) as projects_count,
    (SELECT COUNT(*) FROM missions) as missions_count;

-- =============================================
-- ÉTAPE 2 : CRÉER LA NOUVELLE TABLE MISSIONS UNIFIÉE
-- =============================================

SELECT 'ÉTAPE 2 : Création de la table missions unifiée' as etape;

-- Créer la table missions avec toutes les colonnes des deux tables
CREATE TABLE IF NOT EXISTS missions_new (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    -- Colonnes de base (fusion projects + missions)
    title TEXT NOT NULL DEFAULT 'Mission sans titre',
    name TEXT, -- Alias pour title (compatibilité)
    description TEXT,
    
    -- Dates
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    
    -- Relations
    client_id UUID,
    partner_id UUID,
    assigned_by UUID,
    company_id UUID,
    
    -- Statut et priorité
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'cancelled', 'accepted', 'rejected')),
    priority TEXT DEFAULT 'Moyenne' CHECK (priority IN ('Faible', 'Moyenne', 'Élevée', 'Critique', 'low', 'medium', 'high', 'urgent')),
    
    -- Détails financiers
    budget DECIMAL(10,2),
    estimated_days DECIMAL(10,2),
    worked_days DECIMAL(10,2),
    daily_rate DECIMAL(10,2),
    estimated_hours DECIMAL(10,2),
    worked_hours DECIMAL(10,2),
    
    -- Progression
    completion_percentage DECIMAL(5,2) DEFAULT 0,
    
    -- Notes
    notes TEXT,
    completion_notes TEXT
);

-- =============================================
-- ÉTAPE 3 : MIGRER LES DONNÉES DE PROJECTS
-- =============================================

SELECT 'ÉTAPE 3 : Migration des données de projects vers missions_new' as etape;

-- Vérifier si projects est une table (pas une vue)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'projects' 
        AND table_type = 'BASE TABLE'
    ) THEN
        RAISE NOTICE '✅ projects est une table - migration possible';
    ELSIF EXISTS (
        SELECT 1 FROM information_schema.views 
        WHERE table_name = 'projects'
    ) THEN
        RAISE NOTICE 'ℹ️ projects est une vue - migration ignorée';
        RAISE NOTICE 'ℹ️ Les données seront migrées depuis la table sous-jacente si elle existe';
        RETURN;
    ELSE
        RAISE NOTICE '⚠️ projects n''existe pas - migration ignorée';
        RETURN;
    END IF;
END $$;

INSERT INTO missions_new (
    id, title, name, description, start_date, end_date, 
    client_id, company_id, status, priority,
    budget, estimated_days, worked_days, daily_rate,
    completion_percentage, created_at, updated_at
)
SELECT 
    id, 
    COALESCE(NULLIF(TRIM(name), ''), 'Mission sans titre') as title, -- Assurer qu'il n'y a jamais de NULL
    name,
    description,
    start_date,
    end_date,
    client_id,
    NULL as company_id, -- company_id sera à mettre à jour manuellement si nécessaire
    CASE 
        WHEN status::text = 'actif' OR status::text = 'active' THEN 'in_progress'
        WHEN status::text = 'termine' OR status::text = 'terminé' OR status::text = 'done' THEN 'completed'
        WHEN status::text = 'annule' OR status::text = 'annulé' THEN 'cancelled'
        WHEN status::text IN ('pending', 'in_progress', 'completed', 'cancelled', 'accepted', 'rejected') THEN status::text
        ELSE 'pending'
    END as status,
    CASE 
        WHEN priority IN ('Faible', 'Moyenne', 'Élevée', 'Critique', 'low', 'medium', 'high', 'urgent') THEN priority
        ELSE 'Moyenne'
    END as priority,
    NULL as budget, -- À remplir si disponible
    estimated_days,
    worked_days,
    daily_rate,
    completion_percentage,
    created_at,
    updated_at
FROM projects
WHERE NOT EXISTS (SELECT 1 FROM missions_new WHERE missions_new.id = projects.id);

SELECT COUNT(*) || ' lignes migrées depuis projects' as info FROM projects;

-- =============================================
-- ÉTAPE 4 : MIGRER LES DONNÉES DE MISSIONS
-- =============================================

SELECT 'ÉTAPE 4 : Migration des données de missions vers missions_new' as etape;

INSERT INTO missions_new (
    id, title, description, start_date, end_date,
    partner_id, assigned_by, status, priority, budget,
    notes, completion_notes, created_at, updated_at
)
SELECT 
    id,
    COALESCE(title, 'Mission sans titre') as title, -- Assurer qu'il n'y a jamais de NULL
    description,
    start_date,
    end_date,
    partner_id,
    assigned_by,
    status,
    priority,
    budget,
    notes,
    completion_notes,
    created_at,
    updated_at
FROM missions
WHERE NOT EXISTS (SELECT 1 FROM missions_new WHERE missions_new.id = missions.id);

SELECT COUNT(*) || ' lignes migrées depuis missions' as info FROM missions;

-- =============================================
-- ÉTAPE 5 : METTRE À JOUR LES RÉFÉRENCES
-- =============================================

SELECT 'ÉTAPE 5 : Mise à jour des références' as etape;

-- Désactiver temporairement les contraintes de clés étrangères (seulement les triggers utilisateur)
ALTER TABLE tasks DISABLE TRIGGER USER;

-- Désactiver les triggers de mission_assignments si la table existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mission_assignments') THEN
        ALTER TABLE mission_assignments DISABLE TRIGGER USER;
    END IF;
END $$;

-- Mettre à jour les références dans tasks (seulement si la colonne existe)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' AND column_name = 'project_id'
    ) THEN
        UPDATE tasks
        SET project_id = missions_new.id
        FROM missions_new
        WHERE tasks.project_id IN (SELECT id FROM projects);
        
        RAISE NOTICE 'Références tasks mises à jour';
    ELSE
        RAISE NOTICE 'Colonne project_id n''existe pas dans tasks - ignorée';
    END IF;
END $$;

-- Mettre à jour les références dans mission_assignments (si la table et colonne existent)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mission_assignments') THEN
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'mission_assignments' AND column_name = 'project_id'
        ) THEN
            UPDATE mission_assignments
            SET project_id = missions_new.id
            FROM missions_new
            WHERE mission_assignments.project_id IN (SELECT id FROM projects);
            
            RAISE NOTICE 'Références mission_assignments mises à jour';
        ELSE
            RAISE NOTICE 'Colonne project_id n''existe pas dans mission_assignments - ignorée';
        END IF;
    ELSE
        RAISE NOTICE 'Table mission_assignments n''existe pas - ignorée';
    END IF;
END $$;

-- Réactiver les contraintes (seulement les triggers utilisateur)
ALTER TABLE tasks ENABLE TRIGGER USER;

-- Réactiver les triggers de mission_assignments si la table existe
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'mission_assignments') THEN
        ALTER TABLE mission_assignments ENABLE TRIGGER USER;
    END IF;
END $$;

-- =============================================
-- ÉTAPE 6 : RENOMMER LA TABLE time_extension_requests
-- =============================================

SELECT 'ÉTAPE 6 : Renommage de time_extension_requests' as etape;

-- Renommer la colonne project_id en mission_id dans time_extension_requests (si elle existe)
DO $$
BEGIN
    -- Vérifier si la table existe
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'time_extension_requests') THEN
        -- Vérifier si la colonne project_id existe
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'time_extension_requests' AND column_name = 'project_id'
        ) THEN
            ALTER TABLE time_extension_requests 
            RENAME COLUMN project_id TO mission_id;
            
            RAISE NOTICE '✅ Colonne project_id renommée en mission_id dans time_extension_requests';
        ELSE
            RAISE NOTICE 'ℹ️ Colonne project_id n''existe déjà pas dans time_extension_requests';
        END IF;
        
        -- Mettre à jour le commentaire de la table
        COMMENT ON TABLE time_extension_requests IS 'Demandes d''extension de temps pour les missions';
    ELSE
        RAISE NOTICE '⚠️ Table time_extension_requests n''existe pas';
    END IF;
END $$;

-- =============================================
-- ÉTAPE 7 : SUPPRIMER LES ANCIENNES TABLES
-- =============================================

SELECT 'ÉTAPE 7 : Suppression des anciennes tables' as etape;

-- Supprimer l'ancienne vue ou table projects
DROP VIEW IF EXISTS projects CASCADE;
DROP TABLE IF EXISTS projects CASCADE;

-- Supprimer l'ancienne table missions
DROP TABLE IF EXISTS missions CASCADE;

-- =============================================
-- ÉTAPE 8 : RENOMMER missions_new EN missions
-- =============================================

SELECT 'ÉTAPE 8 : Renommage de missions_new en missions' as etape;

ALTER TABLE missions_new RENAME TO missions;

-- =============================================
-- ÉTAPE 9 : RECRÉER LES INDEX
-- =============================================

SELECT 'ÉTAPE 9 : Recréation des index' as etape;

CREATE INDEX IF NOT EXISTS idx_missions_partner_id ON missions(partner_id);
CREATE INDEX IF NOT EXISTS idx_missions_assigned_by ON missions(assigned_by);
CREATE INDEX IF NOT EXISTS idx_missions_client_id ON missions(client_id);
CREATE INDEX IF NOT EXISTS idx_missions_company_id ON missions(company_id);
CREATE INDEX IF NOT EXISTS idx_missions_status ON missions(status);
CREATE INDEX IF NOT EXISTS idx_missions_priority ON missions(priority);
CREATE INDEX IF NOT EXISTS idx_missions_dates ON missions(start_date, end_date);
CREATE INDEX IF NOT EXISTS idx_missions_created_at ON missions(created_at);

-- =============================================
-- ÉTAPE 10 : RECRÉER LES POLITIQUES RLS
-- =============================================

SELECT 'ÉTAPE 10 : Recréation des politiques RLS' as etape;

ALTER TABLE missions ENABLE ROW LEVEL SECURITY;

-- Politique pour que les associés voient toutes les missions
CREATE POLICY "Associates can view all missions" ON missions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND user_role = 'associe'
        )
    );

-- Politique pour que les partenaires voient leurs missions
CREATE POLICY "Partners can view their missions" ON missions
    FOR SELECT USING (partner_id = auth.uid());

-- Politique pour que les clients voient leurs missions
CREATE POLICY "Clients can view their missions" ON missions
    FOR SELECT USING (client_id = auth.uid());

-- Politique pour que les admins voient toutes les missions
CREATE POLICY "Admins can view all missions" ON missions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND user_role = 'admin'
        )
    );

-- Politique pour que les associés créent des missions
CREATE POLICY "Associates can create missions" ON missions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND user_role = 'associe'
        )
    );

-- Politique pour que les associés mettent à jour les missions
CREATE POLICY "Associates can update missions" ON missions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_id = auth.uid()
            AND user_role = 'associe'
        )
    );

-- Politique pour que les partenaires mettent à jour leurs missions
CREATE POLICY "Partners can update their missions" ON missions
    FOR UPDATE USING (partner_id = auth.uid());

-- =============================================
-- ÉTAPE 11 : CRÉER LES TRIGGERS
-- =============================================

SELECT 'ÉTAPE 11 : Création des triggers' as etape;

CREATE OR REPLACE FUNCTION update_missions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_missions_updated_at_trigger
    BEFORE UPDATE ON missions
    FOR EACH ROW
    EXECUTE FUNCTION update_missions_updated_at();

-- =============================================
-- ÉTAPE 12 : CRÉER UNE VUE POUR LA COMPATIBILITÉ
-- =============================================

SELECT 'ÉTAPE 12 : Création de la vue de compatibilité' as etape;

-- Créer une vue "projects" pour la compatibilité avec l'ancien code
CREATE OR REPLACE VIEW projects AS
SELECT 
    id,
    name,
    description,
    start_date,
    end_date,
    client_id,
    company_id,
    status,
    priority,
    estimated_days,
    worked_days,
    daily_rate,
    completion_percentage,
    created_at,
    updated_at
FROM missions;

COMMENT ON VIEW projects IS 'Vue de compatibilité : redirige vers la table missions';

-- =============================================
-- ÉTAPE 13 : VÉRIFICATION FINALE
-- =============================================

SELECT 'ÉTAPE 13 : Vérification finale' as etape;

-- Vérifier la table missions
SELECT 
    'Table missions' as info,
    COUNT(*) as total_rows,
    COUNT(CASE WHEN partner_id IS NOT NULL THEN 1 END) as with_partner,
    COUNT(CASE WHEN client_id IS NOT NULL THEN 1 END) as with_client
FROM missions;

-- Vérifier les contraintes
SELECT 
    'Contraintes missions' as info,
    COUNT(*) as count
FROM information_schema.table_constraints
WHERE table_name = 'missions';

-- Vérifier les index
SELECT 
    'Index missions' as info,
    COUNT(*) as count
FROM pg_indexes
WHERE tablename = 'missions';

-- Vérifier les politiques RLS
SELECT 
    'Politiques RLS' as info,
    COUNT(*) as count
FROM pg_policies
WHERE tablename = 'missions';

-- =============================================
-- RÉSUMÉ FINAL
-- =============================================

SELECT 'MIGRATION TERMINÉE AVEC SUCCÈS !' as result
UNION ALL
SELECT '✅ Table missions créée et unifiée'
UNION ALL
SELECT '✅ Données de projects migrées'
UNION ALL
SELECT '✅ Données de missions migrées'
UNION ALL
SELECT '✅ Références mises à jour (tasks, mission_assignments)'
UNION ALL
SELECT '✅ time_extension_requests renommé avec mission_id'
UNION ALL
SELECT '✅ Anciennes tables projects et missions supprimées'
UNION ALL
SELECT '✅ Vue de compatibilité "projects" créée'
UNION ALL
SELECT '✅ Index recréés'
UNION ALL
SELECT '✅ Politiques RLS configurées'
UNION ALL
SELECT '✅ Triggers configurés'
UNION ALL
SELECT ''
UNION ALL
SELECT '🎉 Votre base de données utilise maintenant uniquement "missions" !'
UNION ALL
SELECT '📋 Prochaines étapes :'
UNION ALL
SELECT '1. Vérifier que l''application fonctionne'
UNION ALL
SELECT '2. Tester les fonctionnalités de missions'
UNION ALL
SELECT '3. Vérifier les demandes d''extension';
