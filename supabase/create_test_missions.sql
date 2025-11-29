-- Script pour créer des missions de test avec progress_status

-- D'abord, vérifier si la colonne progress_status existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'missions' 
        AND column_name = 'progress_status'
    ) THEN
        RAISE EXCEPTION 'La colonne progress_status n''existe pas. Exécutez d''abord add_progress_status_to_missions.sql';
    END IF;
END $$;

-- Récupérer le premier company_id disponible
DO $$
DECLARE
    v_company_id UUID;
    v_user_id UUID;
BEGIN
    -- Récupérer le premier company_id
    SELECT id INTO v_company_id FROM companies LIMIT 1;
    
    IF v_company_id IS NULL THEN
        RAISE NOTICE 'Aucune entreprise trouvée. Créez d''abord une entreprise.';
        RETURN;
    END IF;
    
    -- Récupérer le premier user_id
    SELECT id INTO v_user_id FROM auth.users LIMIT 1;
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE 'Aucun utilisateur trouvé.';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Company ID: %, User ID: %', v_company_id, v_user_id;
    
    -- Insérer des missions de test avec différents statuts
    INSERT INTO missions (
        title,
        description,
        company_id,
        created_by,
        status,
        progress_status,
        priority,
        start_date,
        end_date
    ) VALUES
    -- Missions à assigner
    (
        'Mission Test 1 - Développement Frontend',
        'Créer une interface utilisateur moderne pour le dashboard',
        v_company_id,
        v_user_id,
        'pending',
        'à_assigner',
        'high',
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '30 days'
    ),
    (
        'Mission Test 2 - Configuration Base de Données',
        'Optimiser les requêtes et créer les index nécessaires',
        v_company_id,
        v_user_id,
        'accepted',
        'à_assigner',
        'medium',
        CURRENT_DATE,
        CURRENT_DATE + INTERVAL '15 days'
    ),
    -- Missions en cours
    (
        'Mission Test 3 - Intégration API',
        'Connecter l''application aux services externes',
        v_company_id,
        v_user_id,
        'accepted',
        'en_cours',
        'high',
        CURRENT_DATE - INTERVAL '5 days',
        CURRENT_DATE + INTERVAL '10 days'
    ),
    (
        'Mission Test 4 - Tests Unitaires',
        'Écrire des tests pour les modules critiques',
        v_company_id,
        v_user_id,
        'accepted',
        'en_cours',
        'low',
        CURRENT_DATE - INTERVAL '3 days',
        CURRENT_DATE + INTERVAL '20 days'
    ),
    -- Missions faites
    (
        'Mission Test 5 - Documentation',
        'Rédiger la documentation technique du projet',
        v_company_id,
        v_user_id,
        'accepted',
        'fait',
        'medium',
        CURRENT_DATE - INTERVAL '30 days',
        CURRENT_DATE - INTERVAL '5 days'
    ),
    (
        'Mission Test 6 - Configuration CI/CD',
        'Mettre en place le pipeline de déploiement',
        v_company_id,
        v_user_id,
        'accepted',
        'fait',
        'high',
        CURRENT_DATE - INTERVAL '20 days',
        CURRENT_DATE - INTERVAL '2 days'
    );
    
    RAISE NOTICE '✅ 6 missions de test créées avec succès';
END $$;

-- Vérifier les missions créées
SELECT 
    id,
    title,
    status,
    progress_status,
    priority,
    created_at
FROM missions 
ORDER BY created_at DESC 
LIMIT 10;
