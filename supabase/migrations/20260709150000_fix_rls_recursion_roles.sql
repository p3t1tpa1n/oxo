-- ============================================================================
-- Correctifs détectés au premier test multi-rôles :
-- 1. Récursion infinie (42P17) : la policy de conversation_participants se
--    référençait elle-même. On passe par une fonction SECURITY DEFINER.
-- 2. get_users() ne renvoyait rien aux non-staff, or le client Flutter s'en
--    sert pour résoudre le rôle à la connexion → chaque utilisateur doit au
--    minimum voir sa propre ligne.
-- ============================================================================

-- ── 1. Anti-récursion : appartenance à une conversation ─────────────────────
create or replace function public.is_conversation_member(p_conversation uuid)
returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from conversation_participants
    where conversation_id = p_conversation and user_id = auth.uid());
$$;

drop policy if exists cp_select on public.conversation_participants;
create policy cp_select on public.conversation_participants
  for select using (
    public.is_staff()
    or user_id = auth.uid()
    or public.is_conversation_member(conversation_id)
  );

drop policy if exists conv_select on public.conversations;
create policy conv_select on public.conversations
  for select using (public.is_staff() or public.is_conversation_member(id));

drop policy if exists msg_select on public.messages;
create policy msg_select on public.messages
  for select using (public.is_conversation_member(conversation_id));

drop policy if exists msg_insert on public.messages;
create policy msg_insert on public.messages
  for insert with check (
    sender_id = auth.uid() and public.is_conversation_member(conversation_id));

drop policy if exists msg_update on public.messages;
create policy msg_update on public.messages
  for update using (public.is_conversation_member(conversation_id));

-- ── 1bis. company_with_group : exposer les timestamps attendus par le client ─
create or replace view public.company_with_group
with (security_invoker = true) as
  select c.id, c.name, c.name as company_name, c.city, c.sector, c.country,
         c.ownership_share, c.is_active as company_active,
         g.id as group_id, g.name as group_name, g.sector as group_sector,
         c.created_at, c.updated_at
  from public.company c
  left join public.investor_group g on g.id = c.group_id;

-- ── 2. get_users : chacun voit au moins sa propre ligne ──────────────────────
create or replace function public.get_users()
returns table (id uuid, user_id uuid, email text, first_name text,
               last_name text, role text, user_role text, company_id bigint)
language sql stable security definer set search_path = public as $$
  select p.id, p.user_id, p.email, p.first_name, p.last_name,
         p.role, p.role as user_role, p.company_id
  from profiles p
  where is_staff() or p.user_id = auth.uid();
$$;
