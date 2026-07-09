-- ============================================================================
-- RLS — tables restantes (complète 20260709120000_rls_policies.sql)
-- Même modèle : staff = tout ; sinon restriction par auth.uid() / company_id.
-- Idempotente (drop policy if exists avant chaque create).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- INVESTOR_GROUP + USER_ROLES + CLIENTS + PROJECTS : back-office staff ;
-- lecture investor_group ouverte aux membres d'une société du groupe.
-- ----------------------------------------------------------------------------
alter table public.investor_group enable row level security;

drop policy if exists ig_select on public.investor_group;
create policy ig_select on public.investor_group
  for select using (
    public.is_staff()
    or id = (select group_id from public.company
             where id = public.current_user_company_id())
  );

drop policy if exists ig_write_staff on public.investor_group;
create policy ig_write_staff on public.investor_group
  for all using (public.is_staff()) with check (public.is_staff());

alter table public.user_roles enable row level security;

drop policy if exists ur_select on public.user_roles;
create policy ur_select on public.user_roles
  for select using (user_id = auth.uid() or public.is_staff());

drop policy if exists ur_write_staff on public.user_roles;
create policy ur_write_staff on public.user_roles
  for all using (public.is_staff()) with check (public.is_staff());

alter table public.clients enable row level security;

drop policy if exists clients_staff on public.clients;
create policy clients_staff on public.clients
  for all using (public.is_staff()) with check (public.is_staff());

alter table public.projects enable row level security;

drop policy if exists projects_select on public.projects;
create policy projects_select on public.projects
  for select using (
    public.is_staff()
    or client_id = auth.uid()
    or assigned_to = auth.uid()
  );

drop policy if exists projects_write_staff on public.projects;
create policy projects_write_staff on public.projects
  for all using (public.is_staff()) with check (public.is_staff());

-- ----------------------------------------------------------------------------
-- TASKS : staff ; partenaire assigné à la tâche ou à la mission parente.
-- ----------------------------------------------------------------------------
alter table public.tasks enable row level security;

-- NB : qualifier tasks.mission_id est indispensable — missions possède aussi
-- une colonne mission_id (auto-référence), qui capturerait la résolution.
drop policy if exists tasks_select on public.tasks;
create policy tasks_select on public.tasks
  for select using (
    public.is_staff()
    or assigned_to = auth.uid()
    or exists (select 1 from public.missions m
               where m.id = tasks.mission_id
                 and (m.partner_id = auth.uid() or m.assigned_to = auth.uid()))
  );

drop policy if exists tasks_update on public.tasks;
create policy tasks_update on public.tasks
  for update using (
    public.is_staff()
    or assigned_to = auth.uid()
    or exists (select 1 from public.missions m
               where m.id = tasks.mission_id
                 and (m.partner_id = auth.uid() or m.assigned_to = auth.uid()))
  );

drop policy if exists tasks_write_staff on public.tasks;
create policy tasks_write_staff on public.tasks
  for insert with check (public.is_staff());

drop policy if exists tasks_delete_staff on public.tasks;
create policy tasks_delete_staff on public.tasks
  for delete using (public.is_staff());

-- ----------------------------------------------------------------------------
-- MISSION_PROPOSALS / MISSION_ASSIGNMENTS / MISSION_CRITERIA
-- ----------------------------------------------------------------------------
alter table public.mission_proposals enable row level security;

drop policy if exists mp_select on public.mission_proposals;
create policy mp_select on public.mission_proposals
  for select using (public.is_staff() or partner_id = auth.uid());

drop policy if exists mp_insert_staff on public.mission_proposals;
create policy mp_insert_staff on public.mission_proposals
  for insert with check (public.is_staff());

drop policy if exists mp_update on public.mission_proposals;
create policy mp_update on public.mission_proposals
  for update using (public.is_staff() or partner_id = auth.uid());

alter table public.mission_assignments enable row level security;

drop policy if exists ma_select on public.mission_assignments;
create policy ma_select on public.mission_assignments
  for select using (
    public.is_staff() or assigned_to = auth.uid() or assigned_by = auth.uid());

drop policy if exists ma_insert_staff on public.mission_assignments;
create policy ma_insert_staff on public.mission_assignments
  for insert with check (public.is_staff());

drop policy if exists ma_update on public.mission_assignments;
create policy ma_update on public.mission_assignments
  for update using (
    public.is_staff() or assigned_to = auth.uid());

alter table public.mission_criteria enable row level security;

drop policy if exists mc_staff on public.mission_criteria;
create policy mc_staff on public.mission_criteria
  for all using (public.is_staff()) with check (public.is_staff());

-- ----------------------------------------------------------------------------
-- PARTNER_PROFILES / PARTNER_AVAILABILITY
-- ----------------------------------------------------------------------------
alter table public.partner_profiles enable row level security;

drop policy if exists pp_select on public.partner_profiles;
create policy pp_select on public.partner_profiles
  for select using (public.is_staff() or user_id = auth.uid());

drop policy if exists pp_insert_own on public.partner_profiles;
create policy pp_insert_own on public.partner_profiles
  for insert with check (user_id = auth.uid() or public.is_staff());

drop policy if exists pp_update_own on public.partner_profiles;
create policy pp_update_own on public.partner_profiles
  for update using (user_id = auth.uid() or public.is_staff());

alter table public.partner_availability enable row level security;

drop policy if exists pa_select on public.partner_availability;
create policy pa_select on public.partner_availability
  for select using (public.is_staff() or partner_id = auth.uid());

drop policy if exists pa_write_own on public.partner_availability;
create policy pa_write_own on public.partner_availability
  for all using (public.is_staff() or partner_id = auth.uid())
  with check (public.is_staff() or partner_id = auth.uid());

-- ----------------------------------------------------------------------------
-- CLIENT_REQUESTS : client = les siennes ; staff = tout.
-- ----------------------------------------------------------------------------
alter table public.client_requests enable row level security;

drop policy if exists cr_select on public.client_requests;
create policy cr_select on public.client_requests
  for select using (public.is_staff() or client_id = auth.uid());

drop policy if exists cr_insert on public.client_requests;
create policy cr_insert on public.client_requests
  for insert with check (client_id = auth.uid() or public.is_staff());

drop policy if exists cr_update_staff on public.client_requests;
create policy cr_update_staff on public.client_requests
  for update using (public.is_staff());

-- ----------------------------------------------------------------------------
-- MESSAGERIE : participants uniquement.
-- ----------------------------------------------------------------------------
alter table public.conversations enable row level security;

drop policy if exists conv_select on public.conversations;
create policy conv_select on public.conversations
  for select using (
    public.is_staff()
    or exists (select 1 from public.conversation_participants cp
               where cp.conversation_id = id and cp.user_id = auth.uid())
  );

drop policy if exists conv_insert on public.conversations;
create policy conv_insert on public.conversations
  for insert with check (auth.uid() is not null);

alter table public.conversation_participants enable row level security;

drop policy if exists cp_select on public.conversation_participants;
create policy cp_select on public.conversation_participants
  for select using (
    public.is_staff()
    or user_id = auth.uid()
    or exists (select 1 from public.conversation_participants me
               where me.conversation_id = conversation_participants.conversation_id
                 and me.user_id = auth.uid())
  );

drop policy if exists cp_insert on public.conversation_participants;
create policy cp_insert on public.conversation_participants
  for insert with check (auth.uid() is not null);

alter table public.messages enable row level security;

drop policy if exists msg_select on public.messages;
create policy msg_select on public.messages
  for select using (
    exists (select 1 from public.conversation_participants cp
            where cp.conversation_id = messages.conversation_id
              and cp.user_id = auth.uid())
  );

drop policy if exists msg_insert on public.messages;
create policy msg_insert on public.messages
  for insert with check (
    sender_id = auth.uid()
    and exists (select 1 from public.conversation_participants cp
                where cp.conversation_id = messages.conversation_id
                  and cp.user_id = auth.uid())
  );

drop policy if exists msg_update on public.messages;
create policy msg_update on public.messages
  for update using (
    exists (select 1 from public.conversation_participants cp
            where cp.conversation_id = messages.conversation_id
              and cp.user_id = auth.uid())
  );

-- ----------------------------------------------------------------------------
-- NOTIFICATIONS : chacun les siennes ; création via RPC (security definer).
-- ----------------------------------------------------------------------------
alter table public.notifications enable row level security;

drop policy if exists notif_select on public.notifications;
create policy notif_select on public.notifications
  for select using (auth.uid() is not null);

drop policy if exists notif_write_staff on public.notifications;
create policy notif_write_staff on public.notifications
  for all using (public.is_staff()) with check (public.is_staff());

alter table public.user_notifications enable row level security;

drop policy if exists un_select_own on public.user_notifications;
create policy un_select_own on public.user_notifications
  for select using (user_id = auth.uid() or public.is_staff());

drop policy if exists un_update_own on public.user_notifications;
create policy un_update_own on public.user_notifications
  for update using (user_id = auth.uid() or public.is_staff());

drop policy if exists un_insert_staff on public.user_notifications;
create policy un_insert_staff on public.user_notifications
  for insert with check (public.is_staff());

-- ----------------------------------------------------------------------------
-- CALENDAR_EVENTS : chacun les siens ; staff = tout.
-- ----------------------------------------------------------------------------
alter table public.calendar_events enable row level security;

drop policy if exists ce_select on public.calendar_events;
create policy ce_select on public.calendar_events
  for select using (public.is_staff() or user_id = auth.uid());

drop policy if exists ce_write_own on public.calendar_events;
create policy ce_write_own on public.calendar_events
  for all using (public.is_staff() or user_id = auth.uid())
  with check (public.is_staff() or user_id = auth.uid());
