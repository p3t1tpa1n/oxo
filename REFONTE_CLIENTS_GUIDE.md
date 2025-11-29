# 🏗️ Guide de Refonte du Système Clients - OXO TIME SHEETS

## 📋 Table des Matières

1. [Vue d'ensemble](#vue-densemble)
2. [Nouvelle architecture](#nouvelle-architecture)
3. [Scripts SQL](#scripts-sql)
4. [Migration des données](#migration-des-données)
5. [Impact sur l'application](#impact-sur-lapplication)
6. [Plan d'action](#plan-daction)

---

## 🎯 Vue d'ensemble

### Problème Initial
- Chaque mission était liée directement à un "client"
- Pas de distinction entre **groupe investisseur** et **société opérationnelle**
- Reporting complexe pour les groupes avec plusieurs filiales

### Solution
Hiérarchie à 4 niveaux :
```
Groupe d'Investissement (investor_group)
    ↓
Société d'Exploitation (company)
    ↓
Mission (missions)
    ↓
Saisie de Temps (timesheet_entries)
```

### Exemple Concret
```
Bpifrance Investissement (groupe)
├── Ecometrix (société) → Lyon
│   ├── Mission 1: Audit énergétique
│   │   ├── Saisie 01/02: 1.0j
│   │   └── Saisie 02/02: 0.5j
│   └── Mission 2: Conseil stratégique
│       └── Saisie 03/02: 1.0j
└── Enerbiotech (société) → Paris
    └── Mission 3: R&D biomasse
        └── Saisie 01/02: 1.0j
```

---

## 🧩 Nouvelle Architecture

### 1️⃣ Table `investor_group`
**Rôle:** Groupe d'investissement, fonds, holding

| Champ | Type | Description |
|-------|------|-------------|
| `id` | BIGSERIAL | Identifiant unique |
| `name` | VARCHAR(255) | Nom du groupe (unique) |
| `sector` | VARCHAR(100) | Secteur d'activité |
| `country` | VARCHAR(100) | Pays (défaut: France) |
| `contact_main` | VARCHAR(255) | Email de contact principal |
| `phone` | VARCHAR(50) | Téléphone |
| `website` | VARCHAR(255) | Site web |
| `notes` | TEXT | Notes internes |
| `logo_url` | VARCHAR(500) | URL du logo |
| `active` | BOOLEAN | Actif (défaut: true) |
| `created_at` | TIMESTAMPTZ | Date de création |
| `updated_at` | TIMESTAMPTZ | Date de mise à jour |

**Exemples:**
- Bpifrance Investissement
- Raise Impact
- Sofinnova Partners

---

### 2️⃣ Table `company`
**Rôle:** Société d'exploitation (filiale, PME, startup)

| Champ | Type | Description |
|-------|------|-------------|
| `id` | BIGSERIAL | Identifiant unique |
| `name` | VARCHAR(255) | Nom de la société |
| `group_id` | BIGINT FK | Groupe propriétaire |
| `city` | VARCHAR(100) | Ville |
| `postal_code` | VARCHAR(20) | Code postal |
| `sector` | VARCHAR(100) | Secteur d'activité |
| `ownership_share` | DECIMAL(5,2) | Part de détention (%) |
| `siret` | VARCHAR(14) | SIRET |
| `contact_name` | VARCHAR(255) | Nom du contact |
| `contact_email` | VARCHAR(255) | Email du contact |
| `contact_phone` | VARCHAR(50) | Téléphone |
| `active` | BOOLEAN | Active (défaut: true) |
| `notes` | TEXT | Notes internes |
| `created_at` | TIMESTAMPTZ | Date de création |
| `updated_at` | TIMESTAMPTZ | Date de mise à jour |

**Exemples:**
- Ecometrix (Bpifrance → 72.5%)
- Enerbiotech (Bpifrance → 45%)
- GreenTech Solutions (Raise Impact → 80%)

---

### 3️⃣ Table `missions` (modifiée)
**Rôle:** Projet confié à une société

**Nouvelle colonne:**
- `company_id` BIGINT FK → `company.id`

**Ancienne colonne (à supprimer après migration):**
- `client_id` (remplacée par `company_id`)

---

### 4️⃣ Table `timesheet_entries` (modifiée)
**Rôle:** Saisie de temps sur une mission

**Nouvelle colonne:**
- `mission_id` UUID FK → `missions.id`

**Ancienne colonne (à supprimer après migration):**
- `client_id` (remplacée par `mission_id`)

---

## 📊 Vues et Fonctions

### Vue `company_with_group`
Société avec détails du groupe

```sql
SELECT * FROM company_with_group WHERE company_name = 'Ecometrix';
```

**Retour:**
- `company_id`, `company_name`, `city`, `company_sector`
- `group_id`, `group_name`, `group_sector`, `country`

---

### Vue `mission_with_context`
Mission avec société, groupe et partenaire

```sql
SELECT * FROM mission_with_context WHERE partner_id = '...';
```

**Retour:**
- Mission: `mission_id`, `mission_title`, `status`, `daily_rate`
- Société: `company_id`, `company_name`, `city`
- Groupe: `group_id`, `group_name`, `group_sector`
- Partenaire: `partner_id`, `partner_email`, `partner_first_name`

---

### Vue `timesheet_entry_with_context`
Saisie avec mission, société et groupe

```sql
SELECT * FROM timesheet_entry_with_context 
WHERE EXTRACT(MONTH FROM entry_date) = 11;
```

---

### Fonction `get_missions_by_partner(partner_id)`
Liste des missions actives d'un partenaire

```sql
SELECT * FROM get_missions_by_partner('uuid-du-partenaire');
```

---

### Fonction `get_available_missions_for_timesheet(partner_id, date)`
Missions disponibles pour saisie du temps

```sql
SELECT * FROM get_available_missions_for_timesheet(
    'uuid-du-partenaire',
    '2025-02-03'::DATE
);
```

**Critères:**
- `status = 'in_progress'`
- `start_date <= date`
- `end_date IS NULL` OU `end_date >= date`

---

### Fonction `get_timesheet_report_by_group(year, month, company_id?)`
Rapport consolidé par groupe

```sql
SELECT * FROM get_timesheet_report_by_group(2025, 2);
```

**Retour:**
- `group_name`
- `total_days`, `total_amount`
- `company_count`, `mission_count`

---

## 🔄 Migration des Données

### Étape 1: Créer les nouvelles tables
```bash
psql -U postgres -d oxo -f supabase/refonte_clients_hierarchie.sql
```

### Étape 2: Vérifier les données de test
```sql
SELECT * FROM investor_group;
SELECT * FROM company;
SELECT * FROM company_with_group;
```

### Étape 3: Migrer les anciennes données
```bash
psql -U postgres -d oxo -f supabase/migration_anciennes_donnees.sql
```

### Étape 4: Vérifier la migration
```sql
-- Saisies sans mission (devrait être 0)
SELECT COUNT(*) FROM timesheet_entries WHERE mission_id IS NULL;

-- Résumé par groupe
SELECT 
    ig.name AS groupe,
    COUNT(DISTINCT c.id) AS nb_societes,
    COUNT(DISTINCT m.id) AS nb_missions
FROM investor_group ig
LEFT JOIN company c ON c.group_id = ig.id
LEFT JOIN missions m ON m.company_id = c.id
GROUP BY ig.name;
```

### Étape 5: Nettoyage (après validation)
```sql
-- Supprimer les anciennes colonnes
ALTER TABLE timesheet_entries DROP COLUMN IF EXISTS client_id;
ALTER TABLE missions DROP COLUMN IF EXISTS client_id;
```

---

## 💻 Impact sur l'Application Flutter

### Modifications Dart Nécessaires

#### 1. Nouveaux modèles

**`lib/models/investor_group.dart`**
```dart
class InvestorGroup {
  final int id;
  final String name;
  final String? sector;
  final String? country;
  final String? contactMain;
  final bool active;
  
  InvestorGroup({...});
  
  factory InvestorGroup.fromJson(Map<String, dynamic> json) {...}
}
```

**`lib/models/company.dart`**
```dart
class Company {
  final int id;
  final String name;
  final int groupId;
  final String? groupName; // depuis la vue
  final String? city;
  final String? sector;
  final double? ownershipShare;
  final bool active;
  
  Company({...});
  
  factory Company.fromJson(Map<String, dynamic> json) {...}
}
```

**`lib/models/mission.dart`**
```dart
class Mission {
  final String id;
  final String title;
  final int? companyId;       // Nouveau
  final String? companyName;  // Depuis la vue
  final int? groupId;         // Depuis la vue
  final String? groupName;    // Depuis la vue
  final String? partnerId;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final double? dailyRate;
  
  Mission({...});
  
  factory Mission.fromJson(Map<String, dynamic> json) {...}
}
```

---

#### 2. Nouveaux services

**`lib/services/company_service.dart`**
```dart
class CompanyService {
  static Future<List<Company>> getAllCompanies() async {
    final response = await SupabaseService.client
        .from('company_with_group')
        .select()
        .eq('company_active', true)
        .order('company_name');
    
    return (response as List)
        .map((json) => Company.fromJson(json))
        .toList();
  }
  
  static Future<List<Company>> getCompaniesByGroup(int groupId) async {
    final response = await SupabaseService.client
        .from('company_with_group')
        .select()
        .eq('group_id', groupId)
        .eq('company_active', true);
    
    return (response as List)
        .map((json) => Company.fromJson(json))
        .toList();
  }
}
```

**`lib/services/mission_service.dart`**
```dart
class MissionService {
  static Future<List<Mission>> getMissionsForTimesheet(String partnerId) async {
    final response = await SupabaseService.client
        .rpc('get_available_missions_for_timesheet', params: {
          'p_partner_id': partnerId,
          'p_date': DateTime.now().toIso8601String().split('T')[0],
        });
    
    return (response as List)
        .map((json) => Mission.fromJson(json))
        .toList();
  }
}
```

---

#### 3. Mise à jour de la saisie du temps

**`lib/pages/timesheet/time_entry_page.dart`**

**Avant:**
```dart
// Sélection de client
DropdownButton<String>(
  hint: Text('Client...'),
  items: _authorizedClients.map((client) => ...),
  onChanged: (clientId) => ...
)
```

**Après:**
```dart
// Sélection de mission (avec contexte: société + groupe)
DropdownButton<String>(
  hint: Text('Mission...'),
  items: _availableMissions.map((mission) => 
    DropdownMenuItem(
      value: mission.id,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(mission.title, style: TextStyle(fontWeight: FontWeight.bold)),
          Text('${mission.companyName} (${mission.groupName})', 
               style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    ),
  ).toList(),
  onChanged: (missionId) => ...
)
```

---

## 📅 Plan d'Action

### Phase 1: Préparation (1 jour)
- [ ] Backup complet de la base de données
- [ ] Exécuter `refonte_clients_hierarchie.sql` sur environnement de test
- [ ] Vérifier la création des tables et vues
- [ ] Tester les fonctions SQL

### Phase 2: Migration des données (1 jour)
- [ ] Adapter `migration_anciennes_donnees.sql` selon vos données
- [ ] Exécuter la migration sur environnement de test
- [ ] Vérifier l'intégrité des données
- [ ] Tester les requêtes sur les vues

### Phase 3: Mise à jour de l'application (2-3 jours)
- [ ] Créer les nouveaux modèles Dart (`InvestorGroup`, `Company`, `Mission`)
- [ ] Créer les services (`CompanyService`, `MissionService`)
- [ ] Mettre à jour `TimeEntryPage` pour utiliser les missions
- [ ] Mettre à jour `TimesheetReportingPage` pour les nouveaux rapports
- [ ] Créer une page de gestion des groupes/sociétés (admin)

### Phase 4: Tests (1 jour)
- [ ] Tester la saisie du temps avec missions
- [ ] Tester les rapports consolidés par groupe
- [ ] Tester la création/modification de sociétés
- [ ] Tester les permissions (RLS)

### Phase 5: Déploiement (1 jour)
- [ ] Exécuter les scripts SQL en production
- [ ] Déployer la nouvelle version de l'application
- [ ] Monitorer les logs
- [ ] Former les utilisateurs

---

## 🎯 Bénéfices de la Refonte

### Pour les Utilisateurs
✅ Sélection de mission plus claire (contexte société + groupe visible)
✅ Reporting consolidé par groupe d'investissement
✅ Meilleure traçabilité (mission → société → groupe)

### Pour l'Architecture
✅ Modèle de données plus robuste et évolutif
✅ Séparation claire des concepts (groupe ≠ société ≠ mission)
✅ Rapports SQL plus puissants (vues consolidées)
✅ Prêt pour facturation multi-niveaux (groupe → société → mission)

### Pour le Métier
✅ Alignement avec la réalité des investissements
✅ Possibilité de tracking par portefeuille (groupe)
✅ Reporting adapté aux besoins des fonds d'investissement

---

## ❓ FAQ

**Q: Que deviennent mes anciens "clients" ?**
R: Ils sont migrés vers la table `company` et rattachés au groupe "Clients Historiques".

**Q: Mes anciennes saisies de temps sont-elles perdues ?**
R: Non, une mission "Migration" est créée automatiquement pour chaque client/partenaire.

**Q: Puis-je avoir une société sans groupe ?**
R: Oui, `group_id` peut être NULL. La société est alors "indépendante".

**Q: Comment gérer une société détenue par plusieurs groupes ?**
R: Pour l'instant, une société = un groupe. Pour co-investissement, créer une société par groupe ou un groupe "Co-inv X+Y".

**Q: Les RLS sont-elles en place ?**
R: Oui, lecture publique (authentifiés), écriture admin/associé uniquement.

---

## 📞 Support

Pour toute question sur la migration :
1. Consulter ce guide
2. Tester sur environnement de développement
3. Vérifier les logs SQL (`RAISE NOTICE`)
4. Contacter l'équipe technique

---

**Date de création:** 4 novembre 2025
**Version:** 1.0
**Auteur:** OXO Development Team






