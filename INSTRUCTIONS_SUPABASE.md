# 🔧 Instructions pour configurer Supabase

## 1. Créer un nouveau projet Supabase

1. Allez sur [supabase.com](https://supabase.com)
2. Connectez-vous ou créez un compte
3. Cliquez sur "New Project"
4. Choisissez une organisation
5. Donnez un nom à votre projet (ex: "oxo-app")
6. Créez un mot de passe pour la base de données
7. Sélectionnez une région proche de vous
8. Cliquez sur "Create new project"

## 2. Récupérer les credentials

1. Une fois le projet créé, allez dans **Settings** → **API**
2. Copiez :
   - **Project URL** (ex: `https://abcdefgh.supabase.co`)
   - **anon public** key (longue chaîne de caractères)

## 3. Mettre à jour le code

### Option A : Modifier directement le fichier existant

Ouvrez `lib/services/supabase_service.dart` et remplacez les lignes 15-16 :

```dart
// Remplacez ces valeurs par vos nouvelles credentials
static const defaultUrl = 'https://VOTRE-NOUVELLE-URL.supabase.co';
static const defaultKey = 'VOTRE-NOUVELLE-CLE-API';
```

### Option B : Utiliser le fichier de remplacement

1. Remplacez le contenu de `lib/services/supabase_service.dart` par celui de `lib/services/supabase_service_new.dart`
2. Mettez à jour les credentials dans le nouveau fichier

## 4. Exécuter les scripts SQL

Une fois Supabase configuré, exécutez dans l'ordre :

1. `supabase/create_partner_questionnaire_system.sql`
2. `supabase/test_partner_questionnaire_system.sql`

## 5. Tester la connexion

Relancez l'application et testez le questionnaire partenaire.

## 🔍 Vérification

Si tout fonctionne, vous devriez voir dans les logs :
```
flutter: ✅ Supabase initialisé avec succès
flutter: ✅ Profil partenaire créé avec succès
```

Au lieu de :
```
flutter: ❌ Erreur lors de la création du profil partenaire
```
