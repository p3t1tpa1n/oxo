# 🚀 DÉPLOYER LE MODULE TIMESHEET - GUIDE RAPIDE

## ⚠️ Action requise : Exécuter le script SQL

Le module est **100% prêt** mais les tables n'existent pas encore dans votre base de données Supabase.

---

## 📋 Étapes (5 minutes)

### 1️⃣ Ouvrir Supabase Dashboard

Ouvrez votre navigateur et allez sur :
```
https://dswirxxbzbyhnxsrzyzi.supabase.co
```

### 2️⃣ Aller dans SQL Editor

Dans le menu de gauche, cliquez sur **"SQL Editor"**

### 3️⃣ Créer une nouvelle requête

Cliquez sur le bouton **"New query"** en haut à droite

### 4️⃣ Copier-coller le script

1. Ouvrez le fichier : **`supabase/create_oxo_timesheets_module.sql`**
2. Sélectionnez **TOUT le contenu** (Cmd+A)
3. Copiez (Cmd+C)
4. Collez dans l'éditeur SQL de Supabase (Cmd+V)

### 5️⃣ Exécuter le script

Cliquez sur le bouton **"Run"** (ou appuyez sur Cmd+Enter)

⏱️ L'exécution prend environ 5-10 secondes.

### 6️⃣ Vérifier la création

Exécutez ce script de vérification (nouvelle requête) :

```sql
-- Vérifier que tout est créé
SELECT 'Tables' as type, COUNT(*) as count
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('partner_rates', 'partner_client_permissions', 'timesheet_entries')

UNION ALL

SELECT 'Fonctions' as type, COUNT(*) as count
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name LIKE '%partner%' OR routine_name LIKE '%timesheet%';
```

**Résultat attendu** :
- Tables : 3
- Fonctions : 7+

---

## ✅ C'est fait ! Relancer l'application

Une fois le script exécuté avec succès :

```bash
# Arrêtez l'app si elle tourne (Ctrl+C dans le terminal)
# Puis relancez :
flutter run
```

---

## 🎯 Tester le module

### Test 1 : En tant qu'Associé (`asso@gmail.com`)

1. Connectez-vous
2. Cliquez sur **"Paramètres Timesheet"** dans le menu
3. Ajoutez un tarif :
   - Partenaire : `part@gmail.com`
   - Client : (choisir un client)
   - Tarif journalier : `500`
4. Cliquez sur **"Saisie du temps"**
5. Sélectionnez un client et entrez des heures
6. Vérifiez que le montant est calculé automatiquement
7. Cliquez sur **"Reporting Timesheet"**
8. Vérifiez les rapports

### Test 2 : En tant que Partenaire (`part@gmail.com`)

1. Connectez-vous
2. Vérifiez que **"Paramètres Timesheet"** et **"Reporting Timesheet"** ne sont **PAS visibles**
3. Cliquez sur **"Saisie du temps"**
4. Sélectionnez un client et entrez des heures
5. Vérifiez le calcul automatique

---

## 🐛 En cas d'erreur

### Erreur : "relation already exists"

C'est normal si vous avez déjà exécuté le script. Ignorez cette erreur.

### Erreur : "permission denied"

Vérifiez que vous êtes bien connecté en tant qu'administrateur Supabase.

### Erreur : "foreign key constraint"

Vérifiez que la table `clients` existe dans votre base de données.

### Les menus ne s'affichent pas

1. Vérifiez que vous êtes connecté
2. Vérifiez votre rôle dans la table `profiles`
3. Redémarrez l'application

---

## 📞 Support

Si vous rencontrez un problème :

1. Vérifiez les logs Flutter dans le terminal
2. Vérifiez les logs Supabase dans le dashboard
3. Exécutez le script de vérification : `supabase/verify_timesheet_module.sql`

---

## 📚 Documentation complète

- **`TIMESHEET_MODULE_READY.md`** - Documentation complète du module
- **`OXO_TIMESHEETS_MODULE_DOCUMENTATION.md`** - Documentation technique
- **`RENAME_OPERATOR_TO_PARTNER.md`** - Détails du renommage

---

**Prêt à déployer !** 🚀

Exécutez le script SQL maintenant et le module sera opérationnel !



