# Base de données OXO — migrations et sécurité

## Principe

Le schéma de la base est **versionné dans `supabase/migrations/`**. Plus aucune
modification ne doit être faite à la main dans le SQL Editor du dashboard :
chaque changement passe par un fichier de migration numéroté, committé, et
appliqué avec la CLI Supabase.

## Mise en place initiale (à faire une fois)

Le schéma actuel a été construit à la main dans le dashboard : il faut d'abord
le capturer comme baseline.

```bash
# 1. Installer la CLI et se connecter
brew install supabase/tap/supabase
supabase login

# 2. Lier le projet local au projet Supabase
supabase link --project-ref dswirxxbzbyhnxsrzyzi

# 3. Capturer le schéma live comme migration baseline
supabase db pull          # crée supabase/migrations/<ts>_remote_schema.sql

# 4. Appliquer ensuite les migrations de ce repo (RLS, etc.)
supabase db push
```

## Workflow pour tout changement de schéma ultérieur

```bash
supabase migration new mon_changement   # crée un fichier vide numéroté
# ... écrire le SQL dedans ...
supabase db push                        # applique sur le projet distant
git add supabase/migrations && git commit
```

## Sécurité — règles non négociables

1. **La clé `service_role` ne quitte jamais le serveur.** Elle n'apparaît ni
   dans le code Flutter, ni dans `.env` du repo, ni dans le CI de build client.
   Elle n'est utilisée que par les Edge Functions (injectée automatiquement par
   Supabase) et par la CLI en local.
2. **La création d'utilisateurs, l'attribution de rôle et l'assignation à une
   entreprise se font exclusivement côté serveur**, via l'Edge Function
   `admin-create-user` (voir `supabase/functions/admin-create-user/`).
   Le client Flutter n'appelle plus jamais `auth.signUp` ni n'écrit dans
   `profiles.role`.
3. **Le client Flutter n'utilise que la clé `anon`**, dont les droits sont
   entièrement bornés par les policies RLS (`migrations/*_rls_policies.sql`).
   La clé anon est publique par nature (elle est embarquée dans chaque build) —
   c'est la RLS qui protège les données, pas le secret de la clé.

### Déploiement de l'Edge Function

```bash
supabase functions deploy admin-create-user
```

La fonction utilise `SUPABASE_SERVICE_ROLE_KEY`, injectée automatiquement par
la plateforme — rien à configurer.

## Pourquoi des Edge Functions plutôt qu'une API séparée

- Aucune infrastructure supplémentaire à héberger/surveiller (l'app n'a pas de
  backend aujourd'hui ; en ajouter un pour 2-3 endpoints sensibles serait
  disproportionné).
- La `service_role` reste dans le périmètre Supabase, jamais dans un `.env`
  d'un serveur tiers.
- Auth intégrée : la fonction reçoit le JWT de l'appelant et peut vérifier son
  rôle avant d'agir.

Si le nombre d'opérations serveur dépasse ~10 endpoints ou nécessite des jobs
longs/planifiés, réévaluer avec une petite API dédiée (ou les Database
Functions + pg_cron).

## Dette connue à réconcilier avec le schéma live

- `company` vs `companies` : le code lisait les deux ; la table réelle semble
  être `company` (utilisée sans fallback par `timesheet_service.dart`).
  `CompanyService.getAllCompanies` garde un fallback à supprimer après
  vérification ; `createCompany`/`updateCompany` écrivent dans `companies` —
  **à vérifier en priorité** avec le schéma capturé par `db pull`.
- `timesheet_entries` : deux conventions coexistent dans le code
  (`date`+`hours` dans les pages, `entry_date`+`days` dans
  `timesheet_service.dart`). Trancher après `db pull` et migrer.
