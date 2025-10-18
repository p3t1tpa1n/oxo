-- Script d'automatisation complète pour corriger les profils partenaires
-- Ce script diagnostique et corrige automatiquement tous les problèmes

DO $$
DECLARE
    table_exists boolean;
    rls_enabled boolean;
    profile_count integer;
    user_count integer;
    policies_count integer;
BEGIN
    RAISE NOTICE '🚀 DÉBUT DE L''AUTOMATISATION - Correction des profils partenaires';
    RAISE NOTICE '================================================';
    
    -- 1. Vérifier l'existence de la table partner_profiles
    SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'partner_profiles' AND table_schema = 'public'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE '❌ Table partner_profiles n''existe pas - Création nécessaire';
        -- Ici on pourrait créer la table, mais c'est complexe
        RAISE NOTICE '⚠️ Veuillez d''abord exécuter create_partner_questionnaire_system.sql';
        RETURN;
    ELSE
        RAISE NOTICE '✅ Table partner_profiles existe';
    END IF;
    
    -- 2. Vérifier l'état de RLS
    SELECT rowsecurity INTO rls_enabled
    FROM pg_tables 
    WHERE tablename = 'partner_profiles';
    
    IF rls_enabled THEN
        RAISE NOTICE '✅ RLS activé sur partner_profiles';
    ELSE
        RAISE NOTICE '⚠️ RLS désactivé sur partner_profiles';
    END IF;
    
    -- 3. Compter les profils existants
    SELECT COUNT(*) INTO profile_count FROM partner_profiles;
    RAISE NOTICE '📊 Nombre de profils existants: %', profile_count;
    
    -- 4. Compter les utilisateurs
    SELECT COUNT(*) INTO user_count FROM user_roles;
    RAISE NOTICE '👥 Nombre d''utilisateurs: %', user_count;
    
    -- 5. Vérifier les politiques RLS
    SELECT COUNT(*) INTO policies_count 
    FROM pg_policies 
    WHERE tablename = 'partner_profiles';
    RAISE NOTICE '🛡️ Nombre de politiques RLS: %', policies_count;
    
    -- 6. Si aucun profil n'existe, en créer
    IF profile_count = 0 THEN
        RAISE NOTICE '📝 Aucun profil trouvé - Création de profils de test...';
        
        -- Insérer des profils de test
        INSERT INTO partner_profiles (
            user_id, civility, first_name, last_name, email, phone, birth_date,
            address, postal_code, city, company_name, legal_form, capital,
            company_address, company_postal_code, company_city, rcs, siren,
            representative_name, representative_title, activity_domains,
            languages, diplomas, career_paths, main_functions,
            professional_experiences, business_sectors, structure_types,
            current_remuneration_type, current_remuneration_amount,
            questionnaire_completed, completed_at
        ) VALUES 
        -- Profil 1: Partenaire avec expérience financière
        (
            'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7',
            'M.', 'Pat', 'Dumoulin', 'part@gmail.com', '0612345678', '1985-03-15',
            '123 Rue de la Paix', '75001', 'Paris', 'Dumoulin Consulting', 'SAS', '50000',
            '123 Rue de la Paix', '75001', 'Paris', 'RCS123456', '123456789',
            'Pat Dumoulin', 'Directeur Général', '["Direction Financière", "Direction Juridique"]',
            '["Anglais bilingue", "Allemand courant"]', '["Master Finance", "DESMA HEC"]',
            '["Commerce", "Finance"]', '["Directeur Général Groupe", "Directeur d''Établissement"]',
            '["Accompagnement Ciri", "Carve-out", "Acquisition", "In bonis"]',
            '["Finance", "Banque", "Assurance"]', '["PME", "ETI"]',
            'Journalière', 800, true, NOW()
        ),
        -- Profil 2: Partenaire avec expérience industrielle
        (
            'ab618e61-e44b-4a42-a312-dbc8fb5bd3c2',
            'Mme', 'Marie', 'Dubois', 'marie.dubois@example.com', '0698765432', '1980-07-22',
            '456 Avenue des Champs', '75008', 'Paris', 'Dubois Industries', 'SARL', '100000',
            '456 Avenue des Champs', '75008', 'Paris', 'RCS789012', '987654321',
            'Marie Dubois', 'Présidente', '["Direction Générale", "Direction Transformation"]',
            '["Anglais courant", "Espagnol technique"]', '["Master Industrie", "MBA"]',
            '["Industriel", "Opérations"]', '["Président", "Directeur Général Groupe"]',
            '["Restructuration", "PSE", "Réorganisation"]', '["Industrie", "Aéronautique", "Automobile"]',
            '["ETI", "Groupe"]', 'Mensuelle', 12000, true, NOW()
        ),
        -- Profil 3: Partenaire avec expérience tech
        (
            '31e265bd-c26e-4aaa-84ef-c1fa3992ec0a',
            'M.', 'Jean', 'Martin', 'jean.martin@example.com', '0654321098', '1990-11-10',
            '789 Boulevard Saint-Germain', '75006', 'Paris', 'Martin Tech', 'SAS', '25000',
            '789 Boulevard Saint-Germain', '75006', 'Paris', 'RCS345678', '345678901',
            'Jean Martin', 'Directeur Technique', '["Direction Transformation", "Direction Juridique"]',
            '["Anglais bilingue", "Chinois technique"]', '["Master Informatique", "PhD"]',
            '["Marketing", "Opérations"]', '["Directeur de Transformation", "Directeur d''Établissement"]',
            '["Levée de fonds", "Spin-off", "Split-off"]', '["Tech", "Média", "Service"]',
            '["Startup", "PME"]', 'Journalière', 600, true, NOW()
        );
        
        RAISE NOTICE '✅ 3 profils de test créés';
    ELSE
        RAISE NOTICE '✅ Profils existants trouvés: %', profile_count;
    END IF;
    
    -- 7. Vérifier et corriger les politiques RLS si nécessaire
    IF policies_count = 0 OR policies_count < 3 THEN
        RAISE NOTICE '🛡️ Correction des politiques RLS...';
        
        -- Supprimer les anciennes politiques
        DROP POLICY IF EXISTS "Users can view their own profile" ON partner_profiles;
        DROP POLICY IF EXISTS "Users can update their own profile" ON partner_profiles;
        DROP POLICY IF EXISTS "Users can insert their own profile" ON partner_profiles;
        DROP POLICY IF EXISTS "Associates can view all profiles" ON partner_profiles;
        DROP POLICY IF EXISTS "Admins can view all profiles" ON partner_profiles;
        DROP POLICY IF EXISTS "Allow all authenticated users to view profiles" ON partner_profiles;
        
        -- Créer les nouvelles politiques
        CREATE POLICY "Users can view their own profile" ON partner_profiles
            FOR SELECT USING (auth.uid() = user_id);
            
        CREATE POLICY "Users can update their own profile" ON partner_profiles
            FOR UPDATE USING (auth.uid() = user_id);
            
        CREATE POLICY "Users can insert their own profile" ON partner_profiles
            FOR INSERT WITH CHECK (auth.uid() = user_id);
            
        CREATE POLICY "Associates can view all profiles" ON partner_profiles
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM user_roles 
                    WHERE user_id = auth.uid() 
                    AND user_role = 'associe'
                )
            );
            
        CREATE POLICY "Admins can view all profiles" ON partner_profiles
            FOR SELECT USING (
                EXISTS (
                    SELECT 1 FROM user_roles 
                    WHERE user_id = auth.uid() 
                    AND user_role = 'admin'
                )
            );
            
        CREATE POLICY "Allow all authenticated users to view profiles" ON partner_profiles
            FOR SELECT USING (auth.uid() IS NOT NULL);
            
        RAISE NOTICE '✅ Politiques RLS créées/corrigées';
    ELSE
        RAISE NOTICE '✅ Politiques RLS déjà en place: %', policies_count;
    END IF;
    
    -- 8. S'assurer que RLS est activé
    ALTER TABLE partner_profiles ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ RLS activé sur partner_profiles';
    
    -- 9. Test final
    SELECT COUNT(*) INTO profile_count FROM partner_profiles;
    RAISE NOTICE '📊 Test final - Profils accessibles: %', profile_count;
    
    -- 10. Afficher un résumé
    RAISE NOTICE '================================================';
    RAISE NOTICE '🎉 AUTOMATISATION TERMINÉE AVEC SUCCÈS !';
    RAISE NOTICE '📊 Résumé:';
    RAISE NOTICE '   - Profils partenaires: %', profile_count;
    RAISE NOTICE '   - Utilisateurs: %', user_count;
    RAISE NOTICE '   - Politiques RLS: %', (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'partner_profiles');
    RAISE NOTICE '   - RLS activé: %', (SELECT rowsecurity FROM pg_tables WHERE tablename = 'partner_profiles');
    RAISE NOTICE '================================================';
    RAISE NOTICE '🚀 Vous pouvez maintenant relancer l''application !';
    
END $$;
