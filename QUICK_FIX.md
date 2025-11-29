# ⚡ FIX RAPIDE - 2 ÉTAPES

## 🎯 Votre problème : `column "partner_id" does not exist`

**Cause** : Anciennes tables existent déjà avec `operator_id`

**Solution** : Supprimer puis recréer

---

## 📋 ÉTAPE 1 : Supprimer les anciennes tables

### Dans Supabase SQL Editor :

1. Ouvrez : https://dswirxxbzbyhnxsrzyzi.supabase.co
2. SQL Editor → New query
3. Copiez-collez : **`supabase/cleanup_timesheet_module.sql`**
4. Run

✅ **Vérifiez** : Les 3 counts doivent être à **0**

---

## 📋 ÉTAPE 2 : Créer les nouvelles tables

### Dans Supabase SQL Editor :

1. New query
2. Copiez-collez : **`supabase/create_oxo_timesheets_module.sql`**
3. Run

✅ **Vérifiez** : Aucune erreur

**Notes** : 
- ✅ `company_id` : `UUID` → `BIGINT`
- ✅ Valeur enum : `'associate'` → `'associe'`
- ✅ Nom colonne : `profiles.user_role` → `profiles.role`

---

## 🚀 ÉTAPE 3 : Relancer l'app

```bash
flutter run
```

---

## ✅ C'est tout !

**Temps total** : 1 minute

Le module timesheet fonctionnera sans erreur.

---

## 📚 Documentation complète

Si vous voulez plus de détails : **`SOLUTION_FINALE_TIMESHEET.md`**


