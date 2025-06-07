-- Script de diagnostic et correction pour l'assignation utilisateur-entreprise
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Diagnostic : Vérifier la structure existante
SELECT 'DIAGNOSTIC : État actuel du système' as info;

-- Vérifier les entreprises existantes
SELECT 'ENTREPRISES EXISTANTES :' as info;
SELECT id, name, status FROM public.companies ORDER BY id;

-- Vérifier les utilisateurs et leurs assignations
SELECT 'UTILISATEURS ET ASSIGNATIONS :' as info;
SELECT 
    p.user_id,
    p.email,
    p.first_name,
    p.last_name,
    p.role,
    p.company_id,
    c.name as company_name
FROM public.profiles p
LEFT JOIN public.companies c ON p.company_id = c.id
ORDER BY p.role, p.email;

-- Vérifier la vue user_company_info
SELECT 'VUE USER_COMPANY_INFO :' as info;
SELECT * FROM public.user_company_info LIMIT 5;

-- 2. Corrections automatiques

-- S'assurer qu'il y a au moins une entreprise
INSERT INTO public.companies (name, description, status) 
SELECT 'Entreprise Principal', 'Entreprise par défaut du système', 'active'
WHERE NOT EXISTS (SELECT 1 FROM public.companies WHERE name = 'Entreprise Principal');

-- Récupérer l'ID de l'entreprise principale
DO $$
DECLARE
    main_company_id BIGINT;
    user_record RECORD;
BEGIN
    -- Récupérer l'ID de l'entreprise principale
    SELECT id INTO main_company_id 
    FROM public.companies 
    WHERE name = 'Entreprise Principal' 
    LIMIT 1;
    
    IF main_company_id IS NOT NULL THEN
        -- Assigner tous les utilisateurs admin/associé sans entreprise à l'entreprise principale
        UPDATE public.profiles 
        SET company_id = main_company_id, updated_at = NOW()
        WHERE role IN ('admin', 'associe') 
        AND (company_id IS NULL OR company_id = 0);
        
        -- Assigner aussi les partenaires sans entreprise
        UPDATE public.profiles 
        SET company_id = main_company_id, updated_at = NOW()
        WHERE role = 'partenaire' 
        AND (company_id IS NULL OR company_id = 0);
        
        -- Pour les clients, on peut les assigner à la première entreprise aussi
        -- ou créer une entreprise "Clients Divers"
        INSERT INTO public.companies (name, description, status) 
        SELECT 'Clients Divers', 'Entreprise pour clients non assignés', 'active'
        WHERE NOT EXISTS (SELECT 1 FROM public.companies WHERE name = 'Clients Divers');
        
        -- Assigner les clients sans entreprise
        UPDATE public.profiles 
        SET company_id = (SELECT id FROM public.companies WHERE name = 'Clients Divers' LIMIT 1), 
            updated_at = NOW()
        WHERE role = 'client' 
        AND (company_id IS NULL OR company_id = 0);
        
        RAISE NOTICE 'Assignations automatiques effectuées vers l''entreprise principale (ID: %)', main_company_id;
    ELSE
        RAISE NOTICE 'Erreur: Impossible de trouver l''entreprise principale';
    END IF;
END;
$$;

-- 3. Vérifications post-correction
SELECT 'APRÈS CORRECTIONS :' as info;

-- Vérifier que tous les utilisateurs ont une entreprise
SELECT 'UTILISATEURS SANS ENTREPRISE (devrait être vide) :' as info;
SELECT user_id, email, role FROM public.profiles 
WHERE company_id IS NULL OR company_id = 0;

-- Afficher les assignations finales
SELECT 'ASSIGNATIONS FINALES :' as info;
SELECT 
    p.user_id,
    p.email,
    p.first_name,
    p.last_name,
    p.role,
    c.name as company_name,
    c.id as company_id
FROM public.profiles p
JOIN public.companies c ON p.company_id = c.id
ORDER BY c.name, p.role, p.email;

-- 4. Test de la vue user_company_info
SELECT 'TEST VUE USER_COMPANY_INFO (admin/associé) :' as info;
SELECT * FROM public.user_company_info 
WHERE role IN ('admin', 'associe') 
LIMIT 3;

-- 5. Fonction helper pour assigner manuellement un utilisateur
CREATE OR REPLACE FUNCTION assign_current_user_to_main_company()
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    main_company_id BIGINT;
    current_user_id UUID;
    result_text TEXT;
BEGIN
    -- Récupérer l'utilisateur actuel
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RETURN 'Erreur: Aucun utilisateur connecté';
    END IF;
    
    -- Récupérer l'entreprise principale
    SELECT id INTO main_company_id 
    FROM public.companies 
    WHERE name = 'Entreprise Principal' 
    LIMIT 1;
    
    IF main_company_id IS NULL THEN
        RETURN 'Erreur: Entreprise principale non trouvée';
    END IF;
    
    -- Assigner l'utilisateur à l'entreprise
    UPDATE public.profiles 
    SET company_id = main_company_id, updated_at = NOW()
    WHERE user_id = current_user_id;
    
    IF FOUND THEN
        result_text := 'Utilisateur ' || current_user_id || ' assigné à l''entreprise ' || main_company_id;
    ELSE
        result_text := 'Erreur: Profil utilisateur non trouvé';
    END IF;
    
    RETURN result_text;
END;
$$;

-- Message final
SELECT '✅ Diagnostic et corrections terminés !' as result;
SELECT 'Pour assigner manuellement l''utilisateur connecté, exécutez : SELECT assign_current_user_to_main_company();' as help; 