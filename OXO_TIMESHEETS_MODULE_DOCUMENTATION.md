# 📚 MODULE OXO TIME SHEETS - Documentation Complète

**Version:** 1.0  
**Date:** 1er novembre 2025  
**Auteur:** IA Assistant  
**Statut:** ✅ Prêt pour déploiement

---

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Installation](#installation)
4. [Schéma de base de données](#schéma-de-base-de-données)
5. [Modèles de données](#modèles-de-données)
6. [Services](#services)
7. [Interfaces utilisateur](#interfaces-utilisateur)
8. [Contrôle d'accès](#contrôle-daccès)
9. [Workflows](#workflows)
10. [Tests et validation](#tests-et-validation)
11. [Maintenance](#maintenance)

---

## 🎯 Vue d'ensemble

Le module **OXO TIME SHEETS** est un système complet de gestion du temps de travail, des tarifs et des permissions pour une application multi-rôles. Il reproduit et améliore les fonctionnalités du fichier Excel "OXO TIME SHEETS.xlsm" dans une architecture moderne.

### Objectifs

- ✅ Saisie du temps de travail par jour et par client
- ✅ Gestion des tarifs journaliers par opérateur et client
- ✅ Contrôle des permissions d'accès aux clients
- ✅ Génération automatique de calendriers mensuels
- ✅ Calculs automatiques (montants, totaux, moyennes)
- ✅ Reporting consolidé par client et opérateur
- ✅ Exports (PDF, Excel, CSV)
- ✅ Validation et workflow d'approbation

### Équivalences Excel → Application

| Feuille Excel | Composant Application |
|---------------|----------------------|
| `Time sheet` | `TimeEntryPage` + `timesheet_entries` table |
| `ENTRÉES TARIFS` | `TimesheetSettingsPage` + `operator_rates` table |
| `CALCUL` | Fonctions SQL + `TimesheetService` |
| `CALCUL 2` | `operator_client_permissions` table |
| `Feuil1` | Fonction `generate_month_calendar()` |

---

## 🏗️ Architecture

### Structure des fichiers

```
oxo/
├── supabase/
│   └── create_oxo_timesheets_module.sql    # Schéma complet de la base de données
├── lib/
│   ├── models/
│   │   └── timesheet_models.dart            # Modèles de données Dart
│   ├── services/
│   │   └── timesheet_service.dart           # Logique métier
│   └── pages/
│       └── timesheet/
│           ├── time_entry_page.dart         # Saisie du temps (partenaires)
│           ├── timesheet_settings_page.dart # Paramètres (associés)
│           └── timesheet_reporting_page.dart # Reporting (associés)
```

### Flux de données

```
┌─────────────────┐
│   Utilisateur   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   UI (Pages)    │ ◄─── Routes dans main.dart
└────────┬────────┘      Liens dans side_menu.dart
         │
         ▼
┌─────────────────┐
│  TimesheetService│ ◄─── Logique métier
└────────┬────────┘      Validations
         │               Calculs
         ▼
┌─────────────────┐
│  Supabase API   │ ◄─── RLS activé
└────────┬────────┘      Fonctions SQL
         │               Triggers
         ▼
┌─────────────────┐
│  Base de données│
│  - operator_rates
│  - operator_client_permissions
│  - timesheet_entries
└─────────────────┘
```

---

## 📦 Installation

### 1. Créer le schéma de base de données

Exécutez le script SQL sur votre instance Supabase :

```bash
psql -h your-supabase-host -U postgres -d postgres -f supabase/create_oxo_timesheets_module.sql
```

Ou via l'interface Supabase :
1. Allez dans **SQL Editor**
2. Copiez le contenu de `create_oxo_timesheets_module.sql`
3. Exécutez le script

### 2. Vérifier l'installation

Le script créera :
- ✅ 3 tables principales
- ✅ 1 vue détaillée
- ✅ 8 fonctions SQL
- ✅ 3 triggers
- ✅ Politiques RLS complètes

### 3. Tester l'application

1. Relancez l'application Flutter
2. Connectez-vous en tant qu'**associé**
3. Accédez à "Paramètres Timesheet" dans le menu
4. Créez des tarifs et permissions
5. Connectez-vous en tant que **partenaire**
6. Accédez à "Saisie du temps"
7. Saisissez des heures

---

## 🗄️ Schéma de base de données

### Table: `operator_rates`

Stocke les tarifs journaliers par opérateur et client.

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Clé primaire |
| `operator_id` | UUID | Référence vers `auth.users` |
| `client_id` | UUID | Référence vers `clients` |
| `daily_rate` | NUMERIC(10,2) | Tarif journalier en euros |
| `created_at` | TIMESTAMPTZ | Date de création |
| `updated_at` | TIMESTAMPTZ | Date de mise à jour |

**Contraintes:**
- Unique sur `(operator_id, client_id)`
- `daily_rate >= 0`

**Indexes:**
- `idx_operator_rates_operator`
- `idx_operator_rates_client`

---

### Table: `operator_client_permissions`

Définit les permissions d'accès opérateur-client.

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Clé primaire |
| `operator_id` | UUID | Référence vers `auth.users` |
| `client_id` | UUID | Référence vers `clients` |
| `allowed` | BOOLEAN | TRUE si autorisé |
| `created_at` | TIMESTAMPTZ | Date de création |
| `updated_at` | TIMESTAMPTZ | Date de mise à jour |

**Contraintes:**
- Unique sur `(operator_id, client_id)`

**Indexes:**
- `idx_operator_client_permissions_operator`
- `idx_operator_client_permissions_client`

---

### Table: `timesheet_entries`

Stocke les saisies de temps de travail.

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | Clé primaire |
| `operator_id` | UUID | Référence vers `auth.users` |
| `client_id` | UUID | Référence vers `clients` |
| `entry_date` | DATE | Date de la saisie |
| `hours` | NUMERIC(4,2) | Heures travaillées (0-24) |
| `comment` | TEXT | Commentaire optionnel |
| `daily_rate` | NUMERIC(10,2) | Tarif journalier appliqué |
| `amount` | NUMERIC(10,2) | **Calculé:** `hours × daily_rate` |
| `is_weekend` | BOOLEAN | TRUE si week-end |
| `status` | VARCHAR(20) | `draft`, `submitted`, `approved`, `rejected` |
| `company_id` | UUID | Référence vers `companies` |
| `created_at` | TIMESTAMPTZ | Date de création |
| `updated_at` | TIMESTAMPTZ | Date de mise à jour |

**Contraintes:**
- Unique sur `(operator_id, entry_date, client_id)`
- `hours > 0 AND hours <= 24`
- `status IN ('draft', 'submitted', 'approved', 'rejected')`

**Indexes:**
- `idx_timesheet_entries_operator`
- `idx_timesheet_entries_client`
- `idx_timesheet_entries_date`
- `idx_timesheet_entries_company`
- `idx_timesheet_entries_status`

---

### Vue: `timesheet_entries_detailed`

Vue enrichie avec les noms des opérateurs et clients.

```sql
SELECT 
  te.*,
  u.email as operator_email,
  p.first_name || ' ' || p.last_name as operator_name,
  c.name as client_name,
  CASE EXTRACT(DOW FROM te.entry_date)
    WHEN 0 THEN 'Dimanche'
    WHEN 1 THEN 'Lundi'
    -- ...
  END as day_name
FROM timesheet_entries te
LEFT JOIN auth.users u ON te.operator_id = u.id
LEFT JOIN profiles p ON te.operator_id = p.user_id
LEFT JOIN clients c ON te.client_id = c.id;
```

---

### Fonctions SQL principales

#### `get_operator_daily_rate(p_operator_id, p_client_id)`

Retourne le tarif journalier d'un opérateur pour un client.

```sql
SELECT get_operator_daily_rate(
  'uuid-operateur',
  'uuid-client'
); -- Retourne: 500.00
```

#### `check_operator_client_access(p_operator_id, p_client_id)`

Vérifie si un opérateur a accès à un client.

```sql
SELECT check_operator_client_access(
  'uuid-operateur',
  'uuid-client'
); -- Retourne: true/false
```

#### `get_authorized_clients_for_operator(p_operator_id)`

Retourne les clients autorisés avec leurs tarifs.

```sql
SELECT * FROM get_authorized_clients_for_operator('uuid-operateur');
-- Retourne: client_id, client_name, daily_rate
```

#### `generate_month_calendar(p_year, p_month)`

Génère le calendrier d'un mois.

```sql
SELECT * FROM generate_month_calendar(2025, 11);
-- Retourne: entry_date, day_name, day_number, is_weekend, week_number
```

#### `get_operator_monthly_stats(p_operator_id, p_year, p_month)`

Calcule les statistiques mensuelles d'un opérateur.

```sql
SELECT * FROM get_operator_monthly_stats('uuid-operateur', 2025, 11);
-- Retourne: total_hours, total_amount, total_days, total_entries, avg_hours_per_day
```

#### `get_timesheet_report_by_client(p_year, p_month, p_company_id)`

Rapport consolidé par client.

```sql
SELECT * FROM get_timesheet_report_by_client(2025, 11, NULL);
-- Retourne: client_id, client_name, total_hours, total_amount, operator_count
```

#### `get_timesheet_report_by_operator(p_year, p_month, p_company_id)`

Rapport consolidé par opérateur.

```sql
SELECT * FROM get_timesheet_report_by_operator(2025, 11, NULL);
-- Retourne: operator_id, operator_name, operator_email, total_hours, total_amount, client_count
```

---

## 📊 Modèles de données

### Dart Models (`lib/models/timesheet_models.dart`)

#### `OperatorRate`

```dart
class OperatorRate {
  final String id;
  final String operatorId;
  final String clientId;
  final double dailyRate;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Champs optionnels pour les jointures
  final String? operatorName;
  final String? operatorEmail;
  final String? clientName;
}
```

#### `OperatorClientPermission`

```dart
class OperatorClientPermission {
  final String id;
  final String operatorId;
  final String clientId;
  final bool allowed;
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

#### `TimesheetEntry`

```dart
class TimesheetEntry {
  final String id;
  final String operatorId;
  final String clientId;
  final DateTime entryDate;
  final double hours;
  final String? comment;
  final double dailyRate;
  final double amount; // Calculé automatiquement
  final bool isWeekend;
  final String status; // draft, submitted, approved, rejected
  final String? companyId;
}
```

#### `CalendarDay`

```dart
class CalendarDay {
  final DateTime date;
  final String dayName;
  final int dayNumber;
  final bool isWeekend;
  final int weekNumber;
  TimesheetEntry? entry; // Saisie associée (optionnel)
}
```

#### `MonthlyStats`

```dart
class MonthlyStats {
  final double totalHours;
  final double totalAmount;
  final int totalDays;
  final int totalEntries;
  final double avgHoursPerDay;
}
```

#### `ClientReport` & `OperatorReport`

```dart
class ClientReport {
  final String clientId;
  final String clientName;
  final double totalHours;
  final double totalAmount;
  final int operatorCount;
}

class OperatorReport {
  final String operatorId;
  final String operatorName;
  final String operatorEmail;
  final double totalHours;
  final double totalAmount;
  final int clientCount;
}
```

---

## 🔧 Services

### `TimesheetService` (`lib/services/timesheet_service.dart`)

Service principal contenant toute la logique métier.

#### Gestion des tarifs

```dart
// Récupérer tous les tarifs
List<OperatorRate> rates = await TimesheetService.getAllRates();

// Créer ou mettre à jour un tarif
await TimesheetService.upsertRate(
  operatorId: 'uuid-operateur',
  clientId: 'uuid-client',
  dailyRate: 500.00,
);

// Supprimer un tarif
await TimesheetService.deleteRate('uuid-tarif');

// Récupérer le tarif d'un opérateur pour un client
double rate = await TimesheetService.getDailyRate('uuid-operateur', 'uuid-client');
```

#### Gestion des permissions

```dart
// Récupérer toutes les permissions
List<OperatorClientPermission> perms = await TimesheetService.getAllPermissions();

// Créer ou mettre à jour une permission
await TimesheetService.upsertPermission(
  operatorId: 'uuid-operateur',
  clientId: 'uuid-client',
  allowed: true,
);

// Vérifier l'accès
bool hasAccess = await TimesheetService.checkOperatorAccess('uuid-operateur', 'uuid-client');

// Récupérer les clients autorisés avec leurs tarifs
List<AuthorizedClient> clients = await TimesheetService.getAuthorizedClients('uuid-operateur');
```

#### Gestion des saisies

```dart
// Récupérer les saisies d'un mois
List<TimesheetEntry> entries = await TimesheetService.getMonthlyEntries(
  operatorId: 'uuid-operateur',
  year: 2025,
  month: 11,
);

// Créer une saisie
TimesheetEntry entry = await TimesheetService.createEntry(
  operatorId: 'uuid-operateur',
  clientId: 'uuid-client',
  entryDate: DateTime(2025, 11, 15),
  hours: 7.5,
  comment: 'Développement module timesheet',
  companyId: 'uuid-company',
);

// Mettre à jour une saisie
await TimesheetService.updateEntry(
  entryId: 'uuid-entry',
  hours: 8.0,
  comment: 'Développement + tests',
);

// Supprimer une saisie
await TimesheetService.deleteEntry('uuid-entry');

// Soumettre un mois complet
await TimesheetService.submitMonth(
  operatorId: 'uuid-operateur',
  year: 2025,
  month: 11,
);
```

#### Calendrier

```dart
// Générer le calendrier d'un mois
List<CalendarDay> calendar = await TimesheetService.generateMonthCalendar(
  year: 2025,
  month: 11,
);

// Générer le calendrier avec les saisies
List<CalendarDay> calendarWithEntries = await TimesheetService.getMonthCalendarWithEntries(
  operatorId: 'uuid-operateur',
  year: 2025,
  month: 11,
);
```

#### Statistiques et reporting

```dart
// Statistiques mensuelles d'un opérateur
MonthlyStats stats = await TimesheetService.getOperatorMonthlyStats(
  operatorId: 'uuid-operateur',
  year: 2025,
  month: 11,
);

// Rapport par client
List<ClientReport> clientReport = await TimesheetService.getClientReport(
  year: 2025,
  month: 11,
  companyId: 'uuid-company',
);

// Rapport par opérateur
List<OperatorReport> operatorReport = await TimesheetService.getOperatorReport(
  year: 2025,
  month: 11,
  companyId: 'uuid-company',
);
```

#### Utilitaires

```dart
// Calculer le total d'heures
double totalHours = TimesheetService.calculateTotalHours(entries);

// Calculer le montant total
double totalAmount = TimesheetService.calculateTotalAmount(entries);

// Calculer les totaux hebdomadaires
Map<int, Map<String, double>> weeklyTotals = TimesheetService.calculateWeeklyTotals(entries);

// Valider les heures
bool isValid = TimesheetService.validateHours(7.5); // true
bool isInvalid = TimesheetService.validateHours(25); // false

// Formater un montant
String formatted = TimesheetService.formatAmount(1250.50); // "1250.50 €"

// Formater des heures
String formatted = TimesheetService.formatHours(7.5); // "7.50 h"
```

---

## 🖥️ Interfaces utilisateur

### 1. `TimeEntryPage` - Saisie du temps (Partenaires)

**Route:** `/timesheet/entry`  
**Accès:** Tous les utilisateurs  
**Fichier:** `lib/pages/timesheet/time_entry_page.dart`

#### Fonctionnalités

- 📅 Sélection du mois (navigation mois précédent/suivant)
- 📊 Statistiques mensuelles (heures, montant, jours, moyenne)
- 📝 Tableau de saisie avec calendrier complet du mois
- 🎨 Détection des week-ends (affichage grisé)
- 🔍 Liste déroulante des clients autorisés uniquement
- 💰 Calcul automatique du montant (heures × tarif)
- ✅ Validation (heures max 24h, client obligatoire)
- 💾 Sauvegarde ligne par ligne
- 🗑️ Suppression des saisies en brouillon
- 📤 Soumission du mois complet

#### Captures d'écran

```
┌────────────────────────────────────────────────────────┐
│  ◀ Novembre 2025 ▶                  [Soumettre le mois]│
├────────────────────────────────────────────────────────┤
│  📊 Heures: 152.5h  💰 Montant: 76,250€  📅 Jours: 20  │
├────────────────────────────────────────────────────────┤
│ Date │ Jour │ Client     │ Heures │ Tarif │ Montant │  │
│ 01/11│ Ven  │ [Client A ▼]│ [7.5] │ 500€  │ 3,750€  │✅│
│ 02/11│ Sam  │ -           │ -      │ -     │ -       │  │ (grisé)
│ 03/11│ Dim  │ -           │ -      │ -     │ -       │  │ (grisé)
│ 04/11│ Lun  │ [Client B ▼]│ [8.0] │ 450€  │ 3,600€  │✅│
│ ...  │ ...  │ ...         │ ...    │ ...   │ ...     │  │
└────────────────────────────────────────────────────────┘
```

---

### 2. `TimesheetSettingsPage` - Paramètres (Associés uniquement)

**Route:** `/timesheet/settings`  
**Accès:** Associés uniquement  
**Fichier:** `lib/pages/timesheet/timesheet_settings_page.dart`

#### Fonctionnalités

**Onglet 1: Tarifs journaliers**
- 📋 Liste de tous les tarifs (opérateur, client, tarif)
- ➕ Création de nouveaux tarifs
- ✏️ Modification des tarifs existants
- 🗑️ Suppression de tarifs
- 🔍 Affichage des emails et noms

**Onglet 2: Permissions clients**
- 📋 Liste de toutes les permissions (opérateur, client, autorisé)
- ➕ Création de nouvelles permissions
- ✏️ Modification des permissions (autoriser/interdire)
- 🗑️ Suppression de permissions
- ✅ Badges visuels (✅ OUI / ⛔ NON)

#### Captures d'écran

```
┌────────────────────────────────────────────────────────┐
│  [Tarifs journaliers] [Permissions clients]            │
├────────────────────────────────────────────────────────┤
│ Opérateur      │ Email           │ Client  │ Tarif    │
│ Arnaud Dupuis  │ arnaud@oxo.fr   │ Client A│ 500.00 € │✏️🗑️
│ Benoît Durand  │ benoit@oxo.fr   │ Client B│ 450.00 € │✏️🗑️
│ Claude Damp... │ claude@oxo.fr   │ Client C│ 550.00 € │✏️🗑️
└────────────────────────────────────────────────────────┘
                                            [+ Nouveau tarif]
```

---

### 3. `TimesheetReportingPage` - Reporting (Associés uniquement)

**Route:** `/timesheet/reporting`  
**Accès:** Associés uniquement  
**Fichier:** `lib/pages/timesheet/timesheet_reporting_page.dart`

#### Fonctionnalités

**En-tête:**
- 📅 Sélection du mois
- 📊 Résumé global (heures, montant, clients, opérateurs)
- 📄 Export PDF
- 📊 Export Excel

**Onglet 1: Rapport par client**
- 📋 Tableau consolidé par client
- 📊 Heures totales, montant total
- 👥 Nombre d'opérateurs
- 💰 Tarif moyen (€/h)

**Onglet 2: Rapport par opérateur**
- 📋 Tableau consolidé par opérateur
- 📊 Heures totales, montant total
- 🏢 Nombre de clients
- 💰 Tarif moyen (€/h)

**Onglet 3: Détail des saisies**
- 📋 Liste complète de toutes les saisies
- 📅 Date, opérateur, client
- ⏱️ Heures, tarif, montant
- 📝 Statut, commentaire

#### Captures d'écran

```
┌────────────────────────────────────────────────────────┐
│  ◀ Novembre 2025 ▶        [Export PDF] [Export Excel]  │
├────────────────────────────────────────────────────────┤
│  ⏱️ 1,220h  💰 610,000€  🏢 15 clients  👥 8 opérateurs│
├────────────────────────────────────────────────────────┤
│ [Par client] [Par opérateur] [Détail des saisies]      │
├────────────────────────────────────────────────────────┤
│ Client     │ Heures │ Montant  │ Opérateurs │ Moy €/h │
│ Client A   │ 320.0  │ 160,000€ │ 3          │ 500.00  │
│ Client B   │ 280.5  │ 126,225€ │ 2          │ 450.00  │
│ Client C   │ 240.0  │ 132,000€ │ 2          │ 550.00  │
│ ...        │ ...    │ ...      │ ...        │ ...     │
└────────────────────────────────────────────────────────┘
```

---

## 🔐 Contrôle d'accès

### Politiques RLS (Row Level Security)

Toutes les tables ont RLS activé avec des politiques strictes.

#### `operator_rates`

| Action | Associé | Partenaire |
|--------|---------|-----------|
| SELECT | ✅ Tous | ✅ Ses propres tarifs uniquement |
| INSERT | ✅ Oui | ❌ Non |
| UPDATE | ✅ Oui | ❌ Non |
| DELETE | ✅ Oui | ❌ Non |

#### `operator_client_permissions`

| Action | Associé | Partenaire |
|--------|---------|-----------|
| SELECT | ✅ Tous | ✅ Ses propres permissions uniquement |
| INSERT | ✅ Oui | ❌ Non |
| UPDATE | ✅ Oui | ❌ Non |
| DELETE | ✅ Oui | ❌ Non |

#### `timesheet_entries`

| Action | Associé | Partenaire |
|--------|---------|-----------|
| SELECT | ✅ Tous | ✅ Ses propres saisies uniquement |
| INSERT | ✅ Oui | ✅ Ses propres saisies uniquement |
| UPDATE | ✅ Oui | ✅ Ses propres saisies en brouillon uniquement |
| DELETE | ✅ Oui | ✅ Ses propres saisies en brouillon uniquement |

### Validation des données

#### Côté base de données

- ✅ `hours` : 0 < hours ≤ 24
- ✅ `daily_rate` : ≥ 0
- ✅ `status` : IN ('draft', 'submitted', 'approved', 'rejected')
- ✅ Contraintes d'unicité

#### Côté application

```dart
// Validation des heures
if (!TimesheetService.validateHours(hours)) {
  throw Exception('Heures invalides (max 24h)');
}

// Vérification des permissions
bool hasAccess = await TimesheetService.checkOperatorAccess(operatorId, clientId);
if (!hasAccess) {
  throw Exception('Accès refusé à ce client');
}

// Vérification du statut
if (entry.status != 'draft') {
  throw Exception('Impossible de modifier une saisie soumise');
}
```

---

## 🔄 Workflows

### Workflow 1: Saisie du temps (Partenaire)

```
1. Partenaire se connecte
2. Accède à "Saisie du temps"
3. Sélectionne le mois
4. Pour chaque jour:
   a. Sélectionne un client (liste filtrée par permissions)
   b. Saisit les heures (0-24h)
   c. Ajoute un commentaire (optionnel)
   d. Clique sur "Enregistrer"
   e. Le tarif et le montant sont calculés automatiquement
5. En fin de mois:
   a. Vérifie les totaux
   b. Clique sur "Soumettre le mois"
   c. Les saisies passent en statut "submitted"
   d. Elles ne sont plus modifiables
```

### Workflow 2: Configuration des tarifs (Associé)

```
1. Associé se connecte
2. Accède à "Paramètres Timesheet"
3. Onglet "Tarifs journaliers":
   a. Clique sur "+ Nouveau tarif"
   b. Sélectionne un opérateur
   c. Sélectionne un client
   d. Saisit le tarif journalier
   e. Clique sur "Créer"
4. Le tarif est immédiatement disponible pour les saisies
```

### Workflow 3: Gestion des permissions (Associé)

```
1. Associé se connecte
2. Accède à "Paramètres Timesheet"
3. Onglet "Permissions clients":
   a. Clique sur "+ Nouvelle permission"
   b. Sélectionne un opérateur
   c. Sélectionne un client
   d. Active/désactive l'accès
   e. Clique sur "Créer"
4. L'opérateur voit (ou ne voit plus) ce client dans sa liste
```

### Workflow 4: Consultation des rapports (Associé)

```
1. Associé se connecte
2. Accède à "Reporting Timesheet"
3. Sélectionne le mois
4. Consulte les 3 onglets:
   - Rapport par client
   - Rapport par opérateur
   - Détail des saisies
5. Exporte en PDF ou Excel si nécessaire
```

---

## 🧪 Tests et validation

### Tests manuels recommandés

#### Test 1: Création de tarifs

```
✅ Créer un tarif pour un opérateur et un client
✅ Vérifier que le tarif apparaît dans la liste
✅ Modifier le tarif
✅ Vérifier que la modification est prise en compte
✅ Supprimer le tarif
✅ Vérifier que le tarif a disparu
```

#### Test 2: Permissions

```
✅ Créer une permission "autorisé" pour un opérateur et un client
✅ Se connecter en tant que cet opérateur
✅ Vérifier que le client apparaît dans la liste
✅ Modifier la permission en "refusé"
✅ Vérifier que le client n'apparaît plus dans la liste
```

#### Test 3: Saisie du temps

```
✅ Se connecter en tant que partenaire
✅ Accéder à "Saisie du temps"
✅ Sélectionner un mois
✅ Saisir des heures pour plusieurs jours
✅ Vérifier que les montants sont calculés automatiquement
✅ Vérifier que les totaux sont corrects
✅ Soumettre le mois
✅ Vérifier que les saisies ne sont plus modifiables
```

#### Test 4: Reporting

```
✅ Se connecter en tant qu'associé
✅ Accéder à "Reporting Timesheet"
✅ Vérifier les totaux globaux
✅ Consulter le rapport par client
✅ Consulter le rapport par opérateur
✅ Consulter le détail des saisies
✅ Vérifier la cohérence des données
```

### Tests de sécurité

```
✅ Un partenaire ne peut pas voir les saisies d'un autre partenaire
✅ Un partenaire ne peut pas modifier les tarifs
✅ Un partenaire ne peut pas modifier les permissions
✅ Un partenaire ne peut pas modifier une saisie soumise
✅ Un partenaire ne peut pas saisir plus de 24h par jour
✅ Un partenaire ne peut pas saisir pour un client non autorisé
```

---

## 🔧 Maintenance

### Logs et debugging

Le service utilise `debugPrint` pour tous les logs :

```dart
debugPrint('✅ Tarif créé/mis à jour avec succès');
debugPrint('❌ Erreur getAllRates: $e');
```

### Erreurs courantes

#### Erreur: "Aucune mission dans la base de données"

**Cause:** RLS activé mais pas de données ou permissions incorrectes  
**Solution:** Vérifier les politiques RLS et les données de test

#### Erreur: "Tarif invalide"

**Cause:** Tentative de saisir un tarif négatif  
**Solution:** Valider côté client avant l'envoi

#### Erreur: "Heures invalides (max 24h)"

**Cause:** Tentative de saisir plus de 24h  
**Solution:** Valider avec `TimesheetService.validateHours()`

#### Erreur: "Accès refusé à ce client"

**Cause:** Permission non définie ou refusée  
**Solution:** Vérifier les permissions dans "Paramètres Timesheet"

### Migrations futures

Si vous devez ajouter des colonnes :

```sql
-- Exemple: Ajouter une colonne "overtime_rate"
ALTER TABLE operator_rates ADD COLUMN overtime_rate NUMERIC(10,2) DEFAULT 0;

-- Mettre à jour les modèles Dart
class OperatorRate {
  // ...
  final double overtimeRate;
}
```

### Optimisations possibles

1. **Cache des tarifs** : Mettre en cache les tarifs fréquemment utilisés
2. **Pagination** : Paginer les listes longues (>100 entrées)
3. **Indexes supplémentaires** : Ajouter des indexes si les requêtes sont lentes
4. **Matérialized views** : Créer des vues matérialisées pour les rapports

---

## 📞 Support

Pour toute question ou problème :

1. Consultez cette documentation
2. Vérifiez les logs dans la console
3. Vérifiez les politiques RLS dans Supabase
4. Testez les fonctions SQL directement dans Supabase SQL Editor

---

## 📝 Changelog

### Version 1.0 (1er novembre 2025)

- ✅ Création du module complet
- ✅ Schéma de base de données
- ✅ Modèles Dart
- ✅ Service métier
- ✅ 3 interfaces utilisateur
- ✅ Politiques RLS
- ✅ Documentation complète

---

## 🎉 Félicitations !

Le module **OXO TIME SHEETS** est maintenant opérationnel. Vous disposez d'un système complet de gestion du temps de travail, moderne, sécurisé et évolutif.

**Prochaines étapes recommandées:**

1. ✅ Exécuter le script SQL
2. ✅ Tester l'application
3. ✅ Créer des données de test
4. ✅ Former les utilisateurs
5. ✅ Déployer en production

**Bon courage ! 🚀**



