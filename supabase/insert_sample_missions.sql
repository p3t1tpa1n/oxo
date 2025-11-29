-- Script pour insérer des missions d'exemple pour tester l'autocomplétion

-- Vérifier si la table missions existe
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'missions' AND table_schema = 'public') THEN
        RAISE NOTICE 'Table missions n''existe pas - création nécessaire';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Table missions trouvée - insertion des missions d''exemple';
END $$;

-- Insérer des missions d'exemple
INSERT INTO missions (title, description, start_date, end_date, budget, priority, status, partner_id, associate_id)
VALUES 
    ('Compta entreprise X', 'Mission de comptabilité pour l''entreprise X - Audit financier complet', '2025-01-15', '2025-02-15', 5000, 'Élevée', 'pending', NULL, NULL),
    ('Compta entreprise Y', 'Mission de comptabilité pour l''entreprise Y - Révision des comptes', '2025-01-20', '2025-02-20', 3500, 'Moyenne', 'pending', NULL, NULL),
    ('Audit financier ABC', 'Audit financier complet pour la société ABC', '2025-02-01', '2025-03-01', 8000, 'Critique', 'pending', NULL, NULL),
    ('Mission comptable DEF', 'Mission de comptabilité générale pour DEF', '2025-02-10', '2025-03-10', 4000, 'Moyenne', 'pending', NULL, NULL),
    ('Comptabilité GHI', 'Gestion comptable pour l''entreprise GHI', '2025-02-15', '2025-03-15', 3000, 'Faible', 'pending', NULL, NULL),
    ('Audit interne JKL', 'Audit interne pour la société JKL', '2025-03-01', '2025-04-01', 6000, 'Élevée', 'pending', NULL, NULL),
    ('Mission financière MNO', 'Mission de conseil financier pour MNO', '2025-03-10', '2025-04-10', 4500, 'Moyenne', 'pending', NULL, NULL),
    ('Comptabilité PQR', 'Mission comptable pour PQR - Tenue de livres', '2025-03-15', '2025-04-15', 2500, 'Faible', 'pending', NULL, NULL),
    ('Audit complet STU', 'Audit complet pour la société STU', '2025-04-01', '2025-05-01', 10000, 'Critique', 'pending', NULL, NULL),
    ('Mission comptable VWX', 'Mission de comptabilité pour VWX', '2025-04-10', '2025-05-10', 3500, 'Moyenne', 'pending', NULL, NULL)
ON CONFLICT (id) DO NOTHING;

-- Vérifier les missions insérées
SELECT 
    'Missions d''exemple insérées' as info,
    COUNT(*) as count
FROM missions
WHERE title LIKE '%Compta%' OR title LIKE '%Audit%' OR title LIKE '%Mission%';

-- Afficher quelques exemples
SELECT 
    'Exemples de missions' as info,
    title,
    description,
    priority
FROM missions
WHERE title LIKE '%Compta%' OR title LIKE '%Audit%' OR title LIKE '%Mission%'
ORDER BY title
LIMIT 5;


