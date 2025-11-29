-- ============================================================================
-- 🏗️ REFONTE DU SYSTÈME CLIENTS - ARCHITECTURE HIÉRARCHIQUE
-- ============================================================================
-- Date: 4 novembre 2025
-- Objectif: Introduire la hiérarchie Groupe → Société → Mission → Saisie
-- ============================================================================

-- ============================================================================
-- 1️⃣ TABLE: investor_group (Groupe d'investissement)
-- ============================================================================
-- Représente l'entité contractuelle principale (fonds, holding, groupe financier)

CREATE TABLE IF NOT EXISTS investor_group (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE,
    sector VARCHAR(100),
    country VARCHAR(100) DEFAULT 'France',
    contact_main VARCHAR(255),
    phone VARCHAR(50),
    website VARCHAR(255),
    notes TEXT,
    logo_url VARCHAR(500),
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour recherche rapide
CREATE INDEX IF NOT EXISTS idx_investor_group_name ON investor_group(name);
CREATE INDEX IF NOT EXISTS idx_investor_group_active ON investor_group(active);

COMMENT ON TABLE investor_group IS 'Groupes d''investissement (fonds, holdings) - Entité contractuelle principale';

-- ============================================================================
-- 2️⃣ TABLE: company (Société d'exploitation)
-- ============================================================================
-- Représente une filiale, PME, startup appartenant à un groupe

CREATE TABLE IF NOT EXISTS company (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    group_id BIGINT REFERENCES investor_group(id) ON DELETE CASCADE,
    city VARCHAR(100),
    postal_code VARCHAR(20),
    sector VARCHAR(100),
    ownership_share DECIMAL(5, 2) CHECK (ownership_share >= 0 AND ownership_share <= 100),
    siret VARCHAR(14),
    contact_name VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    active BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(name, group_id)
);

-- Index pour recherche et jointures
CREATE INDEX IF NOT EXISTS idx_company_group_id ON company(group_id);
CREATE INDEX IF NOT EXISTS idx_company_name ON company(name);
CREATE INDEX IF NOT EXISTS idx_company_active ON company(active);

COMMENT ON TABLE company IS 'Sociétés d''exploitation liées à un groupe d''investissement';
COMMENT ON COLUMN company.ownership_share IS 'Part de détention du groupe (en %)';

-- ============================================================================
-- 3️⃣ MISE À JOUR TABLE: missions
-- ============================================================================
-- Ajouter la colonne company_id pour lier les missions aux sociétés

-- Vérifier et créer/modifier la colonne company_id
DO $$ 
DECLARE
    col_type TEXT;
BEGIN
    -- Vérifier si la colonne existe et son type
    SELECT data_type INTO col_type
    FROM information_schema.columns 
    WHERE table_name = 'missions' AND column_name = 'company_id';
    
    IF col_type IS NULL THEN
        -- Colonne n'existe pas, la créer en BIGINT
        ALTER TABLE missions ADD COLUMN company_id BIGINT REFERENCES company(id) ON DELETE CASCADE;
        CREATE INDEX IF NOT EXISTS idx_missions_company_id ON missions(company_id);
    ELSIF col_type = 'uuid' THEN
        -- Colonne existe mais en UUID, la renommer et créer une nouvelle
        ALTER TABLE missions RENAME COLUMN company_id TO company_id_old;
        ALTER TABLE missions ADD COLUMN company_id BIGINT REFERENCES company(id) ON DELETE CASCADE;
        CREATE INDEX IF NOT EXISTS idx_missions_company_id ON missions(company_id);
        RAISE NOTICE 'Colonne company_id convertie de UUID vers BIGINT (ancienne colonne renommée en company_id_old)';
    ELSIF col_type != 'bigint' THEN
        -- Colonne existe mais mauvais type, convertir
        ALTER TABLE missions ALTER COLUMN company_id TYPE BIGINT USING company_id::text::bigint;
        ALTER TABLE missions ADD CONSTRAINT fk_missions_company FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE CASCADE;
        CREATE INDEX IF NOT EXISTS idx_missions_company_id ON missions(company_id);
        RAISE NOTICE 'Colonne company_id convertie en BIGINT';
    ELSE
        -- Colonne existe déjà en BIGINT, vérifier la contrainte
        IF NOT EXISTS (
            SELECT 1 FROM information_schema.table_constraints 
            WHERE constraint_name = 'fk_missions_company'
            AND table_name = 'missions'
        ) THEN
            ALTER TABLE missions ADD CONSTRAINT fk_missions_company FOREIGN KEY (company_id) REFERENCES company(id) ON DELETE CASCADE;
        END IF;
        CREATE INDEX IF NOT EXISTS idx_missions_company_id ON missions(company_id);
    END IF;
END $$;

-- Garder l'ancienne colonne client_id temporairement pour migration
-- (sera supprimée plus tard après migration des données)

COMMENT ON COLUMN missions.company_id IS 'Société sur laquelle la mission est exécutée';

-- ============================================================================
-- 4️⃣ MISE À JOUR TABLE: timesheet_entries
-- ============================================================================
-- Remplacer client_id par mission_id pour lier directement aux missions

-- Ajouter mission_id si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'timesheet_entries' AND column_name = 'mission_id'
    ) THEN
        ALTER TABLE timesheet_entries ADD COLUMN mission_id UUID REFERENCES missions(id) ON DELETE CASCADE;
        CREATE INDEX idx_timesheet_entries_mission_id ON timesheet_entries(mission_id);
    END IF;
END $$;

COMMENT ON COLUMN timesheet_entries.mission_id IS 'Mission sur laquelle le temps est saisi';

-- ============================================================================
-- 5️⃣ VUE: company_with_group (Société avec détails du groupe)
-- ============================================================================
-- Facilite les requêtes avec informations du groupe

-- Supprimer la vue si elle existe pour éviter les erreurs de dépendances
DROP VIEW IF EXISTS company_with_group CASCADE;
DROP VIEW IF EXISTS mission_with_context CASCADE;
DROP VIEW IF EXISTS timesheet_entry_with_context CASCADE;

CREATE OR REPLACE VIEW company_with_group AS
SELECT 
    c.id AS company_id,
    c.name AS company_name,
    c.city,
    c.sector AS company_sector,
    c.ownership_share,
    c.active AS company_active,
    ig.id AS group_id,
    ig.name AS group_name,
    ig.sector AS group_sector,
    ig.country,
    ig.contact_main AS group_contact,
    ig.active AS group_active,
    c.created_at,
    c.updated_at
FROM company c
LEFT JOIN investor_group ig ON c.group_id = ig.id;

COMMENT ON VIEW company_with_group IS 'Vue consolidée: Société + Groupe d''investissement';

-- ============================================================================
-- 6️⃣ VUE: mission_with_context (Mission avec contexte complet)
-- ============================================================================
-- Mission avec société, groupe et partenaire

CREATE OR REPLACE VIEW mission_with_context AS
SELECT 
    m.id AS mission_id,
    m.title AS mission_title,
    m.start_date,
    m.end_date,
    m.status,
    m.budget,
    m.daily_rate,
    c.id AS company_id,
    c.name AS company_name,
    c.city,
    ig.id AS group_id,
    ig.name AS group_name,
    ig.sector AS group_sector,
    p.user_id AS partner_id,
    p.email AS partner_email,
    p.first_name AS partner_first_name,
    p.last_name AS partner_last_name,
    m.created_at,
    m.updated_at
FROM missions m
LEFT JOIN company c ON m.company_id = c.id
LEFT JOIN investor_group ig ON c.group_id = ig.id
LEFT JOIN profiles p ON m.partner_id = p.user_id;

COMMENT ON VIEW mission_with_context IS 'Vue consolidée: Mission + Société + Groupe + Partenaire';

-- ============================================================================
-- 7️⃣ VUE: timesheet_entry_with_context (Saisie avec contexte complet)
-- ============================================================================
-- Saisie de temps avec mission, société et groupe

CREATE OR REPLACE VIEW timesheet_entry_with_context AS
SELECT 
    te.id AS entry_id,
    te.entry_date,
    te.days,
    te.comment,
    te.status,
    te.daily_rate AS entry_rate,
    (te.days * te.daily_rate) AS amount,
    m.id AS mission_id,
    m.title AS mission_title,
    c.id AS company_id,
    c.name AS company_name,
    c.city,
    ig.id AS group_id,
    ig.name AS group_name,
    ig.sector AS group_sector,
    p.user_id AS partner_id,
    p.email AS partner_email,
    p.first_name AS partner_first_name,
    p.last_name AS partner_last_name,
    te.created_at,
    te.updated_at
FROM timesheet_entries te
LEFT JOIN missions m ON te.mission_id = m.id
LEFT JOIN company c ON m.company_id = c.id
LEFT JOIN investor_group ig ON c.group_id = ig.id
LEFT JOIN profiles p ON te.partner_id = p.user_id;

COMMENT ON VIEW timesheet_entry_with_context IS 'Vue consolidée: Saisie + Mission + Société + Groupe + Partenaire';

-- ============================================================================
-- 8️⃣ FONCTION: get_missions_by_partner (Missions d'un partenaire)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_missions_by_partner(
    p_partner_id UUID
)
RETURNS TABLE (
    mission_id UUID,
    mission_title VARCHAR,
    company_id BIGINT,
    company_name VARCHAR,
    group_id BIGINT,
    group_name VARCHAR,
    start_date DATE,
    end_date DATE,
    status VARCHAR,
    daily_rate DECIMAL
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.title,
        c.id,
        c.name,
        ig.id,
        ig.name,
        m.start_date,
        m.end_date,
        m.status,
        m.daily_rate
    FROM missions m
    LEFT JOIN company c ON m.company_id = c.id
    LEFT JOIN investor_group ig ON c.group_id = ig.id
    WHERE m.partner_id = p_partner_id
    AND m.status NOT IN ('cancelled', 'archived')
    ORDER BY m.start_date DESC;
END;
$$;

COMMENT ON FUNCTION get_missions_by_partner IS 'Récupère toutes les missions actives d''un partenaire avec contexte';

-- ============================================================================
-- 9️⃣ FONCTION: get_available_missions_for_timesheet
-- ============================================================================
-- Liste des missions disponibles pour la saisie du temps

CREATE OR REPLACE FUNCTION get_available_missions_for_timesheet(
    p_partner_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    mission_id UUID,
    mission_title VARCHAR,
    company_name VARCHAR,
    group_name VARCHAR,
    daily_rate DECIMAL
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        m.id,
        m.title,
        c.name,
        ig.name,
        m.daily_rate
    FROM missions m
    LEFT JOIN company c ON m.company_id = c.id
    LEFT JOIN investor_group ig ON c.group_id = ig.id
    WHERE m.partner_id = p_partner_id
    AND m.status = 'in_progress'
    AND m.start_date <= p_date
    AND (m.end_date IS NULL OR m.end_date >= p_date)
    ORDER BY m.start_date DESC;
END;
$$;

COMMENT ON FUNCTION get_available_missions_for_timesheet IS 'Missions disponibles pour saisie du temps à une date donnée';

-- ============================================================================
-- 🔟 FONCTION: get_timesheet_report_by_group
-- ============================================================================
-- Rapport consolidé par groupe d'investissement

CREATE OR REPLACE FUNCTION get_timesheet_report_by_group(
    p_year INT,
    p_month INT,
    p_company_id INT DEFAULT NULL
)
RETURNS TABLE (
    group_id BIGINT,
    group_name VARCHAR,
    total_days DECIMAL,
    total_amount DECIMAL,
    company_count BIGINT,
    mission_count BIGINT
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ig.id,
        ig.name,
        COALESCE(SUM(te.days), 0) AS total_days,
        COALESCE(SUM(te.days * te.daily_rate), 0) AS total_amount,
        COUNT(DISTINCT c.id) AS company_count,
        COUNT(DISTINCT m.id) AS mission_count
    FROM investor_group ig
    LEFT JOIN company c ON c.group_id = ig.id
    LEFT JOIN missions m ON m.company_id = c.id
    LEFT JOIN timesheet_entries te ON te.mission_id = m.id
        AND EXTRACT(YEAR FROM te.entry_date) = p_year
        AND EXTRACT(MONTH FROM te.entry_date) = p_month
    WHERE (p_company_id IS NULL OR c.company_id = p_company_id)
    GROUP BY ig.id, ig.name
    HAVING COALESCE(SUM(te.days), 0) > 0
    ORDER BY total_amount DESC;
END;
$$;

COMMENT ON FUNCTION get_timesheet_report_by_group IS 'Rapport timesheet consolidé par groupe d''investissement';

-- ============================================================================
-- 1️⃣1️⃣ RLS (Row Level Security)
-- ============================================================================

-- Activer RLS
ALTER TABLE investor_group ENABLE ROW LEVEL SECURITY;
ALTER TABLE company ENABLE ROW LEVEL SECURITY;

-- Politique pour investor_group: lecture publique pour utilisateurs authentifiés
CREATE POLICY "Lecture publique des groupes" ON investor_group
    FOR SELECT
    TO authenticated
    USING (true);

-- Politique pour investor_group: écriture admin/associé uniquement
CREATE POLICY "Écriture groupes admin/associé" ON investor_group
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'associe')
        )
    );

-- Politique pour company: lecture publique pour utilisateurs authentifiés
CREATE POLICY "Lecture publique des sociétés" ON company
    FOR SELECT
    TO authenticated
    USING (true);

-- Politique pour company: écriture admin/associé uniquement
CREATE POLICY "Écriture sociétés admin/associé" ON company
    FOR ALL
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE user_id = auth.uid()
            AND role IN ('admin', 'associe')
        )
    );

-- ============================================================================
-- 1️⃣2️⃣ DONNÉES DE TEST
-- ============================================================================

-- Insérer des groupes d'investissement
INSERT INTO investor_group (name, sector, country, contact_main, notes) VALUES
    ('Bpifrance Investissement', 'Fonds public', 'France', 'contact@bpifrance.fr', 'Investit dans des start-up industrielles'),
    ('Raise Impact', 'Fonds privé impact', 'France', 'contact@raise.co', 'Spécialisé dans l''impact environnemental'),
    ('Sofinnova Partners', 'Venture Capital', 'France', 'contact@sofinnova.com', 'Biotech et MedTech')
ON CONFLICT (name) DO NOTHING;

-- Insérer des sociétés d'exploitation
INSERT INTO company (name, group_id, city, sector, ownership_share, active) VALUES
    ('Ecometrix', (SELECT id FROM investor_group WHERE name = 'Bpifrance Investissement'), 'Lyon', 'Analyse énergétique', 72.5, true),
    ('Enerbiotech', (SELECT id FROM investor_group WHERE name = 'Bpifrance Investissement'), 'Paris', 'R&D énergétique', 45.0, true),
    ('GreenTech Solutions', (SELECT id FROM investor_group WHERE name = 'Raise Impact'), 'Nantes', 'Recyclage', 80.0, true),
    ('BioHealth Labs', (SELECT id FROM investor_group WHERE name = 'Sofinnova Partners'), 'Marseille', 'Biotechnologie', 65.0, true)
ON CONFLICT (name, group_id) DO NOTHING;

-- ============================================================================
-- 1️⃣3️⃣ TRIGGERS pour updated_at
-- ============================================================================

-- Fonction trigger pour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour investor_group
DROP TRIGGER IF EXISTS update_investor_group_updated_at ON investor_group;
CREATE TRIGGER update_investor_group_updated_at
    BEFORE UPDATE ON investor_group
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour company
DROP TRIGGER IF EXISTS update_company_updated_at ON company;
CREATE TRIGGER update_company_updated_at
    BEFORE UPDATE ON company
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- ✅ MIGRATION TERMINÉE
-- ============================================================================

-- Résumé de la structure:
-- investor_group (1) ────< (n) company ────< (n) missions ────< (n) timesheet_entries

COMMENT ON DATABASE postgres IS 'OXO Time Sheets - Architecture hiérarchique Groupe → Société → Mission → Saisie';

-- Pour vérifier:
-- SELECT * FROM investor_group;
-- SELECT * FROM company;
-- SELECT * FROM company_with_group;
-- SELECT * FROM mission_with_context LIMIT 5;

