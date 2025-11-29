-- ============================================================================
-- 📦 MIGRATION DES DONNÉES EXISTANTES
-- ============================================================================
-- Migre les anciennes données de l'ancienne structure vers la nouvelle
-- ============================================================================

-- ============================================================================
-- ÉTAPE 1: Créer un groupe "Clients Historiques" pour les anciens clients
-- ============================================================================

INSERT INTO investor_group (name, sector, country, notes)
VALUES (
    'Clients Historiques',
    'Divers',
    'France',
    'Groupe créé automatiquement pour migrer les anciens clients sans groupe défini'
)
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- ÉTAPE 2: Migrer les anciens clients vers la table company
-- ============================================================================
-- Si vous aviez une table "clients" avec: id, name, email, etc.

DO $$ 
DECLARE
    historical_group_id BIGINT;
BEGIN
    -- Récupérer l'ID du groupe historique
    SELECT id INTO historical_group_id 
    FROM investor_group 
    WHERE name = 'Clients Historiques';

    -- Migrer les clients existants (adapter selon votre structure)
    -- Exemple si vous aviez une table clients:
    /*
    INSERT INTO company (name, group_id, contact_email, notes, active)
    SELECT 
        name,
        historical_group_id,
        email,
        'Migré depuis ancienne table clients',
        active
    FROM clients
    ON CONFLICT DO NOTHING;
    */

    RAISE NOTICE 'Migration des clients historiques terminée';
END $$;

-- ============================================================================
-- ÉTAPE 3: Créer des missions par défaut pour les anciennes saisies
-- ============================================================================
-- Si vous avez des timesheet_entries avec client_id mais pas de mission

DO $$ 
DECLARE
    entry RECORD;
    new_mission_id UUID;
    company_record RECORD;
BEGIN
    -- Pour chaque saisie sans mission_id mais avec client_id
    FOR entry IN 
        SELECT DISTINCT 
            te.client_id,
            te.partner_id,
            MIN(te.entry_date) as first_date,
            MAX(te.entry_date) as last_date
        FROM timesheet_entries te
        WHERE te.mission_id IS NULL
        AND te.client_id IS NOT NULL
        GROUP BY te.client_id, te.partner_id
    LOOP
        -- Trouver la company correspondante
        -- (Adapter selon votre logique de correspondance)
        SELECT * INTO company_record
        FROM company
        WHERE id = entry.client_id::BIGINT
        LIMIT 1;

        IF FOUND THEN
            -- Créer une mission "Migration" pour ce client/partenaire
            INSERT INTO missions (
                title,
                company_id,
                partner_id,
                start_date,
                end_date,
                status,
                progress_status,
                daily_rate
            ) VALUES (
                'Mission Migration - ' || company_record.name,
                company_record.id,
                entry.partner_id,
                entry.first_date,
                entry.last_date,
                'completed',
                'terminé',
                450.0  -- Tarif par défaut, à ajuster
            )
            RETURNING id INTO new_mission_id;

            -- Mettre à jour les timesheet_entries pour pointer vers cette mission
            UPDATE timesheet_entries
            SET mission_id = new_mission_id
            WHERE client_id = entry.client_id
            AND partner_id = entry.partner_id
            AND mission_id IS NULL;

            RAISE NOTICE 'Mission créée: % pour company %', new_mission_id, company_record.name;
        END IF;
    END LOOP;

    RAISE NOTICE 'Migration des missions terminée';
END $$;

-- ============================================================================
-- ÉTAPE 4: Vérification de la migration
-- ============================================================================

-- Compter les saisies sans mission (devrait être 0)
SELECT COUNT(*) AS saisies_sans_mission
FROM timesheet_entries
WHERE mission_id IS NULL;

-- Compter les missions créées
SELECT COUNT(*) AS missions_total
FROM missions;

-- Résumé par groupe
SELECT 
    ig.name AS groupe,
    COUNT(DISTINCT c.id) AS nb_societes,
    COUNT(DISTINCT m.id) AS nb_missions,
    COUNT(te.id) AS nb_saisies
FROM investor_group ig
LEFT JOIN company c ON c.group_id = ig.id
LEFT JOIN missions m ON m.company_id = c.id
LEFT JOIN timesheet_entries te ON te.mission_id = m.id
GROUP BY ig.id, ig.name
ORDER BY nb_saisies DESC;

-- ============================================================================
-- ÉTAPE 5: Nettoyage (ATTENTION - à exécuter après vérification)
-- ============================================================================

-- Supprimer l'ancienne colonne client_id de timesheet_entries (après vérification)
-- ALTER TABLE timesheet_entries DROP COLUMN IF EXISTS client_id;

-- Supprimer l'ancienne colonne client_id de missions (après vérification)
-- ALTER TABLE missions DROP COLUMN IF EXISTS client_id;

-- ============================================================================
-- ✅ MIGRATION TERMINÉE
-- ============================================================================

COMMENT ON SCHEMA public IS 'OXO Time Sheets - Migration vers architecture hiérarchique terminée';






