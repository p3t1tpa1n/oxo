# Guide de Migration - Corrections du Schéma Supabase

## 📋 Vue d'Ensemble

Ce dossier contient 4 fichiers de migration SQL pour corriger les problèmes identifiés dans votre schéma Supabase :

1. **Part 1 - Structure** (OBLIGATOIRE) : Foreign keys, types de données, contraintes, index
2. **Part 2 - RLS** (OBLIGATOIRE) : Politiques de sécurité RLS
3. **Part 3 - Fonctions** (OBLIGATOIRE) : Fonctions RLS, soft delete, standardisation
4. **Part 4 - Cleanup** (OPTIONNEL) : Suppression de user_roles et autres nettoyages

## ⚠️ IMPORTANT - À Lire Avant de Commencer

### Prérequis

1. ✅ **Sauvegarde complète** de votre base de données
2. ✅ **Environnement de test** disponible
3. ✅ **Accès admin** à Supabase
4. ✅ **Code Dart** prêt à être mis à jour si nécessaire

### Risques

- ⚠️ Modifications de structure de base de données
- ⚠️ Changements dans les politiques RLS
- ⚠️ Possible interruption temporaire du service
- ⚠️ Code applicatif à adapter

## 🚀 Procédure d'Exécution

### Étape 0 : Sauvegarde

```bash
# Via Supabase CLI
supabase db dump > backup_$(date +%Y%m%d_%H%M%S).sql

# OU via l'interface Supabase
# Database → Backups → Create backup
```

### Étape 1 : Test en Local/Dev

```bash
# 1. Créer un projet Supabase local
supabase init
supabase start

# 2. Appliquer les migrations
supabase db push

# 3. Tester votre application
cd /Users/paul.p/Documents/develompent/oxo
flutter run
```

### Étape 2 : Exécution des Migrations Obligatoires

#### Via Supabase CLI (Recommandé)

```bash
cd /Users/paul.p/Documents/develompent/oxo

# Migration 1 : Structure
supabase db execute < supabase/migrations/20251007_fix_schema_issues_part1_structure.sql

# Vérifier qu'il n'y a pas d'erreurs
# Si OK, continuer...

# Migration 2 : RLS
supabase db execute < supabase/migrations/20251007_fix_schema_issues_part2_rls.sql

# Migration 3 : Fonctions
supabase db execute < supabase/migrations/20251007_fix_schema_issues_part3_data_functions.sql
```

#### Via l'Interface Supabase

1. Aller dans **Database → SQL Editor**
2. Créer un nouveau query
3. Copier-coller le contenu de chaque fichier SQL
4. Exécuter dans l'ordre (1 → 2 → 3)
5. Vérifier les messages de succès/erreur

### Étape 3 : Vérifications Post-Migration

```sql
-- Vérifier les foreign keys
SELECT 
  tc.table_name, 
  kcu.column_name, 
  ccu.table_name AS foreign_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu 
  ON tc.constraint_name = ccu.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;

-- Vérifier les politiques RLS
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  roles
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- Vérifier les fonctions créées
SELECT 
  proname, 
  pg_get_functiondef(oid) as definition
FROM pg_proc
WHERE proname IN (
  'get_user_company_id',
  'can_message_user',
  'can_participate_in_conversation',
  'get_user_role',
  'is_admin_or_associate'
)
AND pronamespace = 'public'::regnamespace;
```

### Étape 4 : Tests Applicatifs

Testez les fonctionnalités suivantes dans votre app Flutter :

- [ ] Connexion / Authentification
- [ ] Création de projet
- [ ] Assignation de tâches
- [ ] Création de factures
- [ ] Messagerie interne
- [ ] Disponibilités partenaires
- [ ] Actions commerciales
- [ ] Timesheet

### Étape 5 : Migration Optionnelle (Part 4)

⚠️ **ATTENTION** : La migration Part 4 est **OPTIONNELLE** et **DESTRUCTIVE**

Elle supprime :
- La table `user_roles` (dédoublonnage avec `profiles.role`)
- Les colonnes `user1_id`, `user2_id` dans `conversations`
- Les colonnes redondantes dans `tasks`

**N'exécutez cette migration QUE si :**
1. Vous avez testé les migrations 1-3
2. Votre code n'utilise plus `user_roles`
3. Vous avez mis à jour votre code Dart
4. Vous avez vérifié les divergences de données

```bash
# Lire le fichier d'abord !
cat supabase/migrations/20251007_fix_schema_issues_part4_optional_cleanup.sql

# Décommenter les sections voulues
# Puis exécuter
supabase db execute < supabase/migrations/20251007_fix_schema_issues_part4_optional_cleanup.sql
```

## 🔧 Modifications à Apporter au Code Dart

### 1. Si vous utilisez `user_roles` table

**Avant :**
```dart
final userRole = await supabase
  .from('user_roles')
  .select('user_role')
  .eq('user_id', userId)
  .single();
```

**Après :**
```dart
final userRole = await supabase
  .from('profiles')
  .select('role')
  .eq('user_id', userId)
  .single();
```

### 2. Statuts standardisés en anglais

**Avant :**
```dart
status: 'actif'  // ❌
```

**Après :**
```dart
status: 'active'  // ✅
```

### 3. Utilisation des nouvelles fonctions RLS

Les fonctions suivantes sont maintenant disponibles dans vos requêtes :

```dart
// Vérifier si on peut envoyer un message
final canMessage = await supabase.rpc(
  'can_message_user',
  params: {
    'sender_id': currentUserId,
    'recipient_id': recipientId,
  }
);

// Récupérer le company_id de l'utilisateur
final companyId = await supabase.rpc('get_user_company_id');

// Vérifier le rôle
final role = await supabase.rpc('get_user_role');

// Vérifier si admin/associé
final isAdmin = await supabase.rpc('is_admin_or_associate');
```

### 4. Soft Delete

**Avant :**
```dart
// Suppression dure
await supabase.from('projects').delete().eq('id', projectId);
```

**Après :**
```dart
// Soft delete
await supabase.from('projects').update({
  'deleted_at': DateTime.now().toIso8601String(),
}).eq('id', projectId);

// Ne pas récupérer les éléments supprimés
final projects = await supabase
  .from('projects')
  .select()
  .is_('deleted_at', null);  // Filtrer les supprimés
```

## 📊 Checklist de Validation

### Après Migration 1 (Structure)

- [ ] Toutes les foreign keys sont créées
- [ ] Aucune erreur de contrainte
- [ ] Les index sont créés
- [ ] La table `user_client_mapping` fonctionne correctement

### Après Migration 2 (RLS)

- [ ] Aucune politique n'utilise le rôle `public`
- [ ] Les politiques redondantes sont supprimées
- [ ] Les accès sont correctement restreints
- [ ] Les utilisateurs peuvent accéder à leurs données

### Après Migration 3 (Fonctions)

- [ ] Les fonctions RLS sont créées
- [ ] Les triggers `updated_at` fonctionnent
- [ ] Le soft delete est actif
- [ ] Les vues sont créées

### Après Migration 4 (Optionnelle)

- [ ] La sauvegarde `_backup_user_roles_20251007` existe
- [ ] Le code Dart est mis à jour
- [ ] Les tests passent
- [ ] Aucune référence à `user_roles` dans le code

## 🐛 Résolution de Problèmes

### Erreur : Foreign key violation

```
ERROR: insert or update on table "X" violates foreign key constraint "fk_X_Y"
```

**Solution :**
1. Vérifier qu'il n'y a pas de données orphelines
2. Nettoyer les données invalides avant la migration
3. Utiliser `ON DELETE SET NULL` ou `CASCADE` selon le besoin

```sql
-- Trouver les données orphelines
SELECT * FROM table_name 
WHERE foreign_key_column NOT IN (SELECT id FROM referenced_table);

-- Nettoyer
DELETE FROM table_name 
WHERE foreign_key_column NOT IN (SELECT id FROM referenced_table);
```

### Erreur : Policy already exists

```
ERROR: policy "policy_name" for table "table_name" already exists
```

**Solution :**
```sql
DROP POLICY IF EXISTS "policy_name" ON table_name;
-- Puis réexécuter la création
```

### Erreur : Function already exists

```
ERROR: function X already exists with same argument types
```

**Solution :**
```sql
CREATE OR REPLACE FUNCTION function_name(...) ...
-- Utilise CREATE OR REPLACE au lieu de CREATE
```

### Problème : Données divergentes entre user_roles et profiles

**Solution :**
1. Exporter les données
2. Choisir la source de vérité (profiles ou user_roles)
3. Synchroniser manuellement
4. Vérifier avec la requête dans part4

```sql
-- Voir les divergences
SELECT 
  ur.user_id, 
  ur.user_role, 
  p.role as profile_role
FROM user_roles ur
JOIN profiles p ON p.user_id = ur.user_id
WHERE ur.user_role::text != p.role::text;
```

## 📞 Support

Si vous rencontrez des problèmes :

1. Vérifiez les logs Supabase : Database → Logs
2. Consultez les messages d'erreur détaillés
3. Vérifiez le fichier `SCHEMA_ANALYSIS.md` pour comprendre les problèmes
4. Restaurez la sauvegarde si nécessaire

## 🎯 Prochaines Étapes Après Migration

1. **Monitoring** : Surveiller les performances pendant 24-48h
2. **Documentation** : Mettre à jour votre documentation technique
3. **Tests** : Exécuter la suite de tests complète
4. **Déploiement** : Mettre à jour l'application en production
5. **Nettoyage** : Après 1 semaine, supprimer les tables de backup si tout fonctionne

## 📚 Références

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Foreign Keys](https://www.postgresql.org/docs/current/ddl-constraints.html)
- [Flutter Supabase Client](https://pub.dev/packages/supabase_flutter)

---

**Créé le :** 7 octobre 2025  
**Version :** 1.0  
**Auteur :** Migration automatique pour correction du schéma


