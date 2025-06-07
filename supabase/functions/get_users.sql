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
    p.user_id,
    au.email,
    p.first_name,
    p.last_name,
    p.phone,
    p.role,
    p.status,
    p.created_at,
    p.updated_at
  FROM profiles p
  JOIN auth.users au ON p.user_id = au.id
  ORDER BY p.created_at DESC;
END;
$$; 