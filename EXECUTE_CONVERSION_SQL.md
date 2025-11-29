# ⚡ Exécution du script de conversion

## 🎯 Objectif

Convertir le module timesheet de **heures** vers **jours/demi-journées**.

---

## ⚠️ ATTENTION

**Ce script va modifier la structure de la base de données.**

Si vous avez des **données existantes** dans `timesheet_entries`, elles seront **converties** :
- La colonne `hours` sera renommée en `days`
- Les valeurs existantes seront conservées mais devront être manuellement ajustées

**Recommandation** : Sauvegardez vos données ou testez d'abord sur un environnement de développement.

---

## 🚀 Exécution

### Étape 1 : Ouvrir Supabase SQL Editor

1. Allez sur : https://dswirxxbzbyhnxsrzyzi.supabase.co
2. Cliquez sur **SQL Editor**
3. Cliquez sur **New query**

---

### Étape 2 : Copier-coller le script

Copiez le contenu complet du fichier :
```
supabase/update_timesheet_to_days.sql
```

---

### Étape 3 : Exécuter

Cliquez sur **Run** (ou Cmd+Enter)

---

## ✅ Vérifications

### 1. Vérifier la colonne `days`

```sql
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'timesheet_entries'
  AND column_name = 'days';
```

**Résultat attendu** :
```
column_name | data_type | is_nullable
days        | numeric   | NO
```

---

### 2. Vérifier la contrainte

```sql
SELECT 
  constraint_name,
  check_clause
FROM information_schema.check_constraints
WHERE constraint_schema = 'public'
  AND constraint_name LIKE '%timesheet_entries_days%';
```

**Résultat attendu** :
```
constraint_name                | check_clause
timesheet_entries_days_check   | (days = ANY (ARRAY[0.5, 1.0]))
```

---

### 3. Vérifier les fonctions

```sql
SELECT 
  routine_name,
  routine_type
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'get_partner_monthly_stats',
    'get_timesheet_report_by_client',
    'get_timesheet_report_by_partner'
  );
```

**Résultat attendu** : 3 fonctions

---

### 4. Tester une insertion

```sql
-- Test avec une demi-journée
INSERT INTO timesheet_entries (
  partner_id,
  client_id,
  entry_date,
  days,
  daily_rate,
  status
) VALUES (
  'bbfd419c-4c15-4ad6-8f34-0fad1f9092c7', -- Remplacez par un partner_id valide
  (SELECT id FROM clients LIMIT 1),
  CURRENT_DATE,
  0.5,
  500.00,
  'draft'
);

-- Vérifier
SELECT * FROM timesheet_entries ORDER BY created_at DESC LIMIT 1;

-- Nettoyer le test
DELETE FROM timesheet_entries WHERE entry_date = CURRENT_DATE;
```

---

## 🐛 En cas d'erreur

### Erreur : "cannot change return type of existing function"

✅ **Corrigé** : Le script supprime maintenant les fonctions avant de les recréer.

---

### Erreur : "column hours does not exist"

❌ La colonne a déjà été renommée. Le script a été partiellement exécuté.

**Solution** : Vérifiez l'état actuel avec :
```sql
SELECT column_name 
FROM information_schema.columns
WHERE table_name = 'timesheet_entries'
  AND column_name IN ('hours', 'days');
```

---

### Erreur : "constraint ... already exists"

❌ La contrainte existe déjà.

**Solution** : Supprimez-la d'abord :
```sql
ALTER TABLE timesheet_entries 
  DROP CONSTRAINT IF EXISTS timesheet_entries_days_check;
```

Puis réexécutez la partie concernée du script.

---

## 📊 Résumé des modifications

| Élément | Avant | Après |
|---------|-------|-------|
| Colonne | `hours NUMERIC(4,2)` | `days NUMERIC(4,2)` |
| Contrainte | `hours > 0 AND hours <= 24` | `days IN (0.5, 1.0)` |
| Vue | `timesheet_entries_detailed.hours` | `timesheet_entries_detailed.days` |
| Fonction 1 | `get_partner_monthly_stats.total_hours` | `get_partner_monthly_stats.total_days` |
| Fonction 2 | `get_timesheet_report_by_client.total_hours` | `get_timesheet_report_by_client.total_days` |
| Fonction 3 | `get_timesheet_report_by_partner.total_hours` | `get_timesheet_report_by_partner.total_days` |

---

## ✅ Après l'exécution

Une fois le script exécuté avec succès :

1. ✅ Relancez l'application Flutter
2. ✅ Testez la saisie de temps
3. ✅ Vérifiez les rapports

---

**Date** : 1er novembre 2025  
**Fichier** : `supabase/update_timesheet_to_days.sql`  
**Statut** : ✅ Prêt à exécuter


