# 🎯 Simplification de la page Missions

## Modifications à faire

### 1. ✅ Supprimer la section "Tâches"
- Supprimer `_buildTaskFilters()`
- Supprimer `_buildEmptyTasksState()`
- Supprimer `_buildTasksBoard()`
- Supprimer `_buildTaskColumn()`
- Supprimer `_buildTasksList()`
- Supprimer `_buildTaskCard()`
- Supprimer `_showCreateTaskDialog()`
- Supprimer le bouton "Nouvelle Tâche"

### 2. ✅ Rendre l'interface sobre
- Utiliser des couleurs neutres (gris, bleu foncé)
- Supprimer les couleurs vives (orange, vert, violet)
- Utiliser `Color(0xFF2A4B63)` comme couleur principale

### 3. ✅ Garder uniquement le badge "progress_status"
- Supprimer le badge "status" (En cours, Pending, etc.)
- Garder uniquement "À assigner", "En cours", "Terminé"

### 4. ✅ Remplacer la progression par l'avancement du temps
- Calculer le temps écoulé entre start_date et end_date
- Afficher "En retard de X jours" si la date de fin est dépassée
- Barre rouge si en retard, bleue sinon

### 5. ✅ Vérifier les colonnes de la base
Colonnes utilisées et vérifiées :
- `title`, `name`, `description` ✅
- `start_date`, `end_date`, `created_at`, `updated_at` ✅
- `budget`, `daily_rate`, `priority` ✅
- `estimated_days`, `worked_days`, `estimated_hours`, `worked_hours` ✅
- `progress_status` ✅
- `notes`, `completion_notes` ✅

## État actuel

❌ Le fichier a été restauré depuis git car trop de modifications ont cassé le code.

## Solution

Au lieu de modifier le fichier existant, je vais créer une nouvelle version simplifiée.

Fichier à créer : `lib/pages/shared/missions_detail_page.dart`

Ce fichier contiendra uniquement :
- L'affichage des détails de la mission
- Les 4 cartes d'information (Dates, Budget, Temps, Avancement)
- Pas de tâches
- Interface sobre

Puis modifier `projects_page.dart` pour utiliser cette nouvelle page en navigation.

