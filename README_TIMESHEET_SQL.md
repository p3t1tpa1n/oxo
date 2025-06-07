# Adaptation SQL pour le nouveau Timesheet avec Chronomètre

## 🔍 Vérification de votre base de données

### **ÉTAPE 1 : Diagnostic**
Exécutez ce script pour vérifier l'état actuel :
```
supabase/check_timesheet_structure.sql
```

Ce script vous dira **exactement** ce qui manque dans votre base.

## 🚨 Tables CRITIQUES pour le nouveau timesheet

### **1. Table `timesheet_entries` (🔥 CRITIQUE)**
**OBLIGATOIRE** pour le chronomètre. Si elle manque, exécutez :
```
supabase/create_timesheet_entries.sql
```

**Colonnes requises :**
- `id` (BIGSERIAL PRIMARY KEY)
- `task_id` (BIGINT) → Référence vers tasks.id
- `user_id` (UUID) → Référence vers auth.users.id
- `hours` (DECIMAL) → Heures enregistrées par le chronomètre
- `date` (TIMESTAMPTZ) → Date d'enregistrement
- `status` (VARCHAR) → pending/approved/rejected
- `description` (TEXT) → Description optionnelle

### **2. Table `tasks` (✅ Existante)**
Déjà créée avec les scripts précédents.

**Colonnes utilisées par le timesheet :**
- `id`, `title`, `description` → Affichage des missions
- `due_date` → Date de fin de mission (au lieu de date actuelle)
- `status` → Filtres (todo, in_progress, done)
- `project_id` → Lien vers l'entreprise
- `partner_id`, `assigned_to`, `user_id` → Identification des missions du partenaire

### **3. Table `projects` (🏢 Importante)**
Pour afficher les entreprises.

**Colonnes utilisées :**
- `id`, `name` → Nom de l'entreprise
- `description` → Détails de l'entreprise

## 🔧 Fonctionnalités supportées par le SQL

### **✅ Ce qui fonctionne maintenant :**
- 📋 Affichage des missions avec entreprise
- 📅 Date de fin de mission (due_date)
- 🔍 Filtres par statut
- 💾 Enregistrement des heures via chronomètre
- 📊 Calcul automatique du total d'heures par mission
- 🔒 Sécurité RLS (chaque utilisateur voit ses heures)

### **⏱️ Flux du chronomètre :**
1. **Sélection** : Partenaire choisit mission dans liste filtrée
2. **Chronomètre** : Temps décompté en temps réel  
3. **Enregistrement** : INSERT dans `timesheet_entries`
4. **Mise à jour** : SELECT SUM(hours) pour afficher total

## 📋 Plan d'action recommandé

### **Si vous n'avez PAS encore testé le diagnostic :**
```sql
-- 1. Exécutez d'abord le diagnostic
supabase/check_timesheet_structure.sql

-- 2. Selon le résultat, exécutez si nécessaire
supabase/create_timesheet_entries.sql
```

### **Si table `timesheet_entries` manque :**
```sql
-- Exécutez immédiatement
supabase/create_timesheet_entries.sql
```

### **Si table `projects` manque :**
Le timesheet fonctionnera mais sans nom d'entreprise.
```sql
-- Inclus dans le script create_timesheet_entries.sql
```

### **Si table `tasks` manque :**
```sql
-- Exécutez d'abord
supabase/create_or_update_tasks_table.sql
-- Puis
supabase/create_timesheet_entries.sql
```

## 🎯 Résultat attendu

Après adaptation SQL complète :
- ✅ Chronomètre opérationnel
- ✅ Heures enregistrées automatiquement
- ✅ Totaux calculés en temps réel
- ✅ Interface moderne et fluide
- ✅ Sécurité RLS active
- ✅ Entreprises affichées correctement

## ⚠️ Points d'attention

1. **Table `timesheet_entries`** = OBLIGATOIRE sinon erreur au clic "Terminer"
2. **Contraintes FK** = Importantes pour l'intégrité des données
3. **Politiques RLS** = Configurées pour éviter les récursions
4. **Index** = Créés pour optimiser les performances

## 🚀 Test final

Une fois le SQL adapté :
1. Connectez-vous comme partenaire
2. Allez dans "Timesheet"
3. Cliquez "+ Ajouter des heures"
4. Sélectionnez une mission
5. Démarrez le chronomètre
6. Arrêtez → Les heures doivent s'enregistrer

**Si ça fonctionne = SQL parfaitement adapté ! 🎉** 