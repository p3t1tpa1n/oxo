# 🔧 Fix : Missions vides dans le dashboard

## 🎯 Problème identifié

L'application affiche **"0 missions récupérées"** alors que les missions existent dans la base de données avec `progress_status = 'à_assigner'`.

**Cause probable :** Les politiques RLS (Row Level Security) bloquent l'accès aux missions.

## 📋 Plan d'action en 3 étapes

### Étape 1 : Diagnostic - Vérifier que c'est bien un problème RLS

#### 1.1 Relancer l'application avec les nouveaux logs

```bash
cd /Users/paul.p/Documents/develompent/oxo
flutter run -d macos
```

**Regardez les nouveaux logs :**
```
🔍 Récupération des missions avec statuts...
👤 Utilisateur actuel: <uuid>
🎭 Rôle actuel: <role>
📊 Test de connexion à la table missions...
✅ 0 missions récupérées
⚠️ ATTENTION: Aucune mission récupérée!
🏢 Company ID de l'utilisateur: <company-id>
🎭 Rôle de l'utilisateur: <role>
```

**Notez votre `company_id` et votre `role` !**

#### 1.2 Exécuter le script de diagnostic SQL

Dans le **SQL Editor** de Supabase Dashboard, exécutez :

```sql
-- Copier-coller le contenu de supabase/diagnose_missions_access.sql
```

Cela vous montrera :
- ✅ Combien de missions existent dans la table
- ✅ Si RLS est activé
- ✅ Quelles politiques RLS sont en place
- ✅ Si votre `company_id` correspond aux missions

#### 1.3 Test temporaire : Désactiver RLS

**⚠️ ATTENTION : À faire UNIQUEMENT pour le diagnostic !**

Dans Supabase SQL Editor :

```sql
-- Désactiver RLS temporairement
ALTER TABLE missions DISABLE ROW LEVEL SECURITY;
```

**Puis relancez votre application.**

**Si les missions apparaissent maintenant :**
✅ Le problème vient bien des politiques RLS !

**Réactivez immédiatement RLS :**
```sql
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;
```

---

### Étape 2 : Correction - Fixer les politiques RLS

#### Option A : Politiques RLS strictes (RECOMMANDÉ)

Exécutez le script `supabase/fix_missions_rls_policies.sql` dans Supabase SQL Editor.

Ce script :
- ✅ Supprime les anciennes politiques
- ✅ Crée des politiques basées sur le rôle utilisateur
- ✅ Admin voit tout
- ✅ Associé voit les missions de son entreprise
- ✅ Partenaire voit ses missions assignées
- ✅ Client voit ses propres missions

#### Option B : Politiques RLS permissives (TEMPORAIRE - pour tester)

Si l'Option A ne fonctionne pas, utilisez des politiques plus permissives :

```sql
-- Supprimer toutes les politiques
DROP POLICY IF EXISTS "missions_select_policy" ON missions;
DROP POLICY IF EXISTS "missions_insert_policy" ON missions;
DROP POLICY IF EXISTS "missions_update_policy" ON missions;
DROP POLICY IF EXISTS "missions_delete_policy" ON missions;

-- Politique très permissive : tous les utilisateurs authentifiés peuvent tout voir
CREATE POLICY "missions_select_all" ON missions
    FOR SELECT
    TO authenticated
    USING (true);

-- Politique d'insertion : tous les utilisateurs authentifiés
CREATE POLICY "missions_insert_all" ON missions
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Politique de mise à jour : tous les utilisateurs authentifiés
CREATE POLICY "missions_update_all" ON missions
    FOR UPDATE
    TO authenticated
    USING (true);

-- Politique de suppression : seulement admin
CREATE POLICY "missions_delete_admin" ON missions
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_roles
            WHERE user_roles.user_id = auth.uid()
            AND user_roles.role = 'admin'
        )
    );
```

**⚠️ Ces politiques sont TROP permissives pour la production !** Utilisez-les uniquement pour tester, puis revenez à l'Option A.

---

### Étape 3 : Vérification - S'assurer que tout fonctionne

#### 3.1 Vérifier les company_id

Si les missions n'ont pas de `company_id`, ajoutez-le :

```sql
-- Voir votre company_id
SELECT user_id, company_id, role 
FROM user_roles 
WHERE user_id = auth.uid();

-- Mettre à jour les missions sans company_id
UPDATE missions 
SET company_id = '<VOTRE-COMPANY-ID>'
WHERE company_id IS NULL;
```

#### 3.2 Vérifier les progress_status

```sql
-- Vérifier la distribution des statuts
SELECT 
    COALESCE(progress_status::text, 'NULL') as progress_status,
    COUNT(*) as count
FROM missions
GROUP BY progress_status;

-- Mettre à jour les missions sans progress_status
UPDATE missions 
SET progress_status = 'à_assigner'::mission_progress_type
WHERE progress_status IS NULL;
```

#### 3.3 Créer des missions de test

Si vous voulez des données de test :

```sql
-- Exécuter supabase/create_test_missions.sql
```

#### 3.4 Relancer l'application

```bash
flutter run -d macos
```

**Vous devriez maintenant voir :**
```
✅ X missions récupérées
📊 Répartition dans l'UI:
   - À assigner: X
   - En cours: X
   - Fait: X
```

---

## 🎯 Checklist finale

- [ ] Logs montrent le `company_id` et le `role` de l'utilisateur
- [ ] Script de diagnostic exécuté
- [ ] Test avec RLS désactivé (puis réactivé)
- [ ] Politiques RLS corrigées (Option A ou B)
- [ ] `company_id` ajouté aux missions si nécessaire
- [ ] `progress_status` défini sur toutes les missions
- [ ] Application relancée
- [ ] Missions visibles dans le dashboard ✅

---

## 📞 Si ça ne fonctionne toujours pas

Copiez-collez ici :

1. **Les logs complets de l'application**
2. **Le résultat du script de diagnostic SQL**
3. **Votre rôle utilisateur et company_id**

Je pourrai alors identifier précisément le problème ! 🔍

