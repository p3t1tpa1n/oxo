# 🚀 Modifications UI Rapides - Jours/Demi-journées

## ✅ Modifications SQL et Modèles : TERMINÉES

- ✅ Base de données : `hours` → `days`
- ✅ Modèles Dart : `TimesheetEntry.hours` → `TimesheetEntry.days`
- ✅ Service : Toutes les fonctions mises à jour

---

## ⏳ Modifications UI Restantes

### 1. `lib/pages/timesheet/time_entry_page.dart`

**Remplacements globaux** :

| Rechercher | Remplacer par |
|------------|---------------|
| `.hours` | `.days` |
| `totalHours` | `totalDays` |
| `avgHoursPerDay` | `avgDaysPerEntry` |
| `formatHours` | `formatDays` |
| `'Heures totales'` | `'Jours totaux'` |
| `'Moyenne/jour'` | `'Moyenne/entrée'` |

**Modifications spécifiques** :

Ligne 101-103 : Remplacer le TextEditingController par un SegmentedButton ou DropdownButton
```dart
// AVANT
_hoursControllers[key] = TextEditingController(
  text: day.entry!.hours > 0 ? day.entry!.hours.toString() : '',
);

// APRÈS - Option simple : Dropdown
_selectedDays[key] = day.entry!.days > 0 ? day.entry!.days : null;
```

---

### 2. `lib/pages/timesheet/timesheet_reporting_page.dart`

**Remplacements globaux** :

| Rechercher | Remplacer par |
|------------|---------------|
| `.totalHours` | `.totalDays` |
| `operatorCount` | `partnerCount` |
| `'Total heures'` | `'Total jours'` |
| `'Heures'` | `'Jours'` |

---

## 🎯 Solution Rapide : Rechercher/Remplacer Global

### Dans VS Code / Cursor :

1. **Cmd+Shift+F** (recherche globale)
2. Activer **Regex** (icône `.*`)
3. Rechercher : `\.hours\b`
4. Remplacer par : `.days`
5. **Replace All** dans les fichiers concernés

Répéter pour chaque remplacement.

---

## 📝 Checklist Rapide

- [ ] `time_entry_page.dart` : Remplacer `.hours` → `.days` (4 occurrences)
- [ ] `time_entry_page.dart` : Remplacer `totalHours` → `totalDays`
- [ ] `time_entry_page.dart` : Remplacer `avgHoursPerDay` → `avgDaysPerEntry`
- [ ] `time_entry_page.dart` : Remplacer `formatHours` → `formatDays`
- [ ] `timesheet_reporting_page.dart` : Remplacer `.totalHours` → `.totalDays` (6 occurrences)
- [ ] `timesheet_reporting_page.dart` : Remplacer `operatorCount` → `partnerCount`

---

**Temps estimé** : 5 minutes avec rechercher/remplacer global



