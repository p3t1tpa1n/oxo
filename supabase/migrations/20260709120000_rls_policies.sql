-- ============================================================================
-- RLS — Row Level Security par rôle (admin, associe, partenaire, client)
--
-- Prérequis : avoir capturé le schéma live comme baseline (supabase db pull).
-- Cette migration est idempotente (DROP POLICY IF EXISTS avant chaque CREATE).
--
-- Modèle de rôles (colonne profiles.role) :
--   admin / associe  : back-office complet du cabinet
--   partenaire       : consultant — ne voit que ce qui lui est assigné
--   client           : ne voit que les données de sa propre entreprise
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Fonctions utilitaires (SECURITY DEFINER pour éviter la récursion RLS
-- lors de la lecture de profiles depuis une policy).
-- ----------------------------------------------------------------------------

create or replace function public.current_user_role()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select lower(role) from public.profiles where user_id = auth.uid();
$$;

create or replace function public.current_user_company_id()
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select company_id from public.profiles where user_id = auth.uid();
$$;

create or replace function public.is_staff()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_user_role() in ('admin', 'associe', 'associé');
$$;

-- ----------------------------------------------------------------------------
-- PROFILES
-- Lecture : soi-même + staff ; les partenaires/clients ne listent pas les autres.
-- Écriture : uniquement le staff (le rôle ne doit JAMAIS être modifiable par
-- son propriétaire) ; la création passe par l'Edge Function (service_role).
-- ----------------------------------------------------------------------------
alter table public.profiles enable row level security;

drop policy if exists profiles_select_own on public.profiles;
create policy profiles_select_own on public.profiles
  for select using (user_id = auth.uid() or public.is_staff());

drop policy if exists profiles_update_own on public.profiles;
create policy profiles_update_own on public.profiles
  for update using (user_id = auth.uid() or public.is_staff())
  with check (
    -- un non-staff ne peut pas changer son rôle ni son entreprise
    public.is_staff()
    or (role = (select role from public.profiles p where p.user_id = auth.uid())
        and company_id is not distinct from public.current_user_company_id())
  );

drop policy if exists profiles_insert_staff on public.profiles;
create policy profiles_insert_staff on public.profiles
  for insert with check (public.is_staff());

drop policy if exists profiles_delete_staff on public.profiles;
create policy profiles_delete_staff on public.profiles
  for delete using (public.current_user_role() = 'admin');

-- ----------------------------------------------------------------------------
-- COMPANY
-- ----------------------------------------------------------------------------
alter table public.company enable row level security;

drop policy if exists company_select on public.company;
create policy company_select on public.company
  for select using (
    public.is_staff()
    or id = public.current_user_company_id()
  );

drop policy if exists company_write_staff on public.company;
create policy company_write_staff on public.company
  for all using (public.is_staff()) with check (public.is_staff());

-- ----------------------------------------------------------------------------
-- MISSIONS
-- staff : tout ; partenaire : missions qui lui sont assignées ;
-- client : missions de son entreprise.
-- ----------------------------------------------------------------------------
alter table public.missions enable row level security;

drop policy if exists missions_select on public.missions;
create policy missions_select on public.missions
  for select using (
    public.is_staff()
    or partner_id = auth.uid()
    or assigned_to = auth.uid()
    or company_id = public.current_user_company_id()
  );

drop policy if exists missions_write_staff on public.missions;
create policy missions_write_staff on public.missions
  for insert with check (public.is_staff());

drop policy if exists missions_update on public.missions;
create policy missions_update on public.missions
  for update using (
    public.is_staff()
    -- un partenaire peut mettre à jour l'avancement de SES missions
    or partner_id = auth.uid()
    or assigned_to = auth.uid()
  );

drop policy if exists missions_delete_staff on public.missions;
create policy missions_delete_staff on public.missions
  for delete using (public.is_staff());

-- ----------------------------------------------------------------------------
-- INVOICES
-- staff : tout ; client : uniquement ses propres factures.
-- Les partenaires ne voient pas la facturation.
-- ----------------------------------------------------------------------------
alter table public.invoices enable row level security;

drop policy if exists invoices_select on public.invoices;
create policy invoices_select on public.invoices
  for select using (
    public.is_staff()
    or client_user_id = auth.uid()
  );

drop policy if exists invoices_write_staff on public.invoices;
create policy invoices_write_staff on public.invoices
  for all using (public.is_staff()) with check (public.is_staff());

-- ----------------------------------------------------------------------------
-- TIMESHEET_ENTRIES
-- staff : tout ; partenaire : ses propres saisies uniquement.
-- ----------------------------------------------------------------------------
alter table public.timesheet_entries enable row level security;

drop policy if exists timesheet_select on public.timesheet_entries;
create policy timesheet_select on public.timesheet_entries
  for select using (
    public.is_staff()
    or partner_id = auth.uid()
    or user_id = auth.uid()
  );

drop policy if exists timesheet_insert_own on public.timesheet_entries;
create policy timesheet_insert_own on public.timesheet_entries
  for insert with check (
    public.is_staff()
    or partner_id = auth.uid()
    or user_id = auth.uid()
  );

drop policy if exists timesheet_update_own on public.timesheet_entries;
create policy timesheet_update_own on public.timesheet_entries
  for update using (
    public.is_staff()
    or ((partner_id = auth.uid() or user_id = auth.uid())
        and status = 'draft')  -- une saisie soumise n'est plus modifiable
  );

drop policy if exists timesheet_delete_own on public.timesheet_entries;
create policy timesheet_delete_own on public.timesheet_entries
  for delete using (
    public.is_staff()
    or ((partner_id = auth.uid() or user_id = auth.uid())
        and status = 'draft')
  );

-- ----------------------------------------------------------------------------
-- PARTNER_RATES — tarifs : staff uniquement (un partenaire ne voit que les siens)
-- ----------------------------------------------------------------------------
alter table public.partner_rates enable row level security;

drop policy if exists rates_select on public.partner_rates;
create policy rates_select on public.partner_rates
  for select using (public.is_staff() or partner_id = auth.uid());

drop policy if exists rates_write_staff on public.partner_rates;
create policy rates_write_staff on public.partner_rates
  for all using (public.is_staff()) with check (public.is_staff());

-- ----------------------------------------------------------------------------
-- PARTNER_CLIENT_PERMISSIONS — staff uniquement en écriture
-- ----------------------------------------------------------------------------
alter table public.partner_client_permissions enable row level security;

drop policy if exists pcp_select on public.partner_client_permissions;
create policy pcp_select on public.partner_client_permissions
  for select using (public.is_staff() or partner_id = auth.uid());

drop policy if exists pcp_write_staff on public.partner_client_permissions;
create policy pcp_write_staff on public.partner_client_permissions
  for all using (public.is_staff()) with check (public.is_staff());

-- ----------------------------------------------------------------------------
-- PROJECT_PROPOSALS + DOCUMENTS — client : les siennes ; staff : toutes
-- ----------------------------------------------------------------------------
alter table public.project_proposals enable row level security;

drop policy if exists proposals_select on public.project_proposals;
create policy proposals_select on public.project_proposals
  for select using (
    public.is_staff()
    or client_id = auth.uid()
  );

drop policy if exists proposals_insert_client on public.project_proposals;
create policy proposals_insert_client on public.project_proposals
  for insert with check (client_id = auth.uid() or public.is_staff());

drop policy if exists proposals_update_staff on public.project_proposals;
create policy proposals_update_staff on public.project_proposals
  for update using (public.is_staff());

alter table public.project_proposal_documents enable row level security;

drop policy if exists proposal_docs_select on public.project_proposal_documents;
create policy proposal_docs_select on public.project_proposal_documents
  for select using (
    public.is_staff()
    or exists (
      select 1 from public.project_proposals p
      where p.id = proposal_id and p.client_id = auth.uid()
    )
  );

drop policy if exists proposal_docs_insert on public.project_proposal_documents;
create policy proposal_docs_insert on public.project_proposal_documents
  for insert with check (
    public.is_staff()
    or exists (
      select 1 from public.project_proposals p
      where p.id = proposal_id and p.client_id = auth.uid()
    )
  );

-- ----------------------------------------------------------------------------
-- TIME_EXTENSION_REQUESTS
-- ----------------------------------------------------------------------------
alter table public.time_extension_requests enable row level security;

drop policy if exists ter_select on public.time_extension_requests;
create policy ter_select on public.time_extension_requests
  for select using (public.is_staff() or client_id = auth.uid());

drop policy if exists ter_insert_client on public.time_extension_requests;
create policy ter_insert_client on public.time_extension_requests
  for insert with check (client_id = auth.uid() or public.is_staff());

drop policy if exists ter_update_staff on public.time_extension_requests;
create policy ter_update_staff on public.time_extension_requests
  for update using (public.is_staff());

-- ----------------------------------------------------------------------------
-- COMMERCIAL_ACTIONS — staff + partenaire concerné
-- ----------------------------------------------------------------------------
alter table public.commercial_actions enable row level security;

drop policy if exists ca_select on public.commercial_actions;
create policy ca_select on public.commercial_actions
  for select using (
    public.is_staff()
    or created_by = auth.uid()
    or assigned_to = auth.uid()
    or partner_id = auth.uid()
  );

drop policy if exists ca_insert on public.commercial_actions;
create policy ca_insert on public.commercial_actions
  for insert with check (public.is_staff() or created_by = auth.uid());

drop policy if exists ca_update on public.commercial_actions;
create policy ca_update on public.commercial_actions
  for update using (
    public.is_staff()
    or created_by = auth.uid()
    or assigned_to = auth.uid()
    or partner_id = auth.uid()
  );

drop policy if exists ca_delete on public.commercial_actions;
create policy ca_delete on public.commercial_actions
  for delete using (public.is_staff() or created_by = auth.uid());

-- ============================================================================
-- NOTES D'APPLICATION
--
-- 1. Types des colonnes : toutes les colonnes d'identifiant utilisateur sont
--    des uuid (cf. 20260709100000_initial_schema.sql) — comparaison directe
--    avec auth.uid(), les index sont utilisables.
-- 2. Les tables restantes (mission_proposals, mission_assignments,
--    notifications, partner_profiles, partner_availability, tasks,
--    calendar_events, messages, mission_criteria…) sont couvertes par
--    20260709130000_rls_remaining.sql.
-- 3. Vues (user_company_info, invoice_details, company_with_group,
--    timesheet_entries_detailed) : les recréer avec `security_invoker = true`
--    pour qu'elles respectent la RLS des tables sous-jacentes :
--      alter view public.user_company_info set (security_invoker = true);
-- 4. Storage : le bucket `documents` doit être PRIVÉ. Le code utilisait
--    getPublicUrl — remplacé côté Flutter par createSignedUrl. Policies :
--      insert : dossier préfixé par auth.uid()
--      select : staff ou propriétaire du dossier
-- ============================================================================
