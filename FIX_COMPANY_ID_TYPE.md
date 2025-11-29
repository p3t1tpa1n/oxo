# 🔧 FIX : Incompatibilité de type company_id

## ❌ Erreur rencontrée

```
ERROR: 42804: foreign key constraint "timesheet_entries_company_id_fkey" cannot be implemented
DETAIL: Key columns "company_id" and "id" are of incompatible types: uuid and bigint.
```

## 🔍 Diagnostic

### Résultat du nettoyage (ÉTAPE 1)
```
Tables restantes    | 0  ✅
Vues restantes      | 0  ✅
Fonctions restantes | 9  ⚠️ (normal, fonctions système)
```

### Problème identifié
Votre table `companies` utilise un `id` de type **`BIGINT`**, mais le script utilisait **`UUID`** pour la colonne `company_id` dans `timesheet_entries`.

## ✅ Correction appliquée

### Fichier modifié : `supabase/create_oxo_timesheets_module.sql`

**Ligne 65** - Changement du type de `company_id` :

```sql
-- ❌ AVANT (incorrect)
company_id UUID REFERENCES companies(id) ON DELETE CASCADE,

-- ✅ APRÈS (correct)
company_id BIGINT REFERENCES companies(id) ON DELETE CASCADE,
```

## 🚀 Prochaines étapes

### Maintenant, exécutez l'ÉTAPE 2 :

1. **Ouvrez Supabase SQL Editor**
2. **New query**
3. **Copiez-collez** le contenu de : `supabase/create_oxo_timesheets_module.sql`
4. **Run** (Cmd+Enter)

✅ **Cette fois, ça devrait fonctionner sans erreur !**

---

## 📊 Vérification après création

Exécutez ce script pour vérifier :

```sql
-- Vérifier que tout est créé correctement
SELECT 
  table_name,
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'timesheet_entries'
  AND column_name = 'company_id';
```

**Résultat attendu** :
```
table_name         | column_name | data_type
timesheet_entries  | company_id  | bigint
```

---

## 🎯 Pourquoi ce changement

### Structure de votre base de données

Votre application utilise **2 types d'ID différents** :

| Table | Type d'ID | Exemple |
|-------|-----------|---------|
| `auth.users` | UUID | `62f86bcb-3529-4aa5-a4b3-ca231f71dc2d` |
| `clients` | UUID | `ab618e61-e44b-4a42-a312-dbc8fb5bd3c2` |
| `companies` | **BIGINT** | `1`, `2`, `3`, etc. |

### Conséquence

Toutes les colonnes qui référencent `companies.id` doivent être de type **`BIGINT`**, pas `UUID`.

---

## 🔍 Comment vérifier votre structure

Si vous voulez vérifier la structure de vos tables :

```sql
-- Vérifier le type d'ID de companies
SELECT 
  column_name,
  data_type
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'companies'
  AND column_name = 'id';
```

---

## ✅ Statut

- [x] Problème identifié
- [x] Script corrigé
- [ ] Script exécuté (ÉTAPE 2)
- [ ] Application testée

---

**Date** : 1er novembre 2025  
**Correction** : `UUID` → `BIGINT` pour `company_id`  
**Fichier** : `supabase/create_oxo_timesheets_module.sql` ligne 65


