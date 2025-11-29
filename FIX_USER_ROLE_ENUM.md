# 🔧 FIX : Erreur enum user_role

## ❌ Erreur rencontrée

```
ERROR: 22P02: invalid input value for enum user_role: "associate"
```

## 🔍 Diagnostic

### Problème identifié

Le script utilisait **2 erreurs** dans les politiques RLS :

1. **Nom de colonne incorrect** : `profiles.role` au lieu de `profiles.user_role`
2. **Valeur enum incorrecte** : `'associate'` (anglais) au lieu de `'associe'` (français)

### Votre structure

Votre application utilise des rôles en **français** :

| Rôle | Valeur dans l'enum |
|------|-------------------|
| Administrateur | `'admin'` |
| Associé | `'associe'` |
| Partenaire | `'partenaire'` |
| Client | `'client'` |

## ✅ Corrections appliquées

### Fichier modifié : `supabase/create_oxo_timesheets_module.sql`

**6 politiques RLS corrigées** (lignes 389-472) :

```sql
-- ❌ AVANT (incorrect)
SELECT 1 FROM profiles
WHERE profiles.user_id = auth.uid()
AND profiles.role = 'associate'

-- ✅ APRÈS (correct)
SELECT 1 FROM profiles
WHERE profiles.user_id = auth.uid()
AND profiles.user_role = 'associe'
```

### Politiques corrigées

1. ✅ "Associés peuvent tout voir sur partner_rates" (ligne 389)
2. ✅ "Associés peuvent tout modifier sur partner_rates" (ligne 401)
3. ✅ "Associés peuvent tout voir sur permissions" (ligne 420)
4. ✅ "Associés peuvent tout modifier sur permissions" (ligne 432)
5. ✅ "Associés peuvent tout voir sur timesheet_entries" (ligne 451)
6. ✅ "Associés peuvent tout modifier sur timesheet_entries" (ligne 463)

## 🚀 Prochaines étapes

### Exécutez le script corrigé :

1. **Ouvrez Supabase SQL Editor**
2. **New query**
3. **Copiez-collez** le contenu de : `supabase/create_oxo_timesheets_module.sql`
4. **Run** (Cmd+Enter)

✅ **Cette fois, ça devrait fonctionner !**

---

## 📊 Vérification après création

Exécutez ce script pour vérifier les politiques :

```sql
-- Vérifier les politiques RLS créées
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd
FROM pg_policies
WHERE tablename IN ('partner_rates', 'partner_client_permissions', 'timesheet_entries')
ORDER BY tablename, policyname;
```

**Résultat attendu** : 8 politiques créées (3 pour partner_rates, 3 pour partner_client_permissions, 2 pour timesheet_entries)

---

## 🎯 Récapitulatif des corrections

| Correction | Avant | Après |
|-----------|-------|-------|
| **Correction 1** | `company_id UUID` | `company_id BIGINT` |
| **Correction 2** | `profiles.role` | `profiles.user_role` |
| **Correction 3** | `'associate'` | `'associe'` |

---

## ✅ Statut

- [x] Erreur `company_id` type incompatible → Corrigée
- [x] Erreur `user_role` enum invalide → Corrigée
- [ ] Script exécuté sans erreur
- [ ] Application testée

---

**Date** : 1er novembre 2025  
**Corrections** : 
- `UUID` → `BIGINT` pour `company_id`
- `profiles.role` → `profiles.user_role`
- `'associate'` → `'associe'`


