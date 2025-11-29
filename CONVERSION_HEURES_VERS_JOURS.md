# 🔄 Conversion : Heures → Journées/Demi-journées

## 📋 Objectif

Modifier le module timesheet pour utiliser des **journées** (1.0) et **demi-journées** (0.5) au lieu d'heures.

---

## ✅ Modifications appliquées

### 1. **Base de données** ✅

**Fichier** : `supabase/update_timesheet_to_days.sql`

**Modifications** :
- ✅ Renommé `hours` → `days`
- ✅ Contrainte modifiée : `CHECK (days IN (0.5, 1.0))`
- ✅ Vue `timesheet_entries_detailed` recréée
- ✅ Fonctions SQL mises à jour :
  - `get_partner_monthly_stats` : `total_hours` → `total_days`
  - `get_timesheet_report_by_client` : `total_hours` → `total_days`
  - `get_timesheet_report_by_partner` : `total_hours` → `total_days`

---

### 2. **Modèles Dart** ✅

**Fichier** : `lib/models/timesheet_models.dart`

**Modifications** :

#### `TimesheetEntry`
- ✅ `final double hours` → `final double days`
- ✅ `fromJson` : `json['hours']` → `json['days']`
- ✅ `toJson` : `'hours': hours` → `'days': days`
- ✅ `copyWith` : `double? hours` → `double? days`

#### `MonthlyStats`
- ✅ `totalHours` → `totalDays`
- ✅ `avgHoursPerDay` → `avgDaysPerEntry`
- ✅ `fromJson` mis à jour

#### `ClientReport`
- ✅ `totalHours` → `totalDays`
- ✅ `operatorCount` → `partnerCount`

#### `PartnerReport`
- ✅ `totalHours` → `totalDays`

---

### 3. **Service Dart** ⏳ (À faire)

**Fichier** : `lib/services/timesheet_service.dart`

**Modifications nécessaires** :

| Ligne | Avant | Après |
|-------|-------|-------|
| 273 | `required double hours` | `required double days` |
| 289 | `'hours': hours` | `'days': days` |
| 315 | `double? hours` | `double? days` |
| 323 | `if (hours != null) updates['hours'] = hours` | `if (days != null) updates['days'] = days` |
| 432 | `hours: 0` | `days: 0` |
| 531 | `sum + entry.hours` | `sum + entry.days` |
| 548-552 | `'hours': 0.0` et `entry.hours` | `'days': 0.0` et `entry.days` |
| 568-569 | `validateHours(double hours)` → `return hours > 0 && hours <= 24` | `validateDays(double days)` → `return days == 0.5 || days == 1.0` |
| 578-579 | `formatHours(double hours)` → `'${hours.toStringAsFixed(2)} h'` | `formatDays(double days)` → `days == 0.5 ? 'Demi-journée' : 'Journée'` |

---

### 4. **Pages UI** ⏳ (À faire)

**Fichiers à modifier** :

#### `lib/pages/timesheet/time_entry_page.dart`
- Remplacer le champ de saisie d'heures par un sélecteur :
  - Radio buttons ou SegmentedButton
  - Options : "Demi-journée" (0.5) ou "Journée complète" (1.0)
- Mettre à jour les labels et textes

#### `lib/pages/timesheet/timesheet_settings_page.dart`
- Mettre à jour les labels : "heures" → "jours"
- Adapter les affichages de statistiques

#### `lib/pages/timesheet/timesheet_reporting_page.dart`
- Mettre à jour les colonnes de tableaux
- Adapter les totaux et moyennes
- Changer "Total heures" → "Total jours"

---

## 🚀 Exécution

### Étape 1 : Mettre à jour la base de données

```sql
-- Exécuter dans Supabase SQL Editor
-- Fichier : supabase/update_timesheet_to_days.sql
```

### Étape 2 : Vérifier les modifications

```sql
-- Vérifier la structure
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'timesheet_entries'
  AND column_name = 'days';

-- Vérifier les contraintes
SELECT constraint_name, check_clause
FROM information_schema.check_constraints
WHERE constraint_name LIKE '%timesheet_entries%';
```

### Étape 3 : Relancer l'application

```bash
flutter run
```

---

## 📊 Impact

### Avant
- Saisie en heures (0.1 à 24.0)
- Affichage : "8.5 h"
- Calcul : `amount = hours × daily_rate`

### Après
- Saisie en jours (0.5 ou 1.0)
- Affichage : "Demi-journée" ou "Journée"
- Calcul : `amount = days × daily_rate`

---

## ⚠️ Points d'attention

1. **Données existantes** : Si des données existent déjà avec des heures, elles seront perdues lors du `RENAME COLUMN`. Sauvegardez d'abord si nécessaire.

2. **Validation** : La nouvelle contrainte n'accepte que 0.5 ou 1.0. Toute autre valeur sera rejetée.

3. **UI** : L'interface doit être adaptée pour proposer uniquement ces 2 choix.

---

## ✅ Checklist

- [x] Script SQL créé
- [x] Modèles Dart modifiés
- [ ] Service Dart modifié
- [ ] Page de saisie modifiée
- [ ] Page de paramètres modifiée
- [ ] Page de reporting modifiée
- [ ] Tests effectués

---

**Date** : 1er novembre 2025  
**Statut** : 🔄 En cours (50% complété)


