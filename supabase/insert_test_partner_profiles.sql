-- Script pour insérer des profils partenaires de test

-- 1. Vérifier l'état actuel
SELECT 
    'État actuel' as info,
    COUNT(*) as total_profiles
FROM partner_profiles;

-- 2. Insérer des profils partenaires de test
INSERT INTO partner_profiles (
    user_id,
    civility,
    first_name,
    last_name,
    email,
    phone,
    birth_date,
    address,
    postal_code,
    city,
    company_name,
    legal_form,
    capital,
    company_address,
    company_postal_code,
    company_city,
    rcs,
    siren,
    representative_name,
    representative_title,
    activity_domains,
    languages,
    diplomas,
    career_paths,
    main_functions,
    professional_experiences,
    business_sectors,
    structure_types,
    current_remuneration_type,
    current_remuneration_amount,
    questionnaire_completed,
    completed_at
) VALUES 
-- Profil 1: Partenaire avec expérience financière
(
    'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7', -- ID du partenaire existant
    'M.',
    'Pat',
    'Dumoulin',
    'part@gmail.com',
    '0612345678',
    '1985-03-15',
    '123 Rue de la Paix',
    '75001',
    'Paris',
    'Dumoulin Consulting',
    'SAS',
    '50000',
    '123 Rue de la Paix',
    '75001',
    'Paris',
    'RCS123456',
    '123456789',
    'Pat Dumoulin',
    'Directeur Général',
    '["Direction Financière", "Direction Juridique"]',
    '["Anglais bilingue", "Allemand courant"]',
    '["Master Finance", "DESMA HEC"]',
    '["Commerce", "Finance"]',
    '["Directeur Général Groupe", "Directeur d''Établissement"]',
    '["Accompagnement Ciri", "Carve-out", "Acquisition", "In bonis"]',
    '["Finance", "Banque", "Assurance"]',
    '["PME", "ETI"]',
    'Journalière',
    800,
    true,
    NOW()
),
-- Profil 2: Partenaire avec expérience industrielle
(
    'ab618e61-e44b-4a42-a312-dbc8fb5bd3c2', -- ID du client (on va l'utiliser comme partenaire pour le test)
    'Mme',
    'Marie',
    'Dubois',
    'marie.dubois@example.com',
    '0698765432',
    '1980-07-22',
    '456 Avenue des Champs',
    '75008',
    'Paris',
    'Dubois Industries',
    'SARL',
    '100000',
    '456 Avenue des Champs',
    '75008',
    'Paris',
    'RCS789012',
    '987654321',
    'Marie Dubois',
    'Présidente',
    '["Direction Générale", "Direction Transformation"]',
    '["Anglais courant", "Espagnol technique"]',
    '["Master Industrie", "MBA"]',
    '["Industriel", "Opérations"]',
    '["Président", "Directeur Général Groupe"]',
    '["Restructuration", "PSE", "Réorganisation"]',
    '["Industrie", "Aéronautique", "Automobile"]',
    '["ETI", "Groupe"]',
    'Mensuelle',
    12000,
    true,
    NOW()
),
-- Profil 3: Partenaire avec expérience tech
(
    '31e265bd-c26e-4aaa-84ef-c1fa3992ec0a', -- ID de l'admin (on va l'utiliser comme partenaire pour le test)
    'M.',
    'Jean',
    'Martin',
    'jean.martin@example.com',
    '0654321098',
    '1990-11-10',
    '789 Boulevard Saint-Germain',
    '75006',
    'Paris',
    'Martin Tech',
    'SAS',
    '25000',
    '789 Boulevard Saint-Germain',
    '75006',
    'Paris',
    'RCS345678',
    '345678901',
    'Jean Martin',
    'Directeur Technique',
    '["Direction Transformation", "Direction Juridique"]',
    '["Anglais bilingue", "Chinois technique"]',
    '["Master Informatique", "PhD"]',
    '["Marketing", "Opérations"]',
    '["Directeur de Transformation", "Directeur d''Établissement"]',
    '["Levée de fonds", "Spin-off", "Split-off"]',
    '["Tech", "Média", "Service"]',
    '["Startup", "PME"]',
    'Journalière',
    600,
    true,
    NOW()
);

-- 3. Vérifier l'insertion
SELECT 
    'Après insertion' as info,
    COUNT(*) as total_profiles
FROM partner_profiles;

-- 4. Afficher les profils insérés
SELECT 
    'Profils insérés' as info,
    id,
    user_id,
    first_name,
    last_name,
    email,
    questionnaire_completed,
    created_at
FROM partner_profiles
ORDER BY created_at DESC;

-- 5. Tester l'accès avec RLS activé
SELECT 
    'Test accès avec RLS' as info,
    COUNT(*) as accessible_profiles
FROM partner_profiles;
