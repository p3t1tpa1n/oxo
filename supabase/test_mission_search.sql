-- Script de test pour vérifier les missions et diagnostiquer le problème de recherche

-- 1. Vérifier si la table missions existe
SELECT 
    'Vérification table missions' as info,
    COUNT(*) as count
FROM information_schema.tables
WHERE table_name = 'missions' AND table_schema = 'public';

-- 2. Vérifier le contenu de la table missions
SELECT 
    'Contenu table missions' as info,
    COUNT(*) as total_missions,
    COUNT(CASE WHEN title IS NOT NULL THEN 1 END) as missions_avec_titre
FROM missions;

-- 3. Afficher quelques missions d'exemple
SELECT 
    'Exemples de missions' as info,
    id,
    title,
    description,
    budget,
    priority,
    status
FROM missions
ORDER BY created_at DESC
LIMIT 5;

-- 4. Insérer des missions de test si la table est vide
INSERT INTO missions (title, description, budget, priority, status)
SELECT * FROM (VALUES 
    ('Compta entreprise X', 'Mission de comptabilité pour l''entreprise X', 5000, 'Élevée', 'pending'),
    ('Audit financier ABC', 'Audit financier complet pour la société ABC', 8000, 'Critique', 'pending'),
    ('Mission comptable DEF', 'Mission de comptabilité générale pour DEF', 4000, 'Moyenne', 'pending'),
    ('Comptabilité GHI', 'Gestion comptable pour l''entreprise GHI', 3000, 'Faible', 'pending'),
    ('Audit interne JKL', 'Audit interne pour la société JKL', 6000, 'Élevée', 'pending')
) AS test_missions(title, description, budget, priority, status)
WHERE NOT EXISTS (SELECT 1 FROM missions LIMIT 1);

-- 5. Vérification finale
SELECT 
    'Vérification finale' as info,
    COUNT(*) as total_missions
FROM missions;


