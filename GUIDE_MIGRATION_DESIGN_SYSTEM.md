# 🎨 Guide de migration vers le Design System OXO

## Résumé

**256 occurrences** de `Color(0xFF...)` dans **29 fichiers** à migrer vers `AppTheme` et `AppIcons`.

---

## 📊 Fichiers à migrer (par priorité)

### 🔴 PRIORITÉ HAUTE (pages principales)
- `lib/pages/shared/projects_page.dart` (29 occurrences)
- `lib/pages/associate/partner_profiles_page.dart` (11 occurrences)
- `lib/pages/timesheet/time_entry_page.dart` (10 occurrences)
- `lib/pages/dashboard/dashboard_page.dart` (22 occurrences)
- `lib/pages/auth/login_page.dart` (8 occurrences)

### 🟡 PRIORITÉ MOYENNE (pages secondaires)
- `lib/pages/clients/companies_page.dart` (8 occurrences)
- `lib/pages/shared/partners_clients_page.dart` (4 occurrences)
- `lib/pages/timesheet/timesheet_reporting_page.dart` (7 occurrences)
- `lib/pages/messaging/messaging_page.dart` (4 occurrences)
- `lib/pages/partner/actions_page.dart` (8 occurrences)

### 🟢 PRIORITÉ BASSE (pages moins utilisées)
- Toutes les autres pages iOS spécifiques
- Pages d'admin
- Pages de settings

---

## 🔧 Mapping des couleurs

### Couleurs principales
| Avant | Après |
|-------|-------|
| `Color(0xFF2A4B63)` | `AppTheme.colors.primary` |
| `Color(0xFF1784af)` | `AppTheme.colors.secondary` |
| `Color(0xFF1E3D54)` | `AppTheme.colors.primaryDark` |
| `Color(0xFF122b35)` | `AppTheme.colors.primaryDark` |

### Couleurs d'état
| Avant | Après |
|-------|-------|
| `Color(0xFF4CAF50)` | `AppTheme.colors.success` |
| `Color(0xFFF44336)` | `AppTheme.colors.error` |
| `Color(0xFFFF9800)` | `AppTheme.colors.warning` |
| `Color(0xFF2196F3)` | `AppTheme.colors.info` |

### Couleurs de fond
| Avant | Après |
|-------|-------|
| `Color(0xFFF5F5F5)` | `AppTheme.colors.background` |
| `Color(0xFFFFFFFF)` | `AppTheme.colors.surface` |
| `Color(0xFFF9F9F9)` | `AppTheme.colors.surfaceVariant` |
| `Color(0xFFFAFAFA)` | `AppTheme.colors.inputBackground` |

### Couleurs de texte
| Avant | Après |
|-------|-------|
| `Color(0xFF212121)` | `AppTheme.colors.textPrimary` |
| `Color(0xFF757575)` | `AppTheme.colors.textSecondary` |
| `Color(0xFFBDBDBD)` | `AppTheme.colors.textDisabled` |

### Couleurs de bordure
| Avant | Après |
|-------|-------|
| `Color(0xFFE0E0E0)` | `AppTheme.colors.border` |
| `Color(0xFFF0F0F0)` | `AppTheme.colors.borderLight` |

---

## 🎯 Mapping des icônes

### Navigation
| Avant | Après |
|-------|-------|
| `Icons.home` / `Icons.home_outlined` | `AppIcons.home` |
| `Icons.folder` / `Icons.folder_outlined` | `AppIcons.missions` |
| `Icons.schedule` | `AppIcons.timesheet` |
| `Icons.people` | `AppIcons.partners` |
| `Icons.person` | `AppIcons.profile` |
| `Icons.settings` | `AppIcons.settings` |

### Actions
| Avant | Après |
|-------|-------|
| `Icons.add` | `AppIcons.add` |
| `Icons.edit` / `Icons.edit_outlined` | `AppIcons.edit` |
| `Icons.delete` / `Icons.delete_outline` | `AppIcons.delete` |
| `Icons.save` | `AppIcons.save` |
| `Icons.search` | `AppIcons.search` |

### Statuts
| Avant | Après |
|-------|-------|
| `Icons.check_circle` | `AppIcons.success` |
| `Icons.error` | `AppIcons.error` |
| `Icons.warning` | `AppIcons.warning` |
| `Icons.info` | `AppIcons.info` |

---

## ⚙️ Script de migration automatique

```bash
#!/bin/bash
# Migration automatique des couleurs

# Couleurs principales
find lib/pages -type f -name "*.dart" -exec sed -i '' 's/Color(0xFF2A4B63)/AppTheme.colors.primary/g' {} +
find lib/pages -type f -name "*.dart" -exec sed -i '' 's/Color(0xFF1784af)/AppTheme.colors.secondary/g' {} +

# Couleurs d'état
find lib/pages -type f -name "*.dart" -exec sed -i '' 's/Color(0xFF4CAF50)/AppTheme.colors.success/g' {} +
find lib/pages -type f -name "*.dart" -exec sed -i '' 's/Color(0xFFF44336)/AppTheme.colors.error/g' {} +
find lib/pages -type f -name "*.dart" -exec sed -i '' 's/Color(0xFFFF9800)/AppTheme.colors.warning/g' {} +
find lib/pages -type f -name "*.dart" -exec sed -i '' 's/Color(0xFF2196F3)/AppTheme.colors.info/g' {} +

# Couleurs de fond
find lib/pages -type f -name "*.dart" -exec sed -i '' 's/Color(0xFFF5F5F5)/AppTheme.colors.background/g' {} +
find lib/pages -type f -name "*.dart" -exec sed -i '' 's/Color(0xFFFFFFFF)/AppTheme.colors.surface/g' {} +

# Couleurs de texte
find lib/pages -type f -name "*.dart" -exec sed -i '' 's/Color(0xFF212121)/AppTheme.colors.textPrimary/g' {} +
find lib/pages -type f -name "*.dart" -exec sed -i '' 's/Color(0xFF757575)/AppTheme.colors.textSecondary/g' {} +

# Couleurs de bordure
find lib/pages -type f -name "*.dart" -exec sed -i '' 's/Color(0xFFE0E0E0)/AppTheme.colors.border/g' {} +

# Ajouter les imports manquants
find lib/pages -type f -name "*.dart" -exec sed -i '' "1s/^/import '..\/config\/app_theme.dart';\\n/" {} +
```

---

## ✅ Checklist de migration par fichier

Pour chaque fichier :

1. [ ] Ajouter `import '../../config/app_theme.dart';`
2. [ ] Ajouter `import '../../config/app_icons.dart';` si utilisation d'icônes
3. [ ] Remplacer toutes les `Color(0xFF...)` par `AppTheme.colors.*`
4. [ ] Remplacer toutes les `Icons.*` par `AppIcons.*`
5. [ ] Remplacer les `TextStyle(...)` par `AppTheme.typography.*`
6. [ ] Vérifier que l'app compile
7. [ ] Tester visuellement la page

---

## 🎯 Impact attendu

✅ **Cohérence visuelle** : Une seule source de vérité pour les couleurs  
✅ **Maintenance facilitée** : Changement global en un seul endroit  
✅ **Thème sombre** : Préparé pour le futur support du dark mode  
✅ **Accessibilité** : Contraste et lisibilité uniformisés  
✅ **Performance** : Pas de création de couleurs multiples (const)

---

## ⏱️ Estimation

- **Migration automatique** : 15 min (script + vérification)
- **Migration manuelle complète** : 3-4 heures (29 fichiers)
- **Tests visuels** : 1 heure

**Recommandation** : Migration progressive par priorité (haute → moyenne → basse)



