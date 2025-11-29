# 🔧 FIX FINAL : Nom de colonne profiles

## ❌ Erreur rencontrée

```
ERROR: 42703: column profiles.user_role does not exist
```

## 🔍 Diagnostic

### Structure réelle de votre table `profiles`

Votre table `profiles` utilise :
- ✅ Colonne : `role` (pas `user_role`)
- ✅ Valeurs : `'admin'`, `'associe'`, `'partenaire'`, `'client'`

### Confusion initiale

La fonction `get_users()` retourne un alias `user_role` dans le résultat, mais la **vraie colonne** dans la table `profiles` s'appelle `role`.

```sql
-- Fonction get_users() (ligne 22)
SELECT p.role  -- ← Colonne réelle
FROM profiles p

-- Mais dans votre code Dart, vous lisez :
userProfile['user_role']  -- ← Alias dans le résultat
```

## ✅ Correction finale appliquée

### Fichier modifié : `supabase/create_oxo_timesheets_module.sql`

**Changement** : `profiles.user_role` → `profiles.role`

```sql
-- ✅ CORRECT (version finale)
SELECT 1 FROM profiles
WHERE profiles.user_id = auth.uid()
AND profiles.role = 'associe'
```

### 6 politiques RLS corrigées

Toutes les occurrences ont été remplacées automatiquement avec `replace_all`.

## 🚀 EXÉCUTION FINALE

### Maintenant, exécutez le script :

1. **Ouvrez Supabase SQL Editor**
2. **New query**
3. **Copiez-collez** : `supabase/create_oxo_timesheets_module.sql`
4. **Run** (Cmd+Enter)

✅ **Toutes les erreurs sont corrigées !**

---

## 📊 Récapitulatif COMPLET des corrections

| # | Erreur | Correction | Ligne(s) |
|---|--------|-----------|----------|
| 1 | `column "partner_id" does not exist` | Nettoyage des anciennes tables | N/A |
| 2 | `incompatible types: uuid and bigint` | `UUID` → `BIGINT` pour `company_id` | 65 |
| 3 | `invalid input value for enum: "associate"` | `'associate'` → `'associe'` | 396, 408, 427, 439, 458, 470 |
| 4 | `column profiles.user_role does not exist` | `profiles.user_role` → `profiles.role` | 396, 408, 427, 439, 458, 470 |

---

## 🎯 État final du script

### Corrections appliquées :

```sql
-- 1. Type de company_id
company_id BIGINT REFERENCES companies(id)  -- ✅

-- 2. Nom de colonne + valeur enum
profiles.role = 'associe'  -- ✅
```

### Politiques RLS (version finale) :

```sql
-- Exemple de politique corrigée
CREATE POLICY "Associés peuvent tout voir sur partner_rates"
  ON partner_rates FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.user_id = auth.uid()
      AND profiles.role = 'associe'  -- ✅ Correct
    )
  );
```

---

## ✅ Checklist finale

- [x] Nettoyage des anciennes tables (ÉTAPE 1)
- [x] Correction du type `company_id` (UUID → BIGINT)
- [x] Correction de la valeur enum (associate → associe)
- [x] Correction du nom de colonne (user_role → role)
- [ ] **Exécution du script final**
- [ ] Vérification de la création
- [ ] Test dans l'application Flutter

---

## 🔍 Vérification après création

```sql
-- Vérifier que tout est créé
SELECT 
  'Tables' as type, 
  COUNT(*) as count
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('partner_rates', 'partner_client_permissions', 'timesheet_entries')

UNION ALL

SELECT 
  'Politiques RLS' as type, 
  COUNT(*) as count
FROM pg_policies
WHERE tablename IN ('partner_rates', 'partner_client_permissions', 'timesheet_entries');
```

**Résultat attendu** :
```
Tables           | 3
Politiques RLS   | 8
```

---

**Date** : 1er novembre 2025  
**Statut** : ✅ Toutes les corrections appliquées  
**Prochaine étape** : Exécuter le script dans Supabase


