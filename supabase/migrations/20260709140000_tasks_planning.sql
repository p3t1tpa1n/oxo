-- ============================================================================
-- Colonnes manquantes détectées à l'usage :
-- - tasks.due_date / tasks.priority : le planning affiche les tâches par
--   échéance (planning_page.dart) — colonnes absentes du schéma initial.
-- - mission_proposals.associate_id : renseigné par partner_profiles_page.dart
--   lors d'une proposition de mission.
-- ============================================================================

alter table public.tasks
  add column if not exists due_date date,
  add column if not exists priority text;

create index if not exists idx_tasks_assigned_due
  on public.tasks (assigned_to, due_date);

alter table public.mission_proposals
  add column if not exists associate_id uuid references auth.users(id) on delete set null;
