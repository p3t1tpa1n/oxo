-- ============================================================================
-- FIX — Messagerie vide pour les clients et partenaires
--
-- get_users() ne renvoyait aux non-staff que leur propre ligne ; la page
-- Messages exclut l'utilisateur courant → liste de destinataires vide.
-- Règle métier (messaging_page.dart) : clients et partenaires ne peuvent
-- écrire qu'aux associés/admins → ils doivent donc pouvoir VOIR le staff.
-- ============================================================================

create or replace function public.get_users()
returns table (id uuid, user_id uuid, email text, first_name text,
               last_name text, role text, user_role text, company_id bigint)
language sql stable security definer set search_path = public as $$
  select p.id, p.user_id, p.email, p.first_name, p.last_name,
         p.role, p.role as user_role, p.company_id
  from profiles p
  where is_staff()                                        -- le staff voit tout
     or p.user_id = auth.uid()                            -- chacun se voit
     or lower(p.role) in ('associe', 'associé', 'admin'); -- tous voient le staff
$$;
