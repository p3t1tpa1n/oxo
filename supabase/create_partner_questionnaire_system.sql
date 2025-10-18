-- =============================================
-- SYSTÈME DE QUESTIONNAIRE PARTENAIRE
-- =============================================

-- 1. Table principale des profils partenaires
CREATE TABLE IF NOT EXISTS partner_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    questionnaire_completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    
    -- Informations personnelles
    civility TEXT CHECK (civility IN ('M.', 'Mme', 'Dr', 'Prof')),
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    phone TEXT,
    birth_date DATE,
    address TEXT,
    postal_code TEXT,
    city TEXT,
    
    -- Informations société
    company_name TEXT,
    legal_form TEXT,
    capital TEXT,
    company_address TEXT,
    company_postal_code TEXT,
    company_city TEXT,
    rcs TEXT,
    siren TEXT,
    representative_name TEXT,
    representative_title TEXT,
    
    -- Domaines d'activité (JSON array)
    activity_domains JSONB DEFAULT '[]'::jsonb,
    
    -- Langues (JSON array)
    languages JSONB DEFAULT '[]'::jsonb,
    
    -- Diplômes (JSON array)
    diplomas JSONB DEFAULT '[]'::jsonb,
    
    -- Parcours (JSON array)
    career_paths JSONB DEFAULT '[]'::jsonb,
    
    -- Fonctions principales (JSON array)
    main_functions JSONB DEFAULT '[]'::jsonb,
    
    -- Expériences professionnelles (JSON array)
    professional_experiences JSONB DEFAULT '[]'::jsonb,
    
    -- Secteurs d'activité (JSON array)
    business_sectors JSONB DEFAULT '[]'::jsonb,
    
    -- Types de structure (JSON array)
    structure_types JSONB DEFAULT '[]'::jsonb,
    
    -- Rémunération
    current_remuneration_type TEXT CHECK (current_remuneration_type IN ('daily', 'monthly')),
    current_remuneration_amount DECIMAL(10,2),
    
    -- Métadonnées pour l'assignation
    experience_score INTEGER DEFAULT 0,
    availability_score INTEGER DEFAULT 0,
    language_score INTEGER DEFAULT 0,
    sector_expertise_score INTEGER DEFAULT 0,
    
    UNIQUE(user_id)
);

-- 2. Table des critères de sélection pour les missions
CREATE TABLE IF NOT EXISTS mission_criteria (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    mission_id UUID, -- Référence vers la mission (à définir selon votre structure)
    required_domains JSONB DEFAULT '[]'::jsonb,
    required_languages JSONB DEFAULT '[]'::jsonb,
    required_experiences JSONB DEFAULT '[]'::jsonb,
    required_sectors JSONB DEFAULT '[]'::jsonb,
    required_functions JSONB DEFAULT '[]'::jsonb,
    required_structure_types JSONB DEFAULT '[]'::jsonb,
    priority_score INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- 3. Table de correspondance partenaire-mission
CREATE TABLE IF NOT EXISTS partner_mission_matches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    partner_profile_id UUID NOT NULL REFERENCES partner_profiles(id) ON DELETE CASCADE,
    mission_id UUID, -- À adapter selon votre structure
    match_score DECIMAL(5,2) DEFAULT 0,
    match_reasons JSONB DEFAULT '[]'::jsonb, -- Raisons du match
    is_recommended BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
    UNIQUE(partner_profile_id, mission_id)
);

-- 4. Index pour optimiser les recherches
CREATE INDEX IF NOT EXISTS idx_partner_profiles_user_id ON partner_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_partner_profiles_questionnaire_completed ON partner_profiles(questionnaire_completed);
CREATE INDEX IF NOT EXISTS idx_partner_profiles_activity_domains ON partner_profiles USING GIN(activity_domains);
CREATE INDEX IF NOT EXISTS idx_partner_profiles_languages ON partner_profiles USING GIN(languages);
CREATE INDEX IF NOT EXISTS idx_partner_profiles_experiences ON partner_profiles USING GIN(professional_experiences);
CREATE INDEX IF NOT EXISTS idx_partner_profiles_sectors ON partner_profiles USING GIN(business_sectors);
CREATE INDEX IF NOT EXISTS idx_partner_profiles_functions ON partner_profiles USING GIN(main_functions);

-- 5. Fonction pour calculer le score de compatibilité
CREATE OR REPLACE FUNCTION calculate_partner_match_score(
    p_partner_profile_id UUID,
    p_mission_criteria_id UUID
) RETURNS DECIMAL(5,2) AS $$
DECLARE
    partner_profile RECORD;
    mission_criteria RECORD;
    total_score DECIMAL(5,2) := 0;
    domain_matches INTEGER := 0;
    language_matches INTEGER := 0;
    experience_matches INTEGER := 0;
    sector_matches INTEGER := 0;
    function_matches INTEGER := 0;
BEGIN
    -- Récupérer le profil partenaire
    SELECT * INTO partner_profile 
    FROM partner_profiles 
    WHERE id = p_partner_profile_id;
    
    -- Récupérer les critères de mission
    SELECT * INTO mission_criteria 
    FROM mission_criteria 
    WHERE id = p_mission_criteria_id;
    
    -- Calculer les correspondances de domaines
    SELECT COUNT(*) INTO domain_matches
    FROM jsonb_array_elements_text(partner_profile.activity_domains) AS p_domain
    WHERE p_domain = ANY(
        SELECT jsonb_array_elements_text(mission_criteria.required_domains)
    );
    
    -- Calculer les correspondances de langues
    SELECT COUNT(*) INTO language_matches
    FROM jsonb_array_elements_text(partner_profile.languages) AS p_lang
    WHERE p_lang = ANY(
        SELECT jsonb_array_elements_text(mission_criteria.required_languages)
    );
    
    -- Calculer les correspondances d'expériences
    SELECT COUNT(*) INTO experience_matches
    FROM jsonb_array_elements_text(partner_profile.professional_experiences) AS p_exp
    WHERE p_exp = ANY(
        SELECT jsonb_array_elements_text(mission_criteria.required_experiences)
    );
    
    -- Calculer les correspondances de secteurs
    SELECT COUNT(*) INTO sector_matches
    FROM jsonb_array_elements_text(partner_profile.business_sectors) AS p_sector
    WHERE p_sector = ANY(
        SELECT jsonb_array_elements_text(mission_criteria.required_sectors)
    );
    
    -- Calculer les correspondances de fonctions
    SELECT COUNT(*) INTO function_matches
    FROM jsonb_array_elements_text(partner_profile.main_functions) AS p_func
    WHERE p_func = ANY(
        SELECT jsonb_array_elements_text(mission_criteria.required_functions)
    );
    
    -- Calculer le score total (pondéré)
    total_score := (
        domain_matches * 2.0 +
        language_matches * 1.5 +
        experience_matches * 3.0 +
        sector_matches * 2.5 +
        function_matches * 2.0
    );
    
    RETURN total_score;
END;
$$ LANGUAGE plpgsql;

-- 6. Fonction pour trouver les meilleurs partenaires pour une mission
CREATE OR REPLACE FUNCTION find_best_partners_for_mission(
    p_mission_criteria_id UUID,
    p_limit INTEGER DEFAULT 10
) RETURNS TABLE(
    partner_profile_id UUID,
    partner_name TEXT,
    match_score DECIMAL(5,2),
    match_reasons JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        pp.id,
        CONCAT(pp.first_name, ' ', pp.last_name) as partner_name,
        calculate_partner_match_score(pp.id, p_mission_criteria_id) as match_score,
        jsonb_build_object(
            'domains', pp.activity_domains,
            'languages', pp.languages,
            'experiences', pp.professional_experiences,
            'sectors', pp.business_sectors,
            'functions', pp.main_functions
        ) as match_reasons
    FROM partner_profiles pp
    WHERE pp.questionnaire_completed = TRUE
    ORDER BY calculate_partner_match_score(pp.id, p_mission_criteria_id) DESC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

-- 7. RLS Policies
ALTER TABLE partner_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE mission_criteria ENABLE ROW LEVEL SECURITY;
ALTER TABLE partner_mission_matches ENABLE ROW LEVEL SECURITY;

-- Politiques pour partner_profiles
CREATE POLICY "Users can view their own profile" ON partner_profiles
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile" ON partner_profiles
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own profile" ON partner_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Les associés peuvent voir tous les profils
CREATE POLICY "Associates can view all profiles" ON partner_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'associate'
        )
    );

-- Politiques pour mission_criteria
CREATE POLICY "Associates can manage mission criteria" ON mission_criteria
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'associate'
        )
    );

-- Politiques pour partner_mission_matches
CREATE POLICY "Associates can view all matches" ON partner_mission_matches
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'associate'
        )
    );

CREATE POLICY "Associates can manage matches" ON partner_mission_matches
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM user_roles 
            WHERE user_id = auth.uid() 
            AND user_role = 'associate'
        )
    );

-- 8. Trigger pour mettre à jour updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_partner_profiles_updated_at
    BEFORE UPDATE ON partner_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 9. Vue pour les associés : résumé des profils partenaires
CREATE OR REPLACE VIEW partner_profiles_summary AS
SELECT 
    pp.id,
    pp.user_id,
    CONCAT(pp.first_name, ' ', pp.last_name) as full_name,
    pp.email,
    pp.phone,
    pp.company_name,
    pp.activity_domains,
    pp.languages,
    pp.professional_experiences,
    pp.business_sectors,
    pp.main_functions,
    pp.experience_score,
    pp.availability_score,
    pp.language_score,
    pp.sector_expertise_score,
    pp.questionnaire_completed,
    pp.completed_at,
    pp.created_at,
    pp.updated_at
FROM partner_profiles pp
WHERE pp.questionnaire_completed = TRUE;

-- 10. Fonction pour vérifier si un utilisateur a complété le questionnaire
CREATE OR REPLACE FUNCTION has_completed_questionnaire(p_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM partner_profiles 
        WHERE user_id = p_user_id 
        AND questionnaire_completed = TRUE
    );
END;
$$ LANGUAGE plpgsql;

-- 11. Fonction pour obtenir le profil partenaire d'un utilisateur
CREATE OR REPLACE FUNCTION get_partner_profile(p_user_id UUID)
RETURNS partner_profiles AS $$
DECLARE
    profile partner_profiles;
BEGIN
    SELECT * INTO profile 
    FROM partner_profiles 
    WHERE user_id = p_user_id;
    
    RETURN profile;
END;
$$ LANGUAGE plpgsql;
