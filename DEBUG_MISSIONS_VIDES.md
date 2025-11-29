# Débogage : Pourquoi les missions ne s'affichent pas ?

## 🔍 Diagnostic

Vous voyez les 3 colonnes vides : "À assigner", "En cours", "Fait". Voici comment identifier le problème.

## 📋 Étape 1 : Vérifier la colonne `progress_status`

**Exécutez dans Supabase SQL Editor** :

```sql
-- Vérifier si la colonne existe
SELECT column_name, data_type, udt_name
FROM information_schema.columns 
WHERE table_name = 'missions' 
AND column_name = 'progress_status';
```

### ✅ Si la colonne existe
Passez à l'étape 2.

### ❌ Si la colonne n'existe PAS
Exécutez le script :
```sql
\i supabase/add_progress_status_to_missions.sql
```
Ou copiez-collez le contenu du fichier dans Supabase SQL Editor.

## 📋 Étape 2 : Vérifier les missions existantes

```sql
-- Compter les missions
SELECT COUNT(*) as total FROM missions;

-- Voir les missions et leurs statuts
SELECT 
    id,
    title,
    status,
    progress_status,
    created_at
FROM missions 
ORDER BY created_at DESC 
LIMIT 5;
```

### ✅ Si vous avez des missions avec `progress_status`
Le problème est dans le code frontend. Vérifiez les logs dans la console.

### ⚠️ Si vous avez des missions SANS `progress_status` (NULL)
Mettez à jour les missions existantes :
```sql
-- Mettre à jour toutes les missions qui ont progress_status NULL
UPDATE missions 
SET progress_status = 'à_assigner'
WHERE progress_status IS NULL;
```

### ❌ Si vous n'avez AUCUNE mission
Créez des missions de test :
```sql
\i supabase/create_test_missions.sql
```
Ou copiez-collez le contenu du fichier.

## 📋 Étape 3 : Vérifier les logs de l'application

1. **Ouvrez la console de débogage** dans votre application
2. **Rechargez le dashboard**
3. **Cherchez les logs** qui commencent par 📊, ✅, ❌, etc.

### Exemples de logs attendus :

```
✅ Cas normal :
📊 Missions récupérées: 6
✅ Colonne progress_status existe
🔍 Valeur: à_assigner
📈 Distribution des statuts: {à_assigner: 2, en_cours: 2, fait: 2}
✅ 6 missions chargées dans le state
```

```
❌ Problème - colonne manquante :
📊 Missions récupérées: 3
❌ Colonne progress_status MANQUANTE!
📝 Colonnes disponibles: [id, title, description, status, ...]
```

```
⚠️ Problème - pas de missions :
📊 Missions récupérées: 0
⚠️ Aucune mission dans la base de données
```

## 🔧 Solutions selon les logs

### Log : "❌ Colonne progress_status MANQUANTE!"
**Solution** : Exécutez `add_progress_status_to_missions.sql`

### Log : "⚠️ Aucune mission dans la base de données"
**Solution** : Exécutez `create_test_missions.sql`

### Log : "📈 Distribution des statuts: {null: 5}"
**Solution** : Mettez à jour les missions avec :
```sql
UPDATE missions SET progress_status = 'à_assigner' WHERE progress_status IS NULL;
```

### Log : "Erreur lors du chargement des missions: ..."
**Solution** : Vérifiez les permissions RLS avec :
```sql
-- Vérifier les politiques RLS
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'missions';
```

## 📊 Script de diagnostic complet

Exécutez ce script pour un diagnostic complet :

```sql
\i supabase/check_missions_status.sql
```

Il vous donnera :
1. ✅ Statut de la colonne `progress_status`
2. 📊 Nombre total de missions
3. 📈 Distribution des statuts
4. 📋 Exemples de missions
5. 🔍 Liste de toutes les colonnes

## 🚀 Solution rapide (Quick Fix)

Si vous voulez juste que ça marche immédiatement :

```sql
-- 1. Ajouter la colonne si elle n'existe pas
\i supabase/add_progress_status_to_missions.sql

-- 2. Créer des missions de test
\i supabase/create_test_missions.sql

-- 3. Rafraîchir l'application
-- Rechargez la page dans votre navigateur
```

## 📝 Checklist de vérification

- [ ] La colonne `progress_status` existe dans la table `missions`
- [ ] L'enum `mission_progress_type` existe avec les valeurs correctes
- [ ] Il y a au moins une mission dans la base de données
- [ ] Les missions ont un `progress_status` non-NULL
- [ ] Les logs de l'application montrent des missions récupérées
- [ ] Les logs montrent que `progress_status` existe dans les données
- [ ] La distribution des statuts n'est pas vide

## 🆘 Si rien ne fonctionne

1. **Vérifiez votre connexion Supabase** :
   ```dart
   debugPrint('Supabase connected: ${SupabaseService.client != null}');
   debugPrint('User: ${SupabaseService.currentUser?.email}');
   ```

2. **Vérifiez les permissions RLS** :
   - Les partenaires voient leurs missions (`partner_id = auth.uid()`)
   - Les admins/associés voient toutes les missions de leur entreprise

3. **Contactez le support** avec :
   - Les logs de la console
   - Le résultat du script `check_missions_status.sql`
   - Votre rôle utilisateur
