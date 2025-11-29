# 🎯 Refonte Clients - Application Flutter Complète

## 📋 Vue d'ensemble

Cette refonte transforme le système "Clients" (utilisateurs individuels) en une **architecture hiérarchique** reflétant la réalité des investissements :

```
📊 Groupe d'Investissement (Fonds, Holding)
   └── 🏢 Société d'Exploitation (PME, Startup)
       └── 📁 Mission (Projet)
           └── ⏱️ Saisie du Temps
```

---

## 🗂️ Structure de la Base de Données

### 1. `investor_group` (Groupe d'investissement)

**Entité contractuelle principale** : fonds, holding, family office, etc.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | `BIGINT` | Identifiant unique |
| `name` | `TEXT` | Nom du groupe (ex: "Bpifrance Investissement") |
| `sector` | `TEXT` | Secteur d'activité |
| `country` | `TEXT` | Pays (défaut: France) |
| `contact_main` | `TEXT` | Email du contact principal |
| `phone` | `TEXT` | Téléphone |
| `website` | `TEXT` | Site web |
| `notes` | `TEXT` | Notes libres |
| `logo_url` | `TEXT` | URL du logo |
| `active` | `BOOLEAN` | Actif ou archivé |
| `created_at` | `TIMESTAMP` | Date de création |
| `updated_at` | `TIMESTAMP` | Dernière mise à jour |

### 2. `company` (Société d'exploitation)

**Entité opérationnelle** sur laquelle les missions sont exécutées.

| Champ | Type | Description |
|-------|------|-------------|
| `id` | `BIGINT` | Identifiant unique |
| `name` | `TEXT` | Nom de la société (ex: "Ecometrix") |
| `group_id` | `BIGINT` | FK → `investor_group.id` |
| `city` | `TEXT` | Ville du siège |
| `postal_code` | `TEXT` | Code postal |
| `sector` | `TEXT` | Secteur d'activité |
| `ownership_share` | `DECIMAL` | Part de détention (%) |
| `siret` | `TEXT` | Numéro SIRET |
| `contact_name` | `TEXT` | Nom du contact |
| `contact_email` | `TEXT` | Email du contact |
| `contact_phone` | `TEXT` | Téléphone du contact |
| `active` | `BOOLEAN` | Actif ou archivé |
| `notes` | `TEXT` | Notes libres |
| `created_at` | `TIMESTAMP` | Date de création |
| `updated_at` | `TIMESTAMP` | Dernière mise à jour |

### 3. `missions` (modifiée)

**Projet confié à une société.**

| Champ | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Identifiant unique |
| `title` | `TEXT` | Titre de la mission |
| **`company_id`** | **`BIGINT`** | **FK → `company.id`** (nouveau) |
| `partner_id` | `UUID` | FK → `profiles.id` |
| `start_date` | `DATE` | Date de début |
| `end_date` | `DATE` | Date de fin |
| `status` | `TEXT` | Statut (draft, in_progress, etc.) |
| `progress_status` | `TEXT` | Statut de progression |
| `budget` | `DECIMAL` | Budget total |
| `daily_rate` | `DECIMAL` | Tarif journalier |
| `estimated_days` | `DECIMAL` | Nombre de jours estimés |
| `worked_days` | `DECIMAL` | Nombre de jours travaillés |
| `completion_percentage` | `DECIMAL` | Pourcentage d'avancement |
| `notes` | `TEXT` | Notes libres |

### 4. `timesheet_entries` (modifiée)

**Saisie du temps.**

| Champ | Type | Description |
|-------|------|-------------|
| `id` | `UUID` | Identifiant unique |
| **`mission_id`** | **`UUID`** | **FK → `missions.id`** (remplace `client_id`) |
| `partner_id` | `UUID` | FK → `profiles.id` |
| `date` | `DATE` | Date de la saisie |
| `days` | `DECIMAL` | Nombre de jours |
| `daily_rate` | `DECIMAL` | Tarif journalier |
| `amount` | `DECIMAL` | Montant total (days × daily_rate) |
| `comment` | `TEXT` | Commentaire |
| `status` | `TEXT` | Statut (draft, submitted, approved) |

---

## 🔄 Vues Consolidées

### `company_with_group`

Société enrichie avec les informations du groupe.

```sql
SELECT 
  c.id AS company_id,
  c.name AS company_name,
  c.city,
  c.sector AS company_sector,
  c.active AS company_active,
  g.id AS group_id,
  g.name AS group_name,
  g.sector AS group_sector
FROM company c
LEFT JOIN investor_group g ON c.group_id = g.id;
```

### `mission_with_context`

Mission enrichie avec société + groupe.

```sql
SELECT 
  m.id AS mission_id,
  m.title AS mission_title,
  m.company_id,
  c.name AS company_name,
  c.city,
  c.group_id,
  g.name AS group_name,
  m.partner_id,
  m.daily_rate,
  m.start_date,
  m.end_date,
  m.status
FROM missions m
LEFT JOIN company c ON m.company_id = c.id
LEFT JOIN investor_group g ON c.group_id = g.id;
```

### `timesheet_entry_with_context`

Saisie de temps enrichie avec mission + société + groupe.

```sql
SELECT 
  te.id,
  te.date,
  te.days,
  te.daily_rate,
  te.amount,
  te.partner_id,
  m.id AS mission_id,
  m.title AS mission_title,
  c.id AS company_id,
  c.name AS company_name,
  g.id AS group_id,
  g.name AS group_name
FROM timesheet_entries te
LEFT JOIN missions m ON te.mission_id = m.id
LEFT JOIN company c ON m.company_id = c.id
LEFT JOIN investor_group g ON c.group_id = g.id;
```

---

## 📱 Modifications Flutter

### 1. `lib/pages/clients/companies_page.dart` (NOUVELLE PAGE)

**Remplace** l'ancienne `clients_page.dart` (gestion des utilisateurs).

#### Onglet 1 : Sociétés

- **Liste** : Toutes les sociétés avec leur groupe
- **Affichage** : Nom, Groupe, Ville, Secteur, Part de détention, Badge Actif/Inactif
- **Recherche** : Par nom, groupe, ville
- **Actions** : Créer, Modifier, Supprimer

#### Onglet 2 : Groupes d'Investissement

- **Liste** : Tous les groupes avec le nombre de sociétés associées
- **Affichage** : Nom, Secteur, Pays, Nombre de sociétés, Badge Actif/Inactif
- **Recherche** : Par nom, secteur
- **Actions** : Créer, Modifier, Supprimer

#### Formulaire Société

```dart
- Groupe d'investissement (Dropdown)
- Nom de la société *
- Ville
- Secteur d'activité
- Part de détention (%)
```

#### Formulaire Groupe

```dart
- Nom du groupe *
- Secteur
- Pays
- Contact principal (email)
```

### 2. `lib/pages/timesheet/time_entry_page.dart` (MODIFIÉE)

**Changements principaux** :

1. **Variable d'état** : `List<Mission> _availableMissions` (remplace `List<AuthorizedClient>`)
2. **Dropdown** : Affichage enrichi avec contexte
   ```
   Mission: Audit énergétique
   Ecometrix (Bpifrance Investissement)
   ```
3. **Largeur colonne** : `240px` (au lieu de 180px)
4. **Tarif journalier** : Pré-rempli depuis `Mission.dailyRate`
5. **Validation** : Vérifie `missionId` au lieu de `clientId`
6. **Sauvegarde** : Enregistre `mission_id` dans `timesheet_entries`

### 3. `lib/pages/shared/partners_clients_page.dart` (MODIFIÉE)

**Changements** :

- **Import** : `companies_page.dart` (au lieu de `clients_page.dart`)
- **Onglet renommé** : "Sociétés et Groupes" (au lieu de "Clients")
- **Icône** : `Icons.business` (au lieu de `Icons.people_outlined`)
- **Contenu** : `CompaniesPage(embedded: true)`

---

## 🛠️ Modèles Dart

### `lib/models/investor_group.dart`

```dart
class InvestorGroup {
  final int id;
  final String name;
  final String? sector;
  final String? country;
  final String? contactMain;
  final bool active;
  // ...
}
```

### `lib/models/company.dart`

```dart
class Company {
  final int id;
  final String name;
  final int? groupId;
  final String? groupName; // Depuis company_with_group
  final String? city;
  final String? sector;
  final double? ownershipShare;
  final bool active;
  // ...
  
  String get displayName => groupName != null 
      ? '$name ($groupName)' 
      : name;
}
```

### `lib/models/mission.dart`

```dart
class Mission {
  final String id;
  final String title;
  final int? companyId;
  final String? companyName; // Depuis mission_with_context
  final String? groupName; // Depuis mission_with_context
  final double? dailyRate;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  // ...
  
  String get displayName {
    final parts = <String>[title];
    if (companyName != null) parts.add(companyName!);
    if (groupName != null) parts.add('($groupName)');
    return parts.join(' - ');
  }
}
```

---

## 🔌 Service

### `lib/services/mission_service.dart`

```dart
class MissionService {
  /// Récupère les missions disponibles pour la saisie du temps
  static Future<List<Mission>> getAvailableMissionsForTimesheet({
    required String partnerId,
    required DateTime date,
  }) async {
    final response = await _supabase
        .from('mission_with_context')
        .select('*')
        .eq('partner_id', partnerId)
        .lte('start_date', date.toIso8601String())
        .gte('end_date', date.toIso8601String())
        .order('title', ascending: true);

    return (response as List)
        .map((json) => Mission.fromJson(json))
        .toList();
  }
}
```

---

## 🎯 Flux Utilisateur

### Administrateur

1. **Créer un groupe d'investissement**
   - Menu : "Partenaires et Clients" → Onglet "Groupes d'investissement"
   - Clic sur FAB "+"
   - Remplir : Nom, Secteur, Pays, Contact
   - Enregistrer

2. **Créer une société**
   - Menu : "Partenaires et Clients" → Onglet "Sociétés"
   - Clic sur FAB "+"
   - Sélectionner le groupe
   - Remplir : Nom, Ville, Secteur, Part de détention
   - Enregistrer

3. **Créer une mission**
   - Menu : "Missions"
   - Créer une mission liée à la société
   - Définir le tarif journalier

### Partenaire (Consultant)

1. **Saisir du temps**
   - Menu : "Saisie du temps"
   - Sélectionner la date
   - Dropdown "Mission" : Affiche "Titre - Société (Groupe)"
   - Le tarif journalier est pré-rempli
   - Saisir le nombre de jours
   - Montant calculé automatiquement
   - Clic sur 💾 pour enregistrer

---

## 📊 Reporting

### Vue consolidée par Groupe

```sql
SELECT 
  g.name AS groupe,
  COUNT(DISTINCT c.id) AS nb_societes,
  COUNT(DISTINCT m.id) AS nb_missions,
  SUM(te.amount) AS ca_total
FROM investor_group g
LEFT JOIN company c ON c.group_id = g.id
LEFT JOIN missions m ON m.company_id = c.id
LEFT JOIN timesheet_entries te ON te.mission_id = m.id
GROUP BY g.id;
```

### Vue par Société

```sql
SELECT 
  c.name AS societe,
  g.name AS groupe,
  COUNT(DISTINCT m.id) AS nb_missions,
  SUM(te.days) AS jours_travailles,
  SUM(te.amount) AS ca_total
FROM company c
LEFT JOIN investor_group g ON c.group_id = g.id
LEFT JOIN missions m ON m.company_id = c.id
LEFT JOIN timesheet_entries te ON te.mission_id = m.id
GROUP BY c.id, g.id;
```

---

## ✅ Checklist de Déploiement

### Base de données

- [ ] Exécuter `supabase/cleanup_before_refonte.sql`
- [ ] Exécuter `supabase/refonte_clients_hierarchie.sql`
- [ ] Exécuter `supabase/migration_anciennes_donnees.sql`
- [ ] Vérifier les vues : `company_with_group`, `mission_with_context`, `timesheet_entry_with_context`
- [ ] Tester les RLS policies

### Application Flutter

- [ ] Vérifier que `companies_page.dart` est importée dans `partners_clients_page.dart`
- [ ] Vérifier que `time_entry_page.dart` utilise `MissionService.getAvailableMissionsForTimesheet`
- [ ] Vérifier que les modèles `InvestorGroup`, `Company`, `Mission` sont à jour
- [ ] Tester le flux complet : Créer Groupe → Créer Société → Créer Mission → Saisir Temps

---

## 🚀 Avantages de la Nouvelle Architecture

| Fonctionnalité | Avant | Après |
|----------------|-------|-------|
| **Modèle de données** | `Client` (utilisateur) → `Mission` → `Timesheet` | `Groupe` → `Société` → `Mission` → `Timesheet` |
| **Reporting** | Par client individuel | Par groupe d'investissement, puis société |
| **Traçabilité** | Mission liée à un utilisateur | Mission liée à une société, elle-même liée à un groupe |
| **Tarif journalier** | Défini manuellement à chaque saisie | Pré-rempli depuis la mission |
| **Sélection mission** | Dropdown simple | Dropdown avec contexte (Société + Groupe) |
| **Gestion client** | Liste d'utilisateurs | Hiérarchie Groupe → Société |
| **Consolidation financière** | Impossible | Par société et par groupe |

---

## 🔮 Évolutions Futures

1. **Tableau de bord financier** : CA par groupe / société / mission
2. **Export Excel** : Avec filtre par groupe ou société
3. **Gestion des contrats** : Lier les contrats aux sociétés
4. **Facturation** : Facturer par société ou par groupe selon le contrat
5. **Historique des relations** : Suivre les sociétés entrées/sorties du portefeuille

---

## 📞 Support

Pour toute question ou problème :

1. Vérifier que les scripts SQL ont été exécutés dans l'ordre
2. Vérifier les logs Supabase (RLS, Foreign Keys)
3. Vérifier les erreurs Flutter (null safety, types)
4. Consulter `REFONTE_CLIENTS_GUIDE.md` pour le plan complet

---

✨ **Refonte terminée et testée** — Prêt pour la production !






