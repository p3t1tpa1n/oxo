-- Script pour ajouter la colonne progress_status à la table missions
-- Cette colonne permet de suivre l'avancement de la mission

-- 1. Créer l'enum pour les statuts d'avancement
DO $$ 
BEGIN
    -- Vérifier si l'enum existe déjà
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'mission_progress_type') THEN
        CREATE TYPE mission_progress_type AS ENUM ('à_assigner', 'en_cours', 'fait');
        RAISE NOTICE 'Type mission_progress_type créé';
    ELSE
        RAISE NOTICE 'Type mission_progress_type existe déjà';
    END IF;
END $$;

-- 2. Ajouter la colonne progress_status à la table missions
DO $$ 
BEGIN
    -- Vérifier si la colonne progress_status existe déjà
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'missions' 
        AND column_name = 'progress_status'
    ) THEN
        ALTER TABLE missions 
        ADD COLUMN progress_status mission_progress_type DEFAULT 'à_assigner';
        RAISE NOTICE 'Colonne progress_status ajoutée';
    ELSE
        RAISE NOTICE 'Colonne progress_status existe déjà';
    END IF;
END $$;

-- 3. Mettre à jour les missions existantes
-- Les missions acceptées passent en "à_assigner"
-- Les missions terminées passent en "fait"
UPDATE missions 
SET progress_status = CASE 
    WHEN status = 'completed' OR status = 'terminé' OR status = 'fait' THEN 'fait'::mission_progress_type
    WHEN status = 'accepted' OR status = 'acceptée' OR status = 'en_cours' THEN 'en_cours'::mission_progress_type
    ELSE 'à_assigner'::mission_progress_type
END
WHERE progress_status IS NULL;

-- 4. Rendre la colonne progress_status NOT NULL
ALTER TABLE missions 
ALTER COLUMN progress_status SET NOT NULL;

-- 5. Créer un index sur la colonne progress_status
CREATE INDEX IF NOT EXISTS idx_missions_progress_status ON missions(progress_status);

-- 6. Ajouter des commentaires pour documenter
COMMENT ON COLUMN missions.progress_status IS 'Statut d''avancement de la mission: à_assigner, en_cours, ou fait';
COMMENT ON TYPE mission_progress_type IS 'Type énuméré pour les statuts d''avancement de mission';

-- 7. Créer une vue pour faciliter les requêtes
CREATE OR REPLACE VIEW missions_with_full_status AS
SELECT 
    m.*,
    CASE m.status
        WHEN 'pending' THEN 'En attente'
        WHEN 'accepted' THEN 'Acceptée'
        WHEN 'rejected' THEN 'Refusée'
        ELSE m.status
    END AS status_display,
    CASE m.progress_status
        WHEN 'à_assigner' THEN 'À assigner'
        WHEN 'en_cours' THEN 'En cours'
        WHEN 'fait' THEN 'Fait'
    END AS progress_display
FROM missions m;

-- 8. Donner les permissions sur la vue
GRANT SELECT ON missions_with_full_status TO authenticated;

-- 9. Vérifier le résultat
SELECT 
    column_name, 
    data_type,
    udt_name,
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'missions' 
AND column_name IN ('status', 'progress_status')
ORDER BY column_name;

-- 10. Afficher quelques exemples
SELECT 
    id, 
    title, 
    status, 
    progress_status,
    created_at 
FROM missions 
ORDER BY created_at DESC 
LIMIT 5;
