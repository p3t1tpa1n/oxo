# 🔍 Guide de débogage - Missions vides dans le Dashboard

## Problème
Les missions avec `progress_status = 'à_assigner'` existent dans la base de données mais n'apparaissent pas dans le dashboard.

## Causes possibles

### 1. 🔒 Problème de permissions RLS (Row Level Security)
Les politiques RLS peuvent bloquer l'accès aux missions selon votre rôle utilisateur.

**Solution :**
```bash
# Exécutez ce script SQL dans Supabase
psql -h <votre-host> -U postgres -d postgres -f supabase/fix_missions_rls_policies.sql
```

### 2. 🏢 Problème de company_id
Les missions peuvent ne pas avoir le bon `company_id` associé à votre utilisateur.

**Vérification :**
```sql
-- Vérifier votre company_id
SELECT user_id, company_id, role 
FROM user_roles 
WHERE user_id = auth.uid();

-- Vérifier les company_id des missions
SELECT id, title, company_id, progress_status 
FROM missions 
ORDER BY created_at DESC 
LIMIT 10;
```

### 3. 📊 Les missions n'ont pas de progress_status
Si les missions ont `progress_status = NULL`, elles ne s'afficheront dans aucune colonne.

**Solution :**
```sql
-- Mettre à jour toutes les missions sans progress_status
UPDATE missions 
SET progress_status = 'à_assigner'::mission_progress_type
WHERE progress_status IS NULL;
```

## 🧪 Tests de diagnostic

### Étape 1 : Vérifier les logs de l'application

Lancez votre application et regardez la console. Vous devriez voir :

```
👤 Utilisateur connecté: <uuid>
🎭 Rôle: associate (ou admin, partner, client)
📊 Missions récupérées depuis Supabase: X
```

**Si vous voyez "0 missions récupérées" :**
- ✅ Le problème vient des **permissions RLS**
- ➡️ Exécutez `supabase/fix_missions_rls_policies.sql`

**Si vous voyez "X missions récupérées" mais "0 dans l'UI" :**
- ✅ Le problème vient du **filtrage par progress_status**
- ➡️ Vérifiez que les missions ont bien `progress_status = 'à_assigner'`

### Étape 2 : Vérifier les données brutes

```sql
-- Voir toutes les missions avec leur statut
SELECT 
    id,
    title,
    status,
    progress_status,
    company_id,
    partner_id,
    client_id
FROM missions
ORDER BY created_at DESC;
```

### Étape 3 : Tester sans RLS (temporairement)

```sql
-- ⚠️ ATTENTION : À utiliser UNIQUEMENT pour le diagnostic
ALTER TABLE missions DISABLE ROW LEVEL SECURITY;

-- Testez votre application

-- Puis réactivez RLS
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;
```

Si les missions apparaissent après avoir désactivé RLS, le problème vient des politiques RLS.

## 🛠️ Solutions

### Solution 1 : Corriger les politiques RLS

```bash
# Exécutez le script de correction
cd /Users/paul.p/Documents/develompent/oxo
psql -h dswirxxbzbyhnxsrzyzi.supabase.co -U postgres -d postgres -f supabase/fix_missions_rls_policies.sql
```

### Solution 2 : Ajouter le company_id aux missions

```sql
-- Récupérer votre company_id
SELECT company_id FROM user_roles WHERE user_id = auth.uid();

-- Mettre à jour les missions sans company_id
UPDATE missions 
SET company_id = '<votre-company-id>'
WHERE company_id IS NULL;
```

### Solution 3 : Créer des missions de test

```bash
# Exécutez le script de création de missions de test
psql -h dswirxxbzbyhnxsrzyzi.supabase.co -U postgres -d postgres -f supabase/create_test_missions.sql
```

## 📝 Logs détaillés

Avec les nouveaux logs ajoutés, vous verrez maintenant :

```
👤 Utilisateur connecté: abc-123-def
🎭 Rôle: associate
📊 Missions récupérées depuis Supabase: 5
📋 Première mission: {id: ..., title: ..., progress_status: à_assigner}
✅ Colonne progress_status existe
🔍 Valeur: à_assigner
📈 Distribution des statuts: {à_assigner: 3, en_cours: 1, fait: 1}
📝 Exemples de missions:
  - Mission Test 1 (progress_status: à_assigner)
  - Mission Test 2 (progress_status: en_cours)
  - Mission Test 3 (progress_status: à_assigner)
✅ 5 missions chargées dans le state
📊 Répartition dans l'UI:
   - À assigner: 3
   - En cours: 1
   - Fait: 1
```

## 🎯 Checklist de débogage

- [ ] Vérifier que le script `add_progress_status_to_missions.sql` a été exécuté
- [ ] Vérifier que les missions ont bien `progress_status = 'à_assigner'`
- [ ] Vérifier les logs de l'application (nombre de missions récupérées)
- [ ] Vérifier les politiques RLS avec le script `fix_missions_rls_policies.sql`
- [ ] Vérifier que le `company_id` des missions correspond à celui de l'utilisateur
- [ ] Tester avec des missions de test (`create_test_missions.sql`)

## 📞 Prochaines étapes

1. **Relancez votre application** et regardez les logs dans la console
2. **Copiez-collez les logs** pour analyse
3. **Exécutez les scripts SQL** si nécessaire
4. **Testez à nouveau**

Les logs détaillés vous diront **exactement** où se situe le problème ! 🎯

