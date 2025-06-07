-- Supprimer la fonction existante
DROP FUNCTION IF EXISTS get_users();

-- Recréer la fonction avec la nouvelle structure
CREATE OR REPLACE FUNCTION get_users()
RETURNS TABLE (
  user_id uuid,
  email text,
  first_name text,
  last_name text,
  phone text,
  role text,
  status text,
  created_at timestamptz,
  updated_at timestamptz
) LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    COALESCE(p.user_id, au.id) as user_id,
    au.email,
    p.first_name,
    p.last_name,
    p.phone,
    COALESCE(p.role, 'client') as role,
    COALESCE(p.status, 'actif') as status,
    COALESCE(p.created_at, au.created_at) as created_at,
    COALESCE(p.updated_at, au.created_at) as updated_at
  FROM auth.users au
  LEFT JOIN profiles p ON p.user_id = au.id
  WHERE au.deleted_at IS NULL
  ORDER BY COALESCE(p.created_at, au.created_at) DESC;
END;
$$; 