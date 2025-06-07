-- Script pour implémenter le multi-tenancy par entreprise
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Créer la table des entreprises
CREATE TABLE IF NOT EXISTS public.companies (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    address TEXT,
    phone VARCHAR(50),
    email VARCHAR(255),
    website VARCHAR(255),
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Index pour améliorer les performances
    UNIQUE(name)
);

-- 2. Ajouter la colonne company_id à la table profiles
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS company_id BIGINT;

-- 3. Ajouter la contrainte de clé étrangère
ALTER TABLE public.profiles 
DROP CONSTRAINT IF EXISTS profiles_company_id_fkey;

ALTER TABLE public.profiles 
ADD CONSTRAINT profiles_company_id_fkey 
FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE SET NULL;

-- 4. Ajouter la colonne company_id à la table projects
ALTER TABLE public.projects 
ADD COLUMN IF NOT EXISTS company_id BIGINT;

-- 5. Ajouter la contrainte de clé étrangère pour projects
ALTER TABLE public.projects 
DROP CONSTRAINT IF EXISTS projects_company_id_fkey;

ALTER TABLE public.projects 
ADD CONSTRAINT projects_company_id_fkey 
FOREIGN KEY (company_id) REFERENCES public.companies(id) ON DELETE CASCADE;

-- 6. Créer une fonction pour récupérer l'entreprise de l'utilisateur connecté
CREATE OR REPLACE FUNCTION get_user_company_id()
RETURNS BIGINT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    company_id BIGINT;
BEGIN
    SELECT p.company_id INTO company_id
    FROM public.profiles p
    WHERE p.user_id = auth.uid();
    
    RETURN company_id;
END;
$$;

-- 7. Créer des politiques RLS pour projects (filtrage par entreprise)
ALTER TABLE public.projects ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "projects_access" ON public.projects;
DROP POLICY IF EXISTS "projects_company_access" ON public.projects;

-- Politique pour les projets : accès uniquement aux projets de son entreprise
CREATE POLICY "projects_company_access"
ON public.projects
FOR ALL TO authenticated
USING (
    -- Admins et associés voient tous les projets
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    -- Clients et partenaires voient uniquement les projets de leur entreprise
    company_id = get_user_company_id()
)
WITH CHECK (
    -- Pour l'insertion/modification : même logique
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    company_id = get_user_company_id()
);

-- 8. Créer des politiques RLS pour tasks (filtrage via les projets)
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;

-- Supprimer les anciennes politiques
DROP POLICY IF EXISTS "tasks_select_policy" ON public.tasks;
DROP POLICY IF EXISTS "tasks_insert_policy" ON public.tasks;
DROP POLICY IF EXISTS "tasks_update_policy" ON public.tasks;
DROP POLICY IF EXISTS "tasks_delete_policy" ON public.tasks;

-- Politique pour les tâches : accès via les projets de l'entreprise
CREATE POLICY "tasks_company_select"
ON public.tasks FOR SELECT
TO authenticated
USING (
    -- Admins et associés voient toutes les tâches
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    -- Ou si la tâche appartient à un projet de l'entreprise de l'utilisateur
    EXISTS (
        SELECT 1 FROM public.projects p
        WHERE p.id = tasks.project_id
        AND p.company_id = get_user_company_id()
    )
    OR
    -- Ou si l'utilisateur est assigné à la tâche
    auth.uid() IN (user_id, assigned_to, partner_id)
);

CREATE POLICY "tasks_company_insert"
ON public.tasks FOR INSERT
TO authenticated
WITH CHECK (
    -- Admins et associés peuvent créer des tâches partout
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    -- Ou le projet appartient à l'entreprise de l'utilisateur
    EXISTS (
        SELECT 1 FROM public.projects p
        WHERE p.id = tasks.project_id
        AND p.company_id = get_user_company_id()
    )
);

CREATE POLICY "tasks_company_update"
ON public.tasks FOR UPDATE
TO authenticated
USING (
    -- Même logique que SELECT
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    EXISTS (
        SELECT 1 FROM public.projects p
        WHERE p.id = tasks.project_id
        AND p.company_id = get_user_company_id()
    )
    OR
    auth.uid() IN (user_id, assigned_to, partner_id)
)
WITH CHECK (
    -- Pour la modification : même logique que INSERT
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    EXISTS (
        SELECT 1 FROM public.projects p
        WHERE p.id = tasks.project_id
        AND p.company_id = get_user_company_id()
    )
);

CREATE POLICY "tasks_company_delete"
ON public.tasks FOR DELETE
TO authenticated
USING (
    -- Seuls les admins/associés ou propriétaires peuvent supprimer
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    auth.uid() IN (user_id, created_by)
);

-- 9. Créer des politiques RLS pour companies
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "companies_access"
ON public.companies FOR SELECT
TO authenticated
USING (
    -- Admins et associés voient toutes les entreprises
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
    OR
    -- Utilisateurs voient leur propre entreprise
    id = get_user_company_id()
);

CREATE POLICY "companies_admin_manage"
ON public.companies
FOR ALL TO authenticated
USING (
    -- Seuls admins et associés peuvent modifier les entreprises
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    )
);

-- 10. Créer des vues utiles
CREATE OR REPLACE VIEW user_company_info AS
SELECT 
    p.user_id,
    p.email,
    p.first_name,
    p.last_name,
    p.role,
    c.id as company_id,
    c.name as company_name,
    c.email as company_email
FROM public.profiles p
LEFT JOIN public.companies c ON p.company_id = c.id;

-- 11. Fonction pour assigner un utilisateur à une entreprise
CREATE OR REPLACE FUNCTION assign_user_to_company(
    user_id_param UUID,
    company_id_param BIGINT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier que l'utilisateur qui exécute est admin ou associé
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'associe')
    ) THEN
        RAISE EXCEPTION 'Permission refusée: seuls les admins et associés peuvent assigner des utilisateurs';
    END IF;
    
    -- Mettre à jour l'entreprise de l'utilisateur
    UPDATE public.profiles 
    SET company_id = company_id_param,
        updated_at = NOW()
    WHERE user_id = user_id_param;
    
    RETURN FOUND;
END;
$$;

-- 12. Créer des entreprises de test si aucune n'existe
INSERT INTO public.companies (name, description, email, status)
SELECT 
    'Entreprise Demo 1',
    'Première entreprise de démonstration',
    'contact@entreprise1.com',
    'active'
WHERE NOT EXISTS (SELECT 1 FROM public.companies LIMIT 1);

INSERT INTO public.companies (name, description, email, status)
SELECT 
    'Entreprise Demo 2', 
    'Deuxième entreprise de démonstration',
    'contact@entreprise2.com',
    'active'
WHERE (SELECT COUNT(*) FROM public.companies) < 2;

-- 13. Assigner les clients existants à des entreprises (démo)
-- Utiliser un CTE pour éviter les fonctions de fenêtre dans UPDATE
WITH client_distribution AS (
    SELECT 
        user_id,
        CASE 
            WHEN (ROW_NUMBER() OVER (ORDER BY created_at)) <= 
                 (SELECT COUNT(*) FROM public.profiles WHERE role = 'client') / 2
            THEN 1
            ELSE 2
        END as target_company_id
    FROM public.profiles 
    WHERE role = 'client' AND company_id IS NULL
)
UPDATE public.profiles 
SET company_id = cd.target_company_id
FROM client_distribution cd
WHERE public.profiles.user_id = cd.user_id;

-- 14. Vérifications finales
SELECT 'ENTREPRISES CRÉÉES' as info;
SELECT id, name, status FROM public.companies ORDER BY id;

SELECT 'UTILISATEURS PAR ENTREPRISE' as info;
SELECT 
    c.name as entreprise,
    p.role as role,
    COUNT(*) as nombre_utilisateurs
FROM public.profiles p
LEFT JOIN public.companies c ON p.company_id = c.id
GROUP BY c.name, p.role
ORDER BY c.name, p.role;

SELECT 'STRUCTURE FINALE PROFILES' as info;
SELECT 
    column_name,
    data_type,
    CASE 
        WHEN column_name = 'company_id' THEN '🏢 NOUVEAU - Entreprise'
        WHEN column_name IN ('user_id', 'email', 'role') THEN '✅ Requis'
        ELSE '📝 Optionnel'
    END as status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'profiles'
ORDER BY ordinal_position;

-- Message final
SELECT '✅ Multi-tenancy par entreprise configuré avec succès !' as result; 