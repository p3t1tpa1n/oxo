-- Structure de base pour la table profiles
-- DROP TABLE IF EXISTS public.profiles;

-- Créer la table profiles si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users(id),
    email text,
    first_name text,
    last_name text,
    phone text,
    role text DEFAULT 'client',
    status text DEFAULT 'actif',
    created_at timestamptz DEFAULT NOW(),
    updated_at timestamptz DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Mise à jour des valeurs par défaut (assure les defaults si non présents)
ALTER TABLE public.profiles
    ALTER COLUMN role SET DEFAULT 'client',
    ALTER COLUMN status SET DEFAULT 'actif',
    ALTER COLUMN created_at SET DEFAULT NOW(),
    ALTER COLUMN updated_at SET DEFAULT NOW();

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS profiles_user_id_idx ON profiles(user_id);
CREATE INDEX IF NOT EXISTS profiles_email_idx ON profiles(email);
CREATE INDEX IF NOT EXISTS profiles_role_idx ON profiles(role);

-- Politiques de sécurité pour profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS "Tout le monde peut lire les profils" ON public.profiles;
DROP POLICY IF EXISTS "Les utilisateurs peuvent modifier leur propre profil" ON public.profiles;
DROP POLICY IF EXISTS "Seuls les administrateurs peuvent créer des profils" ON public.profiles;
DROP POLICY IF EXISTS "Seuls les administrateurs peuvent supprimer des profils" ON public.profiles;

-- Politique de lecture
CREATE POLICY "Tout le monde peut lire les profils"
ON public.profiles FOR SELECT
TO authenticated
USING (true);

-- Politique de mise à jour
CREATE POLICY "Les utilisateurs peuvent modifier leur propre profil"
ON public.profiles FOR UPDATE
TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Politique d'insertion (restreinte aux administrateurs)
CREATE POLICY "Seuls les administrateurs peuvent créer des profils"
ON public.profiles FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'admin'
    )
);

-- Politique de suppression (restreinte aux administrateurs)
CREATE POLICY "Seuls les administrateurs peuvent supprimer des profils"
ON public.profiles FOR DELETE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM profiles
        WHERE user_id = auth.uid()
        AND role = 'admin'
    )
);

-- Supprimer la fonction existante
DROP FUNCTION IF EXISTS get_users();

-- Fonction pour obtenir la liste des utilisateurs
CREATE OR REPLACE FUNCTION get_users()
RETURNS TABLE (
    user_id uuid,
    email text,
    first_name text,
    last_name text,
    phone text,
    user_role text,
    status text,
    created_at timestamptz,
    updated_at timestamptz
) LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.user_id,
        CAST(au.email AS text)  AS email,
        CAST(p.first_name AS text) AS first_name,
        CAST(p.last_name  AS text) AS last_name,
        CAST(p.phone      AS text) AS phone,
        CAST(p.role AS text) AS user_role,
        CAST(p.status     AS text) AS status,
        p.created_at,
        p.updated_at
    FROM auth.users au
    JOIN public.profiles p ON p.user_id = au.id
    WHERE au.deleted_at IS NULL
    ORDER BY p.created_at DESC;
END;
$$;

-- Insérer le premier utilisateur admin s'il n'existe pas déjà
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE role = 'admin'
    ) THEN
        INSERT INTO public.profiles (
            user_id,
            email,
            first_name,
            last_name,
            role,
            status
        )
        SELECT
            id,
            email,
            'Admin',
            'System',
            'admin',
            'actif'
        FROM auth.users
        WHERE email = 'admin@gmail.com'
        AND NOT EXISTS (
            SELECT 1 FROM public.profiles WHERE user_id = auth.users.id
        );
    END IF;
END
$$; 