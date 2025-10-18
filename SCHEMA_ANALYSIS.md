# Analyse du Schéma Supabase - Application de Gestion Commerciale

## ✅ Points Positifs

### Structure Générale
- ✅ Bonne séparation des entités principales (clients, projets, tâches, factures)
- ✅ Gestion multi-tenant avec `companies` et `company_id`
- ✅ Système de rôles avec `profiles` et `user_roles`
- ✅ RLS activé sur la plupart des tables sensibles
- ✅ Timestamps (`created_at`, `updated_at`) présents
- ✅ Utilisation d'UUID pour les identifiants

### Fonctionnalités Métier
- ✅ Gestion des actions commerciales
- ✅ Propositions de projets avec documents
- ✅ Disponibilités des partenaires
- ✅ Feuilles de temps (timesheet)
- ✅ Affectations de missions
- ✅ Système de facturation
- ✅ Messagerie interne

## 🔴 Problèmes Critiques Identifiés

### 1. **Incohérence Majeure: Duplication du Système de Rôles**

**Problème**: Deux systèmes de rôles coexistent:
- `profiles.role` (type: `user_role`)
- `user_roles.user_role` (type: `text`)

**Impact**: 
- Risque de désynchronisation
- Confusion dans les politiques RLS
- Maintenance complexe

**Recommandation**: Choisir UN seul système:
- **Option A**: Utiliser uniquement `profiles.role` (plus simple)
- **Option B**: Supprimer `profiles.role` et utiliser uniquement `user_roles`

---

### 2. **Contraintes Foreign Keys Manquantes ou Nulles**

Plusieurs foreign keys affichent `"foreign_table": null` ou `"foreign_column": null`:

```
clients.created_by → auth.users (manquant)
commercial_actions.assigned_to → auth.users ou profiles (manquant)
commercial_actions.partner_id → profiles (manquant)
invoices.client_user_id → auth.users ou profiles (manquant)
tasks.assigned_to → profiles (manquant)
tasks.partner_id → profiles (manquant)
```

**Impact**: 
- Intégrité référentielle non garantie
- Données orphelines possibles
- Suppressions en cascade non définies

---

### 3. **Incohérence dans les Références Utilisateur**

**Problème**: Mélange entre `auth.users.id` et `profiles.id`:
- Certaines tables référencent `auth.users` (via `auth.uid()`)
- D'autres semblent référencer `profiles.id`
- `profiles.user_id` pointe vers `auth.users.id`

**Exemple problématique**:
```sql
-- Dans clients
created_by uuid → devrait pointer vers auth.users.id

-- Dans timesheet_entries
user_id uuid → pointe vers profiles.id (selon les policies)

-- Dans tasks
user_id uuid → référence ambiguë
```

**Recommandation**: 
- Toujours référencer `auth.users.id` pour l'authentification
- Utiliser `profiles.id` uniquement pour les relations métier spécifiques

---

### 4. **Politiques RLS Redondantes ou Conflictuelles**

#### Exemple 1: Table `projects`
```sql
-- Politique 1: "Users can view all projects"
using: true  -- Accès total !

-- Politique 2: "projects_company_access"
using: (EXISTS ...) -- Conditions restrictives

-- Politique 3: "Modification projets pour admin et associés"
using: (EXISTS ...) -- Autre condition

-- Politique 4: "Accès projets pour tous les utilisateurs authentifiés"
using: true  -- Accès total à nouveau !
```

**Impact**: 
- Confusion sur les règles réelles appliquées
- Possibles failles de sécurité
- Difficulté de maintenance

**Recommandation**: Consolidez en 2-3 politiques claires par opération (SELECT, INSERT, UPDATE, DELETE)

#### Exemple 2: Table `tasks`
5 politiques dont 2 avec `using: true` → trop permissif !

---

### 5. **Statuts Non Standardisés**

**Problème**: Différents formats de statuts selon les tables:

```
clients.status: 'actif' (français) vs 'active' (anglais)
projects.status: enum status_type
tasks.status: enum status_type
commercial_actions.status: 'planned' (anglais)
invoices.status: 'draft' (anglais)
timesheet_entries.status: 'pending' (anglais)
```

**Impact**: 
- Incohérence linguistique
- Erreurs potentielles dans le code client
- Difficulté de localisation

**Recommandation**: Standardiser en anglais partout

---

### 6. **Table `user_client_mapping` Problématique**

**Structure**:
```
id, user_id, client_id, created_at
```

**Contraintes**:
- `UNIQUE(user_id, client_id)` ✅
- `UNIQUE(user_id)` ⚠️ Un user ne peut être lié qu'à UN client
- `UNIQUE(client_id)` ⚠️ Un client ne peut être lié qu'à UN user

**Problème**: Les contraintes uniques sur `user_id` et `client_id` séparément empêchent les relations many-to-many.

**Impact**: 
- Un client ne peut avoir qu'un seul utilisateur
- Un utilisateur ne peut être lié qu'à un client
- Très limitant !

**Recommandation**: Supprimer les contraintes UNIQUE individuelles, garder uniquement `UNIQUE(user_id, client_id)`

---

### 7. **Conversations et Messages: Restrictions Messaging**

**Observation**: Politiques RLS font référence à `can_message_user()` et `can_participate_in_conversation()`

**Problème**: Ces fonctions ne sont pas définies dans le schéma fourni.

**Impact**: 
- Les politiques ne fonctionneront pas correctement
- Risque d'erreurs SQL

**Recommandation**: Vérifier que ces fonctions existent dans le schéma réel

---

### 8. **Champs `company_id` de Types Différents**

**Incohérence**:
```
companies.id: bigint
profiles.company_id: bigint ✅
projects.company_id: bigint ✅
commercial_actions.company_id: bigint ✅
partner_availability.company_id: bigint ✅

MAIS:
user_roles.company_id: uuid ❌
```

**Impact**: 
- Foreign key impossible entre `user_roles.company_id` (uuid) et `companies.id` (bigint)
- Incohérence des données

**Recommandation**: Unifier en `bigint` partout

---

### 9. **Politiques RLS avec `role = 'public'` au lieu de `authenticated`**

Plusieurs politiques utilisent:
```sql
roles: ["public"]
```

Au lieu de:
```sql
roles: ["authenticated"]
```

**Tables concernées**:
- `clients`
- `mission_assignments`
- `mission_notifications`
- `user_notifications`
- `user_roles`
- `projects`
- `tasks`
- `timesheet_entries`

**Impact**: 
- Accès potentiel non authentifié
- Faille de sécurité

**Recommandation**: Remplacer `public` par `authenticated` sauf cas exceptionnels

---

### 10. **Conversations: Limitations Structurelles**

**Structure actuelle**:
```
conversations:
  - user1_id
  - user2_id
  - is_group
  - name
```

**Problème**: 
- Structure fixe pour 2 utilisateurs uniquement
- `is_group` et `name` suggèrent des groupes mais la structure ne le permet pas
- Contradiction entre la structure et les fonctionnalités

**Solution**: Utiliser uniquement `conversation_participants` (déjà présente) et supprimer `user1_id`, `user2_id`

---

### 11. **Factures: Relation Client Ambiguë**

```
invoices:
  - client_user_id: uuid → vers auth.users ?
  - project_id: uuid → vers projects (qui a déjà un client_id)
```

**Problème**: 
- Redondance: le client est déjà lié au projet
- `client_user_id` devrait probablement être `client_id` vers `clients.id`

**Impact**: Confusion et potentielles incohérences de données

---

### 12. **Tasks: Trop de Colonnes d'Assignation**

```
tasks:
  - assigned_to: uuid
  - partner_id: uuid
  - user_id: uuid
  - created_by: uuid
  - updated_by: uuid
```

**Problème**: 
- `assigned_to`, `partner_id` et `user_id` semblent redondants
- Confusion sur qui est réellement assigné à la tâche

**Recommandation**: Clarifier l'utilisation ou fusionner ces champs

---

## ⚠️ Problèmes Moyens

### 13. Absence d'Index Explicites
Les index ne sont pas visibles dans ce JSON, mais assurez-vous d'avoir des index sur:
- Toutes les foreign keys
- `profiles.user_id`
- `profiles.company_id`
- `projects.client_id`
- `tasks.project_id`
- `commercial_actions.company_id`
- Colonnes utilisées dans les WHERE des politiques RLS

### 14. Pas de Soft Delete Unifié
Seule la table `clients` a `deleted_at`. Considérez l'ajouter à:
- `projects`
- `tasks`
- `commercial_actions`
- `invoices`

### 15. Colonnes `estimated_days` et `worked_days` en NUMERIC
Dans `projects`:
```
estimated_days: numeric
worked_days: numeric
```

**Recommandation**: Utiliser `integer` ou `decimal(10,2)` selon si vous avez besoin de demi-journées

---

## 📋 Plan d'Action Recommandé

### Phase 1: Corrections Critiques (Priorité Haute)

1. **Unifier le système de rôles**
   ```sql
   -- Option recommandée: supprimer user_roles, utiliser profiles.role
   DROP TABLE user_roles;
   ```

2. **Corriger company_id dans user_roles** (si table conservée)
   ```sql
   ALTER TABLE user_roles ALTER COLUMN company_id TYPE bigint USING company_id::text::bigint;
   ```

3. **Ajouter les Foreign Keys manquantes**
   ```sql
   ALTER TABLE clients ADD CONSTRAINT fk_clients_created_by 
     FOREIGN KEY (created_by) REFERENCES auth.users(id);
   
   ALTER TABLE commercial_actions ADD CONSTRAINT fk_commercial_actions_assigned_to 
     FOREIGN KEY (assigned_to) REFERENCES auth.users(id);
   -- etc.
   ```

4. **Corriger user_client_mapping**
   ```sql
   ALTER TABLE user_client_mapping DROP CONSTRAINT IF EXISTS user_client_mapping_user_id_key;
   ALTER TABLE user_client_mapping DROP CONSTRAINT IF EXISTS user_client_mapping_client_id_key;
   -- Garder uniquement la contrainte composite
   ```

5. **Nettoyer les politiques RLS redondantes**
   - Supprimer les politiques avec `using: true` trop permissives
   - Remplacer `public` par `authenticated`

### Phase 2: Améliorations (Priorité Moyenne)

6. **Standardiser les statuts en anglais**
7. **Simplifier la structure des conversations**
8. **Clarifier les assignations dans tasks**
9. **Ajouter soft delete unifié**
10. **Créer les fonctions RLS manquantes** (`can_message_user`, etc.)

### Phase 3: Optimisations (Priorité Basse)

11. **Ajouter les index nécessaires**
12. **Documenter les types ENUM**
13. **Audit complet des politiques RLS**

---

## 🔍 Vérifications Nécessaires

Vérifiez dans votre base de données réelle:

1. Les fonctions mentionnées dans les politiques RLS existent-elles ?
   - `can_message_user()`
   - `can_participate_in_conversation()`
   - `get_user_company_id()`

2. Les types ENUM sont-ils bien définis ?
   - `user_role`
   - `status_type`
   - `priority_type`

3. Les triggers `updated_at` sont-ils en place ?

4. Y a-t-il des index sur les foreign keys et colonnes fréquemment requêtées ?

---

## Conclusion

Votre schéma est **fonctionnel mais nécessite des corrections importantes** pour:
- ✅ Garantir l'intégrité des données
- ✅ Sécuriser correctement l'accès (RLS)
- ✅ Faciliter la maintenance
- ✅ Éviter les incohérences

Les problèmes critiques (1-12) doivent être corrigés en priorité.

Souhaitez-vous que je génère les scripts SQL de migration pour corriger ces problèmes ?


