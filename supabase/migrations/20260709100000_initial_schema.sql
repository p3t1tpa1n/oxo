-- ============================================================================
-- OXO — Schéma initial complet (baseline)
--
-- Reconstruit depuis le code Flutter (lib/services, lib/models, lib/pages).
-- À appliquer AVANT 20260709120000_rls_policies.sql.
--
-- Conventions :
--   - Identifiants utilisateurs : uuid (référencent auth.users).
--   - Identifiants sociétés (company/investor_group) : bigint identity.
--   - Toutes les tables ont created_at ; updated_at maintenu par trigger.
--
-- Dettes du code résolues ici (voir supabase/README.md) :
--   1. `company` vs `companies` : une seule table physique `company` ;
--      `companies` est une VUE updatable dessus (les deux noms fonctionnent).
--   2. `timesheet_entries` : deux conventions (`date`+`hours` et
--      `entry_date`+`days`) — les deux colonnes existent, un trigger copie
--      `date` -> `entry_date` pour unifier le reporting.
-- ============================================================================

create extension if not exists pgcrypto;

-- ----------------------------------------------------------------------------
-- Fonctions utilitaires de rôle (redéfinies à l'identique par la migration
-- RLS — présentes ici car les vues, RPC et policies storage y font référence).
-- Déclarées avant les tables ; les corps SQL ne sont pas validés à la
-- création (check_function_bodies off ci-dessous).
-- ----------------------------------------------------------------------------
set check_function_bodies = off;

create or replace function public.current_user_role()
returns text language sql stable security definer set search_path = public as $$
  select lower(role) from public.profiles where user_id = auth.uid();
$$;

create or replace function public.current_user_company_id()
returns bigint language sql stable security definer set search_path = public as $$
  select company_id from public.profiles where user_id = auth.uid();
$$;

create or replace function public.is_staff()
returns boolean language sql stable security definer set search_path = public as $$
  select public.current_user_role() in ('admin', 'associe', 'associé');
$$;

-- ----------------------------------------------------------------------------
-- Trigger générique updated_at
-- ----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

-- ============================================================================
-- 1. RÉFÉRENTIEL SOCIÉTÉS
-- ============================================================================

create table if not exists public.investor_group (
  id           bigint generated always as identity primary key,
  name         text not null,
  sector       text,
  country      text,
  contact_main text,
  created_at   timestamptz not null default now()
);

create table if not exists public.company (
  id              bigint generated always as identity primary key,
  name            text not null,
  group_id        bigint references public.investor_group(id) on delete set null,
  city            text,
  sector          text,
  country         text,
  contact_main    text,
  ownership_share numeric,
  -- colonnes utilisées via la vue `companies` (company_service.dart)
  description     text,
  address         text,
  phone           text,
  email           text,
  website         text,
  status          text not null default 'active',
  is_active       boolean not null default true,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create trigger trg_company_updated before update on public.company
  for each row execute function public.set_updated_at();

-- Vue updatable : le code écrit tantôt dans `company`, tantôt dans `companies`.
create or replace view public.companies
with (security_invoker = true) as
  select id, name, description, address, phone, email, website,
         status, group_id, city, sector, country, contact_main,
         ownership_share, is_active, created_at, updated_at
  from public.company;

-- ============================================================================
-- 2. UTILISATEURS
-- ============================================================================

create table if not exists public.profiles (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null unique references auth.users(id) on delete cascade,
  email      text,
  first_name text,
  last_name  text,
  role       text not null default 'client'
             check (lower(role) in ('admin','associe','associé','partenaire','client')),
  company_id bigint references public.company(id) on delete set null,
  status     text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create trigger trg_profiles_updated before update on public.profiles
  for each row execute function public.set_updated_at();

-- Table héritée, encore lue par supabase_service.dart (company_id, role)
create table if not exists public.user_roles (
  id         bigint generated always as identity primary key,
  user_id    uuid not null unique references auth.users(id) on delete cascade,
  partner_id uuid references auth.users(id) on delete set null,
  role       text not null default 'client',
  company_id bigint references public.company(id) on delete set null,
  status     text not null default 'active',
  created_at timestamptz not null default now()
);

-- Contacts clients (CRM léger — supabase_service.dart)
create table if not exists public.clients (
  id         uuid primary key default gen_random_uuid(),
  first_name text,
  last_name  text,
  email      text,
  phone      text,
  company_id bigint references public.company(id) on delete set null,
  status     text not null default 'active',
  created_at timestamptz not null default now()
);

-- ============================================================================
-- 3. PROJETS / MISSIONS
-- ============================================================================

create table if not exists public.projects (
  id             uuid primary key default gen_random_uuid(),
  name           text not null,
  description    text,
  status         text not null default 'active',
  client_id      uuid references auth.users(id) on delete set null,
  assigned_to    uuid references auth.users(id) on delete set null,
  estimated_days numeric,
  daily_rate     numeric,
  start_date     timestamptz,
  end_date       timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create trigger trg_projects_updated before update on public.projects
  for each row execute function public.set_updated_at();

create table if not exists public.missions (
  id                    uuid primary key default gen_random_uuid(),
  title                 text not null,
  description           text,
  company_id            bigint references public.company(id) on delete set null,
  project_id            uuid references public.projects(id) on delete set null,
  mission_id            uuid references public.missions(id) on delete cascade, -- sous-mission -> parent
  partner_id            uuid references auth.users(id) on delete set null,
  assigned_to           uuid references auth.users(id) on delete set null,
  client_id             uuid references auth.users(id) on delete set null,
  start_date            date not null default current_date,
  end_date              date,
  status                text not null default 'draft',
  progress_status       text,
  priority              text,
  budget                numeric,
  daily_rate            numeric,
  monthly_cap           numeric,
  referral_fee          numeric,
  referral_fee_type     text check (referral_fee_type in ('fixed','percentage') or referral_fee_type is null),
  currency              text not null default 'EUR',
  estimated_days        numeric,
  worked_days           numeric,
  completion_percentage numeric,
  notes                 text,
  created_at            timestamptz not null default now(),
  updated_at            timestamptz not null default now()
);
create trigger trg_missions_updated before update on public.missions
  for each row execute function public.set_updated_at();

create table if not exists public.tasks (
  id          uuid primary key default gen_random_uuid(),
  mission_id  uuid references public.missions(id) on delete cascade,
  title       text not null,
  description text,
  status      text not null default 'pending',
  assigned_to uuid references auth.users(id) on delete set null,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create trigger trg_tasks_updated before update on public.tasks
  for each row execute function public.set_updated_at();

create table if not exists public.mission_proposals (
  id              uuid primary key default gen_random_uuid(),
  mission_id      uuid not null references public.missions(id) on delete cascade,
  partner_id      uuid not null references auth.users(id) on delete cascade,
  status          text not null default 'pending',
  progress_status text,
  response_at     timestamptz,
  response_notes  text,
  created_at      timestamptz not null default now()
);

create table if not exists public.mission_assignments (
  id               uuid primary key default gen_random_uuid(),
  mission_id       uuid references public.missions(id) on delete cascade,
  task_id          uuid references public.tasks(id) on delete set null,
  assigned_to      uuid not null references auth.users(id) on delete cascade,
  assigned_by      uuid references auth.users(id) on delete set null,
  message          text,
  priority         text,
  deadline         timestamptz,
  status           text not null default 'pending',
  accepted_at      timestamptz,
  rejected_at      timestamptz,
  partner_response text,
  created_at       timestamptz not null default now()
);

-- Critères de recherche de partenaire (find_best_partners_for_mission)
create table if not exists public.mission_criteria (
  id               uuid primary key default gen_random_uuid(),
  mission_id       uuid references public.missions(id) on delete cascade,
  activity_domains text[] not null default '{}',
  languages        text[] not null default '{}',
  career_paths     text[] not null default '{}',
  main_functions   text[] not null default '{}',
  criteria         jsonb,
  created_at       timestamptz not null default now()
);

-- ============================================================================
-- 4. PARTENAIRES
-- ============================================================================

create table if not exists public.partner_profiles (
  id                       uuid primary key default gen_random_uuid(),
  user_id                  uuid not null unique references auth.users(id) on delete cascade,
  civility                 text,
  first_name               text,
  last_name                text,
  email                    text,
  phone                    text,
  birth_date               date,
  address                  text,
  postal_code              text,
  city                     text,
  company_name             text,
  legal_form               text,
  capital                  text,
  company_address          text,
  company_postal_code      text,
  company_city             text,
  rcs                      text,
  siren                    text,
  representative_name      text,
  representative_title     text,
  activity_domains         text[] not null default '{}',
  languages                text[] not null default '{}',
  diplomas                 text[] not null default '{}',
  career_paths             text[] not null default '{}',
  main_functions           text[] not null default '{}',
  professional_experiences jsonb not null default '[]',
  questionnaire_completed  boolean not null default false,
  completed_at             timestamptz,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now()
);
create trigger trg_partner_profiles_updated before update on public.partner_profiles
  for each row execute function public.set_updated_at();

create table if not exists public.partner_availability (
  id                    uuid primary key default gen_random_uuid(),
  partner_id            uuid not null references auth.users(id) on delete cascade,
  date                  date not null,
  status                text not null default 'available',
  is_available          boolean not null default true,
  availability_type     text,
  start_time            time,
  end_time              time,
  notes                 text,
  unavailability_reason text,
  company_id            bigint references public.company(id) on delete set null,
  created_at            timestamptz not null default now(),
  unique (partner_id, date)
);

create table if not exists public.partner_rates (
  id         bigint generated always as identity primary key,
  partner_id uuid not null references auth.users(id) on delete cascade,
  company_id bigint not null references public.company(id) on delete cascade,
  daily_rate numeric not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (partner_id, company_id)
);
create trigger trg_partner_rates_updated before update on public.partner_rates
  for each row execute function public.set_updated_at();

-- client_id = société cliente (company.id)
create table if not exists public.partner_client_permissions (
  id         bigint generated always as identity primary key,
  partner_id uuid not null references auth.users(id) on delete cascade,
  client_id  bigint not null references public.company(id) on delete cascade,
  allowed    boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (partner_id, client_id)
);
create trigger trg_pcp_updated before update on public.partner_client_permissions
  for each row execute function public.set_updated_at();

-- ============================================================================
-- 5. FEUILLES DE TEMPS
-- ============================================================================

create table if not exists public.timesheet_entries (
  id          uuid primary key default gen_random_uuid(),
  partner_id  uuid references auth.users(id) on delete set null,
  user_id     uuid references auth.users(id) on delete set null,
  mission_id  uuid references public.missions(id) on delete set null,
  task_id     uuid references public.tasks(id) on delete set null,
  company_id  bigint references public.company(id) on delete set null,
  entry_date  date,          -- convention canonique (timesheet_service.dart)
  "date"      date,          -- convention héritée (dashboard_page.dart)
  days        numeric,
  hours       numeric,
  daily_rate  numeric,
  comment     text,
  description text,
  status      text not null default 'draft',
  is_weekend  boolean not null default false,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now(),
  check (entry_date is not null or "date" is not null)
);
create trigger trg_timesheet_updated before update on public.timesheet_entries
  for each row execute function public.set_updated_at();

-- Unifie les deux conventions de colonnes + calcule is_weekend
create or replace function public.timesheet_entries_normalize()
returns trigger language plpgsql as $$
begin
  if new.entry_date is null then new.entry_date := new."date"; end if;
  if new."date" is null then new."date" := new.entry_date; end if;
  if new.partner_id is null then new.partner_id := new.user_id; end if;
  if new.user_id is null then new.user_id := new.partner_id; end if;
  new.is_weekend := extract(isodow from new.entry_date) in (6, 7);
  return new;
end $$;
create trigger trg_timesheet_normalize before insert or update on public.timesheet_entries
  for each row execute function public.timesheet_entries_normalize();

-- ============================================================================
-- 6. DEMANDES CLIENTS (propositions de projet, extensions, requêtes)
-- ============================================================================

create table if not exists public.project_proposals (
  id               uuid primary key default gen_random_uuid(),
  client_id        uuid not null references auth.users(id) on delete cascade,
  company_id       bigint references public.company(id) on delete set null,
  title            text not null,
  description      text,
  estimated_budget numeric,
  estimated_days   numeric,
  end_date         date,
  status           text not null default 'pending',
  reviewed_by      uuid references auth.users(id) on delete set null,
  approved_by      uuid references auth.users(id) on delete set null,
  response_message text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create trigger trg_proposals_updated before update on public.project_proposals
  for each row execute function public.set_updated_at();

create table if not exists public.project_proposal_documents (
  id          uuid primary key default gen_random_uuid(),
  proposal_id uuid not null references public.project_proposals(id) on delete cascade,
  file_name   text not null,
  file_path   text not null,
  file_size   bigint,
  mime_type   text,
  uploaded_at timestamptz not null default now(),
  created_at  timestamptz not null default now()
);

create table if not exists public.time_extension_requests (
  id               uuid primary key default gen_random_uuid(),
  mission_id       uuid references public.missions(id) on delete cascade,
  client_id        uuid not null references auth.users(id) on delete cascade,
  company_id       bigint references public.company(id) on delete set null,
  days_requested   numeric,
  reason           text,
  status           text not null default 'pending',
  approved_by      uuid references auth.users(id) on delete set null,
  response_message text,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now()
);
create trigger trg_ter_updated before update on public.time_extension_requests
  for each row execute function public.set_updated_at();

create table if not exists public.client_requests (
  id           uuid primary key default gen_random_uuid(),
  client_id    uuid not null references auth.users(id) on delete cascade,
  title        text not null,
  description  text,
  request_type text,
  status       text not null default 'pending',
  created_at   timestamptz not null default now()
);

-- ============================================================================
-- 7. FACTURATION
-- ============================================================================

create table if not exists public.invoices (
  id                bigint generated always as identity primary key,
  invoice_number    text unique,
  company_id        bigint references public.company(id) on delete set null,
  client_user_id    uuid references auth.users(id) on delete set null,
  mission_id        uuid references public.missions(id) on delete set null,
  title             text,
  description       text,
  amount            numeric not null default 0,
  tax_rate          numeric,
  invoice_date      date not null default current_date,
  due_date          date,
  payment_date      date,
  payment_method    text,
  payment_reference text,
  status            text not null default 'draft',
  created_by        uuid references auth.users(id) on delete set null,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);
create trigger trg_invoices_updated before update on public.invoices
  for each row execute function public.set_updated_at();

-- Numéro de facture automatique : INV-2026-000042
create or replace function public.invoices_set_number()
returns trigger language plpgsql as $$
begin
  if new.invoice_number is null then
    new.invoice_number := 'INV-' || to_char(now(), 'YYYY') || '-' || lpad(new.id::text, 6, '0');
  end if;
  return new;
end $$;
create trigger trg_invoices_number before insert on public.invoices
  for each row execute function public.invoices_set_number();

-- ============================================================================
-- 8. ACTIONS COMMERCIALES
-- ============================================================================

create table if not exists public.commercial_actions (
  id              uuid primary key default gen_random_uuid(),
  title           text not null,
  description     text,
  type            text,
  status          text not null default 'planned',
  priority        text,
  client_name     text,
  contact_person  text,
  contact_email   text,
  contact_phone   text,
  estimated_value numeric,
  actual_value    numeric,
  due_date        date,
  completed_date  date,
  assigned_to     uuid references auth.users(id) on delete set null,
  partner_id      uuid references auth.users(id) on delete set null,
  company_id      bigint references public.company(id) on delete set null,
  created_by      uuid references auth.users(id) on delete set null,
  notes           text,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);
create trigger trg_ca_updated before update on public.commercial_actions
  for each row execute function public.set_updated_at();

-- ============================================================================
-- 9. MESSAGERIE
-- ============================================================================

create table if not exists public.conversations (
  id         uuid primary key default gen_random_uuid(),
  name       text,
  is_group   boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.conversation_participants (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id         uuid not null references auth.users(id) on delete cascade,
  joined_at       timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create table if not exists public.messages (
  id              uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id       uuid not null references auth.users(id) on delete cascade,
  content         text not null,
  is_read         boolean not null default false,
  created_at      timestamptz not null default now()
);

-- ============================================================================
-- 10. NOTIFICATIONS
-- ============================================================================

create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  title      text not null,
  message    text,
  type       text,
  mission_id uuid references public.missions(id) on delete set null,
  sent_by    uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create table if not exists public.user_notifications (
  id                    uuid primary key default gen_random_uuid(),
  user_id               uuid not null references auth.users(id) on delete cascade,
  title                 text not null,
  message               text,
  type                  text,
  is_read               boolean not null default false,
  read_at               timestamptz,
  mission_assignment_id uuid references public.mission_assignments(id) on delete set null,
  notification_id       uuid references public.notifications(id) on delete cascade,
  created_at            timestamptz not null default now()
);

-- ============================================================================
-- 11. AGENDA
-- ============================================================================

create table if not exists public.calendar_events (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  description text,
  start_time  timestamptz not null,
  end_time    timestamptz,
  user_id     uuid references auth.users(id) on delete cascade,
  mission_id  uuid references public.missions(id) on delete set null,
  created_at  timestamptz not null default now()
);

-- ============================================================================
-- 12. INDEX
-- ============================================================================

create index if not exists idx_profiles_user on public.profiles(user_id);
create index if not exists idx_profiles_company on public.profiles(company_id);
create index if not exists idx_company_group on public.company(group_id);
create index if not exists idx_missions_company on public.missions(company_id);
create index if not exists idx_missions_partner on public.missions(partner_id);
create index if not exists idx_missions_assigned on public.missions(assigned_to);
create index if not exists idx_missions_parent on public.missions(mission_id);
create index if not exists idx_tasks_mission on public.tasks(mission_id);
create index if not exists idx_proposals_partner on public.mission_proposals(partner_id);
create index if not exists idx_assignments_to on public.mission_assignments(assigned_to);
create index if not exists idx_availability_partner_date on public.partner_availability(partner_id, date);
create index if not exists idx_ts_partner_date on public.timesheet_entries(partner_id, entry_date);
create index if not exists idx_ts_company on public.timesheet_entries(company_id);
create index if not exists idx_invoices_client on public.invoices(client_user_id);
create index if not exists idx_ca_company on public.commercial_actions(company_id);
create index if not exists idx_messages_conv on public.messages(conversation_id, created_at);
create index if not exists idx_user_notif_user on public.user_notifications(user_id, is_read);
create index if not exists idx_events_user_time on public.calendar_events(user_id, start_time);

-- ============================================================================
-- 13. VUES (security_invoker : respectent la RLS des tables sous-jacentes)
-- ============================================================================

create or replace view public.company_with_group
with (security_invoker = true) as
  select c.id, c.name, c.name as company_name, c.city, c.sector, c.country,
         c.ownership_share, c.is_active as company_active,
         g.id as group_id, g.name as group_name, g.sector as group_sector
  from public.company c
  left join public.investor_group g on g.id = c.group_id;

create or replace view public.user_company_info
with (security_invoker = true) as
  select p.id, p.user_id, p.email, p.first_name, p.last_name, p.role,
         p.status, p.company_id, c.name as company_name
  from public.profiles p
  left join public.company c on c.id = p.company_id;

create or replace view public.mission_with_context
with (security_invoker = true) as
  select m.id, m.id as mission_id, m.title, m.title as mission_title,
         m.description, m.company_id, c.name as company_name, c.city,
         c.is_active as company_active,
         g.id as group_id, g.name as group_name, g.sector as group_sector,
         m.partner_id, pp.email as partner_email,
         pp.first_name as partner_first_name, pp.last_name as partner_last_name,
         m.assigned_to, pa.first_name as assigned_to_first_name,
         pa.last_name as assigned_to_last_name,
         m.client_id, m.project_id, m.start_date, m.end_date, m.status,
         m.progress_status, m.priority, m.budget, m.daily_rate, m.monthly_cap,
         m.referral_fee, m.referral_fee_type, m.currency, m.estimated_days,
         m.worked_days, m.completion_percentage, m.notes,
         m.created_at, m.updated_at
  from public.missions m
  left join public.company c on c.id = m.company_id
  left join public.investor_group g on g.id = c.group_id
  left join public.profiles pp on pp.user_id = m.partner_id
  left join public.profiles pa on pa.user_id = m.assigned_to;

create or replace view public.mission_assignments_with_details
with (security_invoker = true) as
  select a.*, m.title as mission_title, t.title as task_title,
         pt.first_name as assigned_to_first_name, pt.last_name as assigned_to_last_name,
         pb.first_name as assigned_by_first_name, pb.last_name as assigned_by_last_name
  from public.mission_assignments a
  left join public.missions m on m.id = a.mission_id
  left join public.tasks t on t.id = a.task_id
  left join public.profiles pt on pt.user_id = a.assigned_to
  left join public.profiles pb on pb.user_id = a.assigned_by;

create or replace view public.timesheet_entries_detailed
with (security_invoker = true) as
  select e.id, e.partner_id,
         coalesce(p.first_name || ' ' || p.last_name, p.email) as partner_name,
         p.email as partner_email,
         e.company_id, e.company_id as client_id, c.name as client_name,
         c.name as company_name,
         e.mission_id, m.title as mission_title,
         e.entry_date, e.days, e.hours, e.daily_rate,
         coalesce(e.days, 0) * coalesce(e.daily_rate, 0) as amount,
         e.comment, e.description, e.status, e.is_weekend,
         trim(to_char(e.entry_date, 'Day')) as day_name,
         e.created_at, e.updated_at
  from public.timesheet_entries e
  left join public.profiles p on p.user_id = e.partner_id
  left join public.company c on c.id = e.company_id
  left join public.missions m on m.id = e.mission_id;

create or replace view public.invoice_details
with (security_invoker = true) as
  select i.*, c.name as company_name,
         coalesce(p.first_name || ' ' || p.last_name, p.email) as client_name,
         p.email as client_email, m.title as mission_title
  from public.invoices i
  left join public.company c on c.id = i.company_id
  left join public.profiles p on p.user_id = i.client_user_id
  left join public.missions m on m.id = i.mission_id;

create or replace view public.partner_availability_view
with (security_invoker = true) as
  select a.*, p.user_id,
         coalesce(p.first_name || ' ' || p.last_name, p.email) as partner_name,
         p.email as partner_email
  from public.partner_availability a
  left join public.profiles p on p.user_id = a.partner_id;

create or replace view public.unread_notifications_count
with (security_invoker = true) as
  select user_id, count(*) as unread_count
  from public.user_notifications
  where is_read = false
  group by user_id;

-- ============================================================================
-- 14. FONCTIONS RPC (appelées par le client Flutter)
-- Toutes en SECURITY INVOKER par défaut : la RLS s'applique.
-- Celles marquées SECURITY DEFINER contournent la RLS volontairement
-- et vérifient elles-mêmes les droits.
-- ============================================================================

-- --- Utilisateurs ------------------------------------------------------------

create or replace function public.get_users()
returns table (id uuid, user_id uuid, email text, first_name text,
               last_name text, role text, user_role text, company_id bigint)
language sql stable security definer set search_path = public as $$
  select p.id, p.user_id, p.email, p.first_name, p.last_name,
         p.role, p.role as user_role, p.company_id
  from profiles p
  where is_staff();
$$;

create or replace function public.get_company_clients()
returns table (id uuid, user_id uuid, email text, first_name text,
               last_name text, company_id bigint, company_name text)
language sql stable security definer set search_path = public as $$
  select p.id, p.user_id, p.email, p.first_name, p.last_name,
         p.company_id, c.name
  from profiles p
  left join company c on c.id = p.company_id
  where lower(p.role) = 'client' and is_staff();
$$;

create or replace function public.assign_user_to_company(
  user_id_param uuid, company_id_param bigint)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_staff() then
    raise exception 'Accès refusé';
  end if;
  update profiles set company_id = company_id_param where user_id = user_id_param;
  insert into user_roles (user_id, role, company_id)
  values (user_id_param,
          coalesce((select role from profiles where user_id = user_id_param), 'client'),
          company_id_param)
  on conflict (user_id) do update set company_id = excluded.company_id;
end $$;

-- --- Projets / missions ------------------------------------------------------

create or replace function public.create_project_with_client(
  p_name text, p_client_id uuid, p_description text default null,
  p_estimated_days numeric default null, p_daily_rate numeric default null,
  p_end_date date default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  if not is_staff() then
    raise exception 'Accès refusé';
  end if;
  insert into missions (title, description, client_id, estimated_days,
                        daily_rate, end_date, status,
                        company_id)
  values (p_name, p_description, p_client_id, p_estimated_days,
          p_daily_rate, p_end_date, 'active',
          (select company_id from profiles where user_id = p_client_id))
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.assign_client_to_mission(
  p_mission_id uuid, p_client_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_staff() then
    raise exception 'Accès refusé';
  end if;
  update missions
  set client_id = p_client_id,
      company_id = coalesce(company_id,
                            (select company_id from profiles where user_id = p_client_id))
  where id = p_mission_id;
end $$;

create or replace function public.get_missions_by_partner(p_partner_id uuid)
returns setof public.mission_with_context
language sql stable security invoker set search_path = public as $$
  select * from mission_with_context
  where partner_id = p_partner_id or assigned_to = p_partner_id
  order by created_at desc;
$$;

create or replace function public.get_available_missions_for_timesheet(
  p_partner_id uuid, p_date date default current_date)
returns setof public.mission_with_context
language sql stable security invoker set search_path = public as $$
  select * from mission_with_context
  where (partner_id = p_partner_id or assigned_to = p_partner_id)
    and status in ('active', 'in_progress')
    and start_date <= p_date
    and (end_date is null or end_date >= p_date)
  order by title;
$$;

create or replace function public.find_best_partners_for_mission(
  p_mission_criteria_id uuid, p_limit int default 10)
returns table (user_id uuid, first_name text, last_name text, email text,
               activity_domains text[], match_score int)
language sql stable security definer set search_path = public as $$
  select pp.user_id, pp.first_name, pp.last_name, pp.email,
         pp.activity_domains,
         cardinality(array(
           select unnest(pp.activity_domains)
           intersect
           select unnest(mc.activity_domains))) as match_score
  from partner_profiles pp
  cross join mission_criteria mc
  where mc.id = p_mission_criteria_id
    and pp.questionnaire_completed
    and is_staff()
  order by match_score desc
  limit p_limit;
$$;

-- --- Notifications -----------------------------------------------------------

create or replace function public.create_user_notification(
  p_user_id uuid, p_title text, p_message text default null,
  p_type text default null, p_mission_assignment_id uuid default null,
  p_notification_id uuid default null)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  insert into user_notifications
    (user_id, title, message, type, mission_assignment_id, notification_id)
  values (p_user_id, p_title, p_message, p_type,
          p_mission_assignment_id, p_notification_id)
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.notify_all_partners_mission_available(
  p_mission_id uuid, p_title text, p_message text default null,
  p_sent_by uuid default null)
returns int language plpgsql security definer set search_path = public as $$
declare v_notif uuid; v_count int;
begin
  if not is_staff() then
    raise exception 'Accès refusé';
  end if;
  insert into notifications (title, message, type, mission_id, sent_by)
  values (p_title, p_message, 'mission_available', p_mission_id, p_sent_by)
  returning id into v_notif;

  insert into user_notifications (user_id, title, message, type, notification_id)
  select p.user_id, p_title, p_message, 'mission_available', v_notif
  from profiles p where lower(p.role) = 'partenaire';
  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- --- Messagerie --------------------------------------------------------------

create or replace function public.create_conversation(
  p_user_id1 uuid, p_user_id2 uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare v_id uuid;
begin
  select cp1.conversation_id into v_id
  from conversation_participants cp1
  join conversation_participants cp2
    on cp2.conversation_id = cp1.conversation_id
  join conversations c on c.id = cp1.conversation_id and not c.is_group
  where cp1.user_id = p_user_id1 and cp2.user_id = p_user_id2
  limit 1;

  if v_id is not null then return v_id; end if;

  insert into conversations (is_group) values (false) returning id into v_id;
  insert into conversation_participants (conversation_id, user_id)
  values (v_id, p_user_id1), (v_id, p_user_id2);
  return v_id;
end $$;

create or replace function public.get_user_conversations(p_user_id uuid)
returns table (conversation_id uuid, name text, is_group boolean,
               user_id uuid, other_user_name text,
               last_message text, last_message_at timestamptz,
               unread_count bigint)
language sql stable security definer set search_path = public as $$
  select c.id,
         coalesce(c.name,
                  (select coalesce(pr.first_name || ' ' || pr.last_name, pr.email)
                   from conversation_participants cpo
                   left join profiles pr on pr.user_id = cpo.user_id
                   where cpo.conversation_id = c.id and cpo.user_id <> p_user_id
                   limit 1)) as name,
         c.is_group,
         p_user_id,
         (select coalesce(pr.first_name || ' ' || pr.last_name, pr.email)
          from conversation_participants cpo
          left join profiles pr on pr.user_id = cpo.user_id
          where cpo.conversation_id = c.id and cpo.user_id <> p_user_id
          limit 1) as other_user_name,
         (select m.content from messages m
          where m.conversation_id = c.id order by m.created_at desc limit 1),
         (select m.created_at from messages m
          where m.conversation_id = c.id order by m.created_at desc limit 1),
         (select count(*) from messages m
          where m.conversation_id = c.id and not m.is_read
            and m.sender_id <> p_user_id)
  from conversations c
  join conversation_participants cp
    on cp.conversation_id = c.id and cp.user_id = p_user_id
  where p_user_id = auth.uid() or is_staff()
  order by 7 desc nulls last;
$$;

-- --- Disponibilités ----------------------------------------------------------

create or replace function public.get_partner_availability_for_period(
  start_date date, end_date date)
returns setof public.partner_availability
language sql stable security invoker set search_path = public as $$
  select * from partner_availability
  where date between start_date and end_date
  order by date, partner_id;
$$;

create or replace function public.get_available_partners_for_date(target_date date)
returns table (partner_id uuid, partner_name text, partner_email text,
               is_available boolean, availability_type text)
language sql stable security invoker set search_path = public as $$
  select a.partner_id,
         coalesce(p.first_name || ' ' || p.last_name, p.email),
         p.email, a.is_available, a.availability_type
  from partner_availability a
  left join profiles p on p.user_id = a.partner_id
  where a.date = target_date and a.is_available
  order by 2;
$$;

create or replace function public.create_default_availability_for_partner(
  new_partner_id uuid, days_ahead int default 90)
returns int language plpgsql security definer set search_path = public as $$
declare v_count int;
begin
  insert into partner_availability (partner_id, date, status, is_available)
  select new_partner_id, d::date, 'available', true
  from generate_series(current_date, current_date + days_ahead, interval '1 day') d
  where extract(isodow from d) < 6
  on conflict (partner_id, date) do nothing;
  get diagnostics v_count = row_count;
  return v_count;
end $$;

-- --- Feuilles de temps -------------------------------------------------------

create or replace function public.get_partner_daily_rate(
  p_partner_id uuid, p_company_id bigint)
returns numeric language sql stable security invoker set search_path = public as $$
  select coalesce(
    (select daily_rate from partner_rates
     where partner_id = p_partner_id and company_id = p_company_id),
    0);
$$;

create or replace function public.check_operator_client_access(
  p_partner_id uuid, p_client_id bigint)
returns boolean language sql stable security invoker set search_path = public as $$
  select coalesce(
    (select allowed from partner_client_permissions
     where partner_id = p_partner_id and client_id = p_client_id),
    false);
$$;

create or replace function public.get_authorized_clients_for_partner(p_partner_id uuid)
returns table (client_id bigint, client_name text, daily_rate numeric)
language sql stable security invoker set search_path = public as $$
  select pcp.client_id, c.name,
         coalesce(pr.daily_rate, 0)
  from partner_client_permissions pcp
  join company c on c.id = pcp.client_id
  left join partner_rates pr
    on pr.partner_id = pcp.partner_id and pr.company_id = pcp.client_id
  where pcp.partner_id = p_partner_id and pcp.allowed
  order by c.name;
$$;

create or replace function public.generate_month_calendar(p_year int, p_month int)
returns table (entry_date date, day_number int, day_name text,
               week_number int, is_weekend boolean)
language sql immutable set search_path = public as $$
  select d::date,
         extract(day from d)::int,
         trim(to_char(d, 'Day')),
         extract(week from d)::int,
         extract(isodow from d) in (6, 7)
  from generate_series(
    make_date(p_year, p_month, 1),
    (make_date(p_year, p_month, 1) + interval '1 month - 1 day'),
    interval '1 day') d;
$$;

create or replace function public.get_partner_monthly_stats(
  p_partner_id uuid, p_year int, p_month int)
returns table (total_days numeric, total_amount numeric, total_entries bigint,
               days_worked numeric, avg_days_per_entry numeric)
language sql stable security invoker set search_path = public as $$
  select coalesce(sum(days), 0),
         coalesce(sum(coalesce(days, 0) * coalesce(daily_rate, 0)), 0),
         count(*),
         coalesce(sum(days) filter (where not is_weekend), 0),
         case when count(*) > 0
              then round(coalesce(sum(days), 0) / count(*), 2) else 0 end
  from timesheet_entries
  where partner_id = p_partner_id
    and extract(year from entry_date) = p_year
    and extract(month from entry_date) = p_month;
$$;

create or replace function public.get_timesheet_report_by_client(
  p_year int, p_month int, p_company_id bigint default null)
returns table (client_id bigint, client_name text, total_days numeric,
               total_amount numeric, partner_count bigint)
language sql stable security definer set search_path = public as $$
  select e.company_id, c.name,
         coalesce(sum(e.days), 0),
         coalesce(sum(coalesce(e.days, 0) * coalesce(e.daily_rate, 0)), 0),
         count(distinct e.partner_id)
  from timesheet_entries e
  left join company c on c.id = e.company_id
  where extract(year from e.entry_date) = p_year
    and extract(month from e.entry_date) = p_month
    and (p_company_id is null or e.company_id = p_company_id)
    and is_staff()
  group by e.company_id, c.name
  order by 4 desc;
$$;

create or replace function public.get_timesheet_report_by_partner(
  p_year int, p_month int, p_company_id bigint default null)
returns table (partner_id uuid, partner_name text, partner_email text,
               total_days numeric, total_amount numeric, client_count bigint)
language sql stable security definer set search_path = public as $$
  select e.partner_id,
         coalesce(p.first_name || ' ' || p.last_name, p.email),
         p.email,
         coalesce(sum(e.days), 0),
         coalesce(sum(coalesce(e.days, 0) * coalesce(e.daily_rate, 0)), 0),
         count(distinct e.company_id)
  from timesheet_entries e
  left join profiles p on p.user_id = e.partner_id
  where extract(year from e.entry_date) = p_year
    and extract(month from e.entry_date) = p_month
    and (p_company_id is null or e.company_id = p_company_id)
    and is_staff()
  group by e.partner_id, p.first_name, p.last_name, p.email
  order by 5 desc;
$$;

-- --- Actions commerciales ----------------------------------------------------

create or replace function public.get_commercial_actions_for_company()
returns setof public.commercial_actions
language sql stable security invoker set search_path = public as $$
  select * from commercial_actions
  where company_id = current_user_company_id()
     or is_staff()
     or created_by = auth.uid()
     or assigned_to = auth.uid()
     or partner_id = auth.uid()
  order by created_at desc;
$$;

-- --- Validation des demandes -------------------------------------------------

create or replace function public.approve_project_proposal(
  p_proposal_id uuid, p_response_message text default null)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not is_staff() then
    raise exception 'Accès refusé';
  end if;
  update project_proposals
  set status = 'approved',
      approved_by = auth.uid(),
      reviewed_by = auth.uid(),
      response_message = p_response_message,
      updated_at = now()
  where id = p_proposal_id;
end $$;

create or replace function public.approve_time_extension(
  p_request_id uuid, p_response_message text default null)
returns void language plpgsql security definer set search_path = public as $$
declare v_req time_extension_requests%rowtype;
begin
  if not is_staff() then
    raise exception 'Accès refusé';
  end if;
  select * into v_req from time_extension_requests where id = p_request_id;
  if not found then
    raise exception 'Demande introuvable';
  end if;

  update time_extension_requests
  set status = 'approved',
      approved_by = auth.uid(),
      response_message = p_response_message,
      updated_at = now()
  where id = p_request_id;

  -- Répercute l'extension sur la mission concernée
  if v_req.mission_id is not null and v_req.days_requested is not null then
    update missions
    set estimated_days = coalesce(estimated_days, 0) + v_req.days_requested
    where id = v_req.mission_id;
  end if;
end $$;

-- ============================================================================
-- 15. STORAGE — bucket privé `documents` (voir note 4 de la migration RLS)
-- ============================================================================

insert into storage.buckets (id, name, public)
values ('documents', 'documents', false)
on conflict (id) do nothing;

drop policy if exists documents_insert_own on storage.objects;
create policy documents_insert_own on storage.objects
  for insert with check (
    bucket_id = 'documents'
    and (public.is_staff() or (storage.foldername(name))[2] = auth.uid()::text)
  );

drop policy if exists documents_select_own on storage.objects;
create policy documents_select_own on storage.objects
  for select using (
    bucket_id = 'documents'
    and (public.is_staff() or (storage.foldername(name))[2] = auth.uid()::text)
  );

drop policy if exists documents_delete_own on storage.objects;
create policy documents_delete_own on storage.objects
  for delete using (
    bucket_id = 'documents'
    and (public.is_staff() or (storage.foldername(name))[2] = auth.uid()::text)
  );
