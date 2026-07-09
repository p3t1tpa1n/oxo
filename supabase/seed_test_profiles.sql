-- ============================================================================
-- SEED — Profils de test pour les 3 rôles (associé, partenaire, client)
--
-- PRÉREQUIS (2 minutes) :
--   Dashboard → Authentication → Users → "Add user" → créer ces 3 comptes
--   (coche "Auto Confirm User") :
--     associe@test.oxo     mot de passe : Test1234!
--     partenaire@test.oxo  mot de passe : Test1234!
--     client@test.oxo      mot de passe : Test1234!
--
-- PUIS : coller ce script dans SQL Editor et l'exécuter.
-- Il est idempotent : ré-exécutable sans doublons.
--
-- Le script crée :
--   - 1 groupe d'investissement + 1 société de test
--   - les 3 profils avec leurs rôles
--   - le profil partenaire complet (questionnaire) + tarif + permission client
--   - 1 mission assignée au partenaire + 1 tâche planifiée
--   - les disponibilités par défaut du partenaire (60 jours)
-- ============================================================================

do $$
declare
  v_associe    uuid;
  v_partenaire uuid;
  v_client     uuid;
  v_group_id   bigint;
  v_company_id bigint;
  v_mission_id uuid;
begin
  -- ── Récupérer les comptes créés dans Authentication ────────────────────
  select id into v_associe    from auth.users where email = 'associe@test.oxo';
  select id into v_partenaire from auth.users where email = 'partenaire@test.oxo';
  select id into v_client     from auth.users where email = 'client@test.oxo';

  if v_associe is null or v_partenaire is null or v_client is null then
    raise exception 'Créez d''abord les 3 comptes dans Authentication → Users : associe@test.oxo, partenaire@test.oxo, client@test.oxo';
  end if;

  -- ── Groupe + société de test ───────────────────────────────────────────
  select id into v_group_id from investor_group where name = 'Groupe Test';
  if v_group_id is null then
    insert into investor_group (name, sector, country, contact_main)
    values ('Groupe Test', 'Industrie', 'France', 'contact@groupetest.fr')
    returning id into v_group_id;
  end if;

  select id into v_company_id from company where name = 'Société Test SA';
  if v_company_id is null then
    insert into company (name, group_id, city, sector, country, ownership_share)
    values ('Société Test SA', v_group_id, 'Paris', 'Industrie', 'France', 65)
    returning id into v_company_id;
  end if;

  -- ── Profils (rôle + rattachement société pour le client) ───────────────
  insert into profiles (user_id, email, first_name, last_name, role, company_id)
  values
    (v_associe,    'associe@test.oxo',    'Alice',   'Associée',   'associe',    null),
    (v_partenaire, 'partenaire@test.oxo', 'Pierre',  'Partenaire', 'partenaire', null),
    (v_client,     'client@test.oxo',     'Claire',  'Cliente',    'client',     v_company_id)
  on conflict (user_id) do update
    set role = excluded.role,
        company_id = excluded.company_id,
        first_name = excluded.first_name,
        last_name = excluded.last_name;

  -- ── Profil partenaire complet (questionnaire rempli) ───────────────────
  insert into partner_profiles (
    user_id, civility, first_name, last_name, email, phone, city,
    company_name, legal_form, activity_domains, languages,
    career_paths, main_functions, questionnaire_completed, completed_at)
  values (
    v_partenaire, 'M.', 'Pierre', 'Partenaire', 'partenaire@test.oxo',
    '0600000000', 'Lyon', 'PP Conseil', 'SASU',
    array['Finance', 'Stratégie'], array['Français', 'Anglais'],
    array['Direction financière'], array['DAF de transition'],
    true, now())
  on conflict (user_id) do update set questionnaire_completed = true;

  -- ── Tarif + permission du partenaire sur la société cliente ────────────
  insert into partner_rates (partner_id, company_id, daily_rate)
  values (v_partenaire, v_company_id, 850)
  on conflict (partner_id, company_id) do update set daily_rate = 850;

  insert into partner_client_permissions (partner_id, client_id, allowed)
  values (v_partenaire, v_company_id, true)
  on conflict (partner_id, client_id) do update set allowed = true;

  -- ── Mission de test assignée au partenaire ─────────────────────────────
  select id into v_mission_id from missions where title = 'Mission de test — DAF transition';
  if v_mission_id is null then
    insert into missions (
      title, description, company_id, partner_id, client_id,
      start_date, end_date, status, progress_status, priority,
      daily_rate, estimated_days, currency)
    values (
      'Mission de test — DAF transition',
      'Mission de démonstration pour valider les écrans.',
      v_company_id, v_partenaire, v_client,
      current_date - 7, current_date + 60, 'active', 'en_cours', 'medium',
      850, 40, 'EUR')
    returning id into v_mission_id;
  end if;

  -- ── Tâche planifiée aujourd'hui (visible dans le Planning) ─────────────
  if not exists (select 1 from tasks where title = 'Tâche de test — kick-off') then
    insert into tasks (mission_id, title, description, status, assigned_to, due_date, priority)
    values (v_mission_id, 'Tâche de test — kick-off',
            'Réunion de lancement avec le client.', 'in_progress',
            v_partenaire, current_date, 'high');
  end if;

  -- ── Disponibilités par défaut du partenaire (60 jours ouvrés) ──────────
  perform create_default_availability_for_partner(v_partenaire, 60);

  raise notice 'Seed OK — associé: %, partenaire: %, client: %', v_associe, v_partenaire, v_client;
end $$;
