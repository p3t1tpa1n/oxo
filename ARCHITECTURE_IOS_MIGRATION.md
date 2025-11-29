# 🏗️ Architecture iOS - Plan de Migration OXO Time Sheets

## 📋 Vue d'ensemble

Ce document décrit l'architecture complète pour refondre l'application iOS avec une séparation claire entre DesktopShell et MobileShell, et un plan de migration en 8 phases.

---

## 🎯 Objectifs

1. **Parité fonctionnelle** : iOS doit avoir les mêmes fonctionnalités que macOS/Web
2. **Cohérence visuelle** : Réutiliser le design system existant (`AppTheme`, `IOSTheme`, `AppIcons`)
3. **Layout mobile optimisé** : Pas de sidebar sur iPhone, navigation par tabs
4. **Architecture propre** : Séparation claire des responsabilités

---

## 🏛️ Architecture des Shells

### DesktopShell (macOS/Web)

- **Layout** : Sidebar gauche (240px) + TopBar + Contenu principal
- **Navigation** : Sidebar avec menu vertical
- **Réutilise** : Le widget `SideMenu` existant
- **Fichier** : `lib/app/shells/desktop_shell.dart`

### MobileShell (iOS)

- **Layout** : Tabs en bas + Navigation stack par tab
- **Navigation** : `CupertinoTabScaffold` avec `CupertinoTabView` pour chaque tab
- **Tabs selon rôle** :
  - **Admin/Associé** : Accueil, Missions, Partenaires, Profil (4 tabs)
  - **Partenaire** : Accueil, Missions, Profil (3 tabs)
  - **Client** : Accueil, Projets, Demandes, Profil (4 tabs)
- **Fichier** : `lib/app/shells/mobile_shell.dart`

### AdaptiveShell

- **Rôle** : Sélecteur automatique du bon shell selon la plateforme
- **Détection** : Utilise `DeviceDetector.shouldUseIOSInterface()`
- **Fichier** : `lib/app/shells/adaptive_shell.dart`

---

## 📁 Structure de dossiers proposée

```
lib/
├── app/
│   ├── shells/
│   │   ├── desktop_shell.dart          ✅ Créé
│   │   ├── mobile_shell.dart           ✅ Créé
│   │   └── adaptive_shell.dart         ✅ Créé
│   └── routing/
│       └── app_routes.dart             ⏳ À créer
├── features/
│   ├── dashboard/
│   │   └── presentation/
│   │       └── dashboard_content.dart  ⏳ À créer
│   ├── missions/
│   │   └── presentation/
│   │       └── missions_list.dart      ⏳ À créer
│   ├── profile/
│   │   └── presentation/
│   │       ├── profile_page_improved.dart  ✅ Créé
│   │       └── preferences_page.dart    ✅ Créé
│   └── ...
├── services/
│   └── preferences_service.dart        ✅ Créé
└── ...
```

---

## 🚀 Plan de Migration en 8 Phases

### ✅ Phase 1 : Créer la structure des shells

**Statut** : ✅ **TERMINÉ**

**Fichiers créés** :
- `lib/app/shells/desktop_shell.dart`
- `lib/app/shells/mobile_shell.dart`
- `lib/app/shells/adaptive_shell.dart`

**Actions** :
- [x] Créer DesktopShell avec sidebar + topbar
- [x] Créer MobileShell avec tabs
- [x] Créer AdaptiveShell sélecteur

**Test** : Vérifier que les shells se compilent sans erreur.

---

### ⏳ Phase 2 : Migrer le contenu dashboard vers des widgets réutilisables

**Statut** : ⏳ **EN ATTENTE**

**Actions** :
1. Créer `lib/features/dashboard/presentation/dashboard_content.dart`
2. Extraire la logique de chargement des données
3. Rendre le widget responsive (s'adapte à la largeur)
4. Réutiliser sur desktop ET mobile

**Exemple de code** : Voir section "Exemple DashboardContent" dans le document principal.

**Test** : Vérifier que le dashboard s'affiche correctement sur desktop et mobile.

---

### ⏳ Phase 3 : Adapter le système de routing pour utiliser les shells

**Statut** : ⏳ **EN ATTENTE**

**Actions** :
1. Modifier `lib/main.dart` pour utiliser `AdaptiveShell`
2. Créer un système de routing qui passe par les shells
3. Gérer les routes qui ne passent pas par le shell (login, etc.)

**Modifications dans `main.dart`** :
```dart
// Avant
home: _getHomePage(),

// Après
home: AdaptiveShell(
  currentRoute: '/dashboard',
  desktopChild: _getPageForRoute('/dashboard', null),
),
```

**Test** : Vérifier que la navigation fonctionne sur desktop et mobile.

---

### ⏳ Phase 4 : Créer des widgets adaptatifs pour missions, timesheet, messages

**Statut** : ⏳ **EN ATTENTE**

**Actions** :
1. Créer `lib/features/missions/presentation/missions_list.dart`
   - Widget réutilisable pour lister les missions
   - S'adapte à la largeur (grid sur desktop, list sur mobile)
2. Créer `lib/features/timesheet/presentation/timesheet_content.dart`
   - Contenu timesheet réutilisable
   - Scrollable, respecte SafeArea
3. Créer `lib/features/messaging/presentation/messaging_content.dart`
   - Liste de conversations réutilisable

**Principe** : Chaque widget doit :
- Détecter la plateforme avec `DeviceDetector.shouldUseIOSInterface()`
- Utiliser `AppTheme` sur desktop, `IOSTheme` sur mobile
- Respecter `SafeArea` sur mobile
- Être scrollable pour éviter les overflows

**Test** : Vérifier qu'il n'y a pas d'overflow sur iOS.

---

### ⏳ Phase 5 : Supprimer les pages iOS dupliquées et migrer vers les widgets partagés

**Statut** : ⏳ **EN ATTENTE**

**Actions** :
1. **Audit des pages iOS** :
   - Identifier les pages iOS qui dupliquent la logique desktop
   - Identifier les pages iOS avec des bugs/overflows
   - Identifier les boutons non-fonctionnels

2. **Migration** :
   - Remplacer `IOSMobileTimesheetPage` par `TimesheetContent` dans MobileShell
   - Remplacer `IOSMobileMissionsPage` par `MissionsList` dans MobileShell
   - Supprimer les pages iOS obsolètes

3. **Nettoyage** :
   - Supprimer les fichiers iOS dupliqués
   - Mettre à jour les imports dans `main.dart`

**Pages à migrer** :
- `lib/pages/associate/ios_mobile_timesheet_page.dart` → `TimesheetContent`
- `lib/pages/partner/ios_mobile_missions_page.dart` → `MissionsList`
- `lib/pages/partner/ios_mobile_actions_page.dart` → ActionsContent (à créer)
- `lib/pages/admin/ios_mobile_admin_clients_page.dart` → ClientsList (à créer)

**Test** : Vérifier que toutes les fonctionnalités existantes fonctionnent toujours.

---

### ✅ Phase 6 : Créer le service PreferencesService et améliorer la page Profil

**Statut** : ✅ **TERMINÉ**

**Fichiers créés** :
- `lib/services/preferences_service.dart`
- `lib/features/profile/presentation/preferences_page.dart`
- `lib/features/profile/presentation/profile_page_improved.dart`

**Fonctionnalités** :
- Gestion du thème (clair/sombre/système)
- Gestion des notifications (email, push)
- Sauvegarde des préférences avec `SharedPreferences`

**Test** : Vérifier que les préférences sont sauvegardées et restaurées.

---

### ⏳ Phase 7 : Tests iOS - Overflow, navigation, SafeArea, cohérence visuelle

**Statut** : ⏳ **EN ATTENTE**

**Checklist de test** :

#### Navigation
- [ ] Tous les tabs sont accessibles et fonctionnels
- [ ] Navigation back fonctionne correctement dans chaque tab
- [ ] Navigation entre tabs préserve l'état de chaque stack
- [ ] Pas de retour inattendu au dashboard

#### Layout
- [ ] Pas d'overflow horizontal sur aucune page
- [ ] Pas d'overflow vertical (tous les contenus sont scrollables)
- [ ] `SafeArea` respecté partout (notch, Dynamic Island)
- [ ] Tous les widgets respectent les contraintes de taille

#### Cohérence visuelle
- [ ] Couleurs cohérentes avec `IOSTheme` et `AppTheme`
- [ ] Icônes cohérentes avec `AppIcons`
- [ ] Typographie cohérente
- [ ] Espacements cohérents

#### Fonctionnalités
- [ ] Toutes les fonctionnalités desktop sont accessibles sur iOS
- [ ] Pas de boutons "fantômes" (qui ne font rien)
- [ ] Tous les formulaires fonctionnent
- [ ] Tous les dialogues s'affichent correctement

**Outils de test** :
- Utiliser `flutter run` sur simulateur iOS
- Tester sur iPhone SE (petit écran)
- Tester sur iPhone 14 Pro Max (grand écran)
- Vérifier avec `flutter analyze`

---

### ⏳ Phase 8 : Audit final - Supprimer boutons non-fonctionnels et features orphelines

**Statut** : ⏳ **EN ATTENTE**

**Actions** :
1. **Audit des boutons** :
   - Parcourir toutes les pages iOS
   - Identifier les boutons qui ne font rien (TODO, navigation vide)
   - Identifier les boutons qui pointent vers des features inexistantes

2. **Décisions** :
   - **Option A** : Connecter le bouton à une feature existante
   - **Option B** : Supprimer le bouton si la feature n'existe pas sur desktop

3. **Nettoyage** :
   - Supprimer les boutons orphelins
   - Supprimer les routes inutilisées
   - Nettoyer les imports

**Exemples de boutons à vérifier** :
- Boutons "Créer mission" qui ouvrent un dialogue vide
- Boutons "Paramètres" qui ne mènent nulle part
- Boutons "Notifications" sans fonctionnalité

**Test** : Vérifier qu'il n'y a plus de boutons non-fonctionnels.

---

## 📝 Checklist de test iOS finale

### Navigation
- [ ] Tous les tabs sont accessibles
- [ ] Navigation back fonctionne
- [ ] Navigation entre tabs fonctionne
- [ ] Pas de retour inattendu au dashboard

### Layout
- [ ] Pas d'overflow horizontal
- [ ] Pas d'overflow vertical
- [ ] SafeArea respecté
- [ ] Tous les contenus sont scrollables

### Fonctionnalités
- [ ] Dashboard affiche les stats
- [ ] Missions listent correctement
- [ ] Timesheet fonctionne
- [ ] Messagerie fonctionne
- [ ] Profil affiche les infos
- [ ] Préférences sauvegardent

### Cohérence
- [ ] Couleurs cohérentes
- [ ] Icônes cohérentes
- [ ] Typographie cohérente
- [ ] Pas de boutons orphelins

---

## 🔧 Fichiers à modifier dans `main.dart`

Pour intégrer les shells, vous devrez modifier `main.dart` :

```dart
// Dans _getHomePage()
if (DeviceDetector.shouldUseIOSInterface()) {
  return const MobileShell();
} else {
  return DesktopShell(
    currentRoute: '/dashboard',
    child: _getPageForRoute('/dashboard', null),
  );
}
```

---

## 📚 Ressources

- **Design System** : `lib/config/app_theme.dart`, `lib/config/ios_theme.dart`
- **Icônes** : `lib/config/app_icons.dart`
- **Feedback** : `lib/services/feedback_service.dart`
- **Device Detection** : `lib/utils/device_detector.dart`

---

## 🎯 Prochaines étapes

1. **Tester les shells** : Vérifier que DesktopShell et MobileShell se compilent
2. **Phase 2** : Créer DashboardContent réutilisable
3. **Phase 3** : Adapter le routing
4. **Phase 4** : Créer les widgets adaptatifs
5. **Phase 5** : Migrer et supprimer les pages dupliquées
6. **Phase 7** : Tests complets iOS
7. **Phase 8** : Audit final et nettoyage

---

**Date de création** : 2024
**Dernière mise à jour** : 2024


