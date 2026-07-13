-- ============================================================================
-- SEED — Données de démo pour remplir les écrans client et partenaire
--
-- PRÉREQUIS : avoir exécuté seed_test_profiles.sql (comptes + société).
-- Coller dans Supabase → SQL Editor → Run. Idempotent (ré-exécutable).
--
-- Remplit :
--   CLIENT     : 5 factures (payées / en attente / en retard), 3 missions,
--                1 proposition de projet en attente
--   PARTENAIRE : 1 proposition de mission à accepter, saisies de temps
--                sur 2 semaines, disponibilités variées
-- ============================================================================

do $$
declare
  v_associe    uuid;
  v_partenaire uuid;
  v_client     uuid;
  v_company_id bigint;
  v_m1 uuid;  -- mission en cours (DAF transition)
  v_m2 uuid;  -- mission terminée
  v_m3 uuid;  -- mission à assigner
begin
  -- ── Comptes et société ───────────────────────────────────────────────────
  select id into v_associe    from auth.users where email = 'associe@test.oxo';
  select id into v_partenaire from auth.users where email = 'partenaire@test.oxo';
  select id into v_client     from auth.users where email = 'client@test.oxo';

  if v_associe is null or v_partenaire is null or v_client is null then
    raise exception 'Exécutez d''abord seed_test_profiles.sql (comptes manquants)';
  end if;

  select id into v_company_id from company where name = 'Société Test SA';
  if v_company_id is null then
    raise exception 'Société Test SA introuvable — exécutez seed_test_profiles.sql';
  end if;

  -- ── Missions de la société cliente ──────────────────────────────────────
  select id into v_m1 from missions where title = 'Mission de test — DAF transition';
  if v_m1 is null then
    insert into missions (title, description, company_id, partner_id, client_id,
                          start_date, end_date, status, progress_status, priority,
                          daily_rate, estimated_days, currency)
    values ('Mission de test — DAF transition',
            'Mission de démonstration pour valider les écrans.',
            v_company_id, v_partenaire, v_client,
            current_date - 30, current_date + 60, 'active', 'en_cours', 'medium',
            850, 40, 'EUR')
    returning id into v_m1;
  end if;

  select id into v_m2 from missions where title = 'Clôture annuelle 2025';
  if v_m2 is null then
    insert into missions (title, description, company_id, partner_id, client_id,
                          start_date, end_date, status, progress_status, priority,
                          daily_rate, estimated_days, worked_days, currency)
    values ('Clôture annuelle 2025',
            'Assistance à la clôture des comptes et liasse fiscale.',
            v_company_id, v_partenaire, v_client,
            current_date - 120, current_date - 45, 'completed', 'fait', 'high',
            900, 20, 20, 'EUR')
    returning id into v_m2;
  end if;

  select id into v_m3 from missions where title = 'Cadrage projet ERP';
  if v_m3 is null then
    insert into missions (title, description, company_id, client_id,
                          start_date, end_date, status, progress_status, priority,
                          daily_rate, estimated_days, currency)
    values ('Cadrage projet ERP',
            'Étude de cadrage pour le remplacement de l''ERP.',
            v_company_id, v_client,
            current_date + 5, current_date + 45, 'active', 'à_assigner', 'medium',
            950, 18, 'EUR')
    returning id into v_m3;
  end if;

  -- ── Factures du client (résumé : payé / en attente / en retard) ─────────
  -- NB : due_date toujours renseignée (l'app la parse sans null-check).
  if not exists (select 1 from invoices where title = 'Prestations avril 2026') then
    insert into invoices (company_id, client_user_id, mission_id, title, description,
                          amount, tax_rate, invoice_date, due_date, payment_date,
                          payment_method, status, created_by)
    values (v_company_id, v_client, v_m2, 'Prestations avril 2026',
            'Clôture annuelle — solde.', 9000, 20,
            current_date - 75, current_date - 45, current_date - 50,
            'virement', 'paid', v_associe);
  end if;

  if not exists (select 1 from invoices where title = 'Prestations mai 2026') then
    insert into invoices (company_id, client_user_id, mission_id, title, description,
                          amount, tax_rate, invoice_date, due_date, payment_date,
                          payment_method, status, created_by)
    values (v_company_id, v_client, v_m1, 'Prestations mai 2026',
            'DAF de transition — 10 jours.', 8500, 20,
            current_date - 45, current_date - 15, current_date - 20,
            'virement', 'paid', v_associe);
  end if;

  if not exists (select 1 from invoices where title = 'Prestations juin 2026') then
    insert into invoices (company_id, client_user_id, mission_id, title, description,
                          amount, tax_rate, invoice_date, due_date, status, created_by)
    values (v_company_id, v_client, v_m1, 'Prestations juin 2026',
            'DAF de transition — 12 jours.', 10200, 20,
            current_date - 12, current_date + 18, 'sent', v_associe);
  end if;

  if not exists (select 1 from invoices where title = 'Acompte cadrage ERP') then
    insert into invoices (company_id, client_user_id, mission_id, title, description,
                          amount, tax_rate, invoice_date, due_date, status, created_by)
    values (v_company_id, v_client, v_m3, 'Acompte cadrage ERP',
            'Acompte 30 % au lancement.', 5130, 20,
            current_date - 5, current_date + 25, 'pending', v_associe);
  end if;

  if not exists (select 1 from invoices where title = 'Frais de déplacement T1') then
    insert into invoices (company_id, client_user_id, mission_id, title, description,
                          amount, tax_rate, invoice_date, due_date, status, created_by)
    values (v_company_id, v_client, v_m1, 'Frais de déplacement T1',
            'Refacturation frais T1.', 640, 20,
            current_date - 60, current_date - 20, 'overdue', v_associe);
  end if;

  -- ── Proposition de projet du client (en attente de validation) ──────────
  if not exists (select 1 from project_proposals where title = 'Refonte du contrôle de gestion') then
    insert into project_proposals (client_id, company_id, title, description,
                                   estimated_budget, estimated_days, end_date, status)
    values (v_client, v_company_id, 'Refonte du contrôle de gestion',
            'Mise en place d''indicateurs et tableaux de bord.',
            30000, 35, current_date + 90, 'pending');
  end if;

  -- ── Proposition de mission au partenaire (écran "missions proposées") ───
  if not exists (select 1 from mission_proposals
                 where mission_id = v_m3 and partner_id = v_partenaire) then
    insert into mission_proposals (mission_id, partner_id, status)
    values (v_m3, v_partenaire, 'pending');
  end if;

  -- ── Saisies de temps du partenaire (10 derniers jours ouvrés) ───────────
  insert into timesheet_entries (partner_id, mission_id, company_id, entry_date,
                                 days, daily_rate, status, comment)
  select v_partenaire, v_m1, v_company_id, d::date, 1, 850, 'draft',
         'Journée mission DAF'
  from generate_series(current_date - 14, current_date - 1, interval '1 day') d
  where extract(isodow from d) < 6
    and not exists (select 1 from timesheet_entries
                    where partner_id = v_partenaire and entry_date = d::date);

  -- ── Disponibilités variées du partenaire (30 prochains jours) ───────────
  -- jours ouvrés disponibles, sauf : vendredi prochain partiel, et 2 jours de congés
  insert into partner_availability (partner_id, date, is_available,
                                    availability_type, company_id)
  select v_partenaire, d::date, true, 'full_day', v_company_id
  from generate_series(current_date, current_date + 30, interval '1 day') d
  where extract(isodow from d) < 6
  on conflict (partner_id, date) do nothing;

  update partner_availability
     set is_available = true, availability_type = 'partial_day',
         start_time = '09:00', end_time = '12:30'
   where partner_id = v_partenaire
     and date = (current_date + (5 - extract(isodow from current_date)::int + 7) % 7 + 7);

  update partner_availability
     set is_available = false, availability_type = 'unavailable',
         unavailability_reason = 'vacation', notes = 'Congés'
   where partner_id = v_partenaire
     and date in (current_date + 14, current_date + 15);

  raise notice 'Seed démo OK — factures: %, missions société: %',
    (select count(*) from invoices where client_user_id = v_client),
    (select count(*) from missions where company_id = v_company_id);
end $$;
