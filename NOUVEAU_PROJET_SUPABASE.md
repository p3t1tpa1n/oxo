# 🚀 Créer un nouveau projet Supabase

## Étapes détaillées :

### 1. Aller sur Supabase
- Ouvrez [supabase.com](https://supabase.com)
- Connectez-vous avec votre compte

### 2. Créer un nouveau projet
- Cliquez sur **"New Project"**
- Choisissez votre organisation
- Nom du projet : `oxo-app` (ou autre nom de votre choix)
- Mot de passe de la base de données : `VotreMotDePasseSecurise123!`
- Région : Choisissez la plus proche de vous (ex: Europe West)
- Cliquez sur **"Create new project"**

### 3. Attendre la création
- Le projet prend 2-3 minutes à se créer
- Vous verrez un écran de chargement

### 4. Récupérer les nouvelles credentials
Une fois créé, allez dans :
- **Settings** (icône d'engrenage) → **API**
- Copiez :
  - **Project URL** (ex: `https://abcdefghijklmnop.supabase.co`)
  - **anon public** key (longue chaîne commençant par `eyJ...`)

### 5. Mettre à jour votre code

Remplacez dans `lib/services/supabase_service.dart` :

```dart
// Ancien (ne fonctionne plus)
static const defaultUrl = 'https://dswirxxbzbyhnxsrzyzi.supabase.co';
static const defaultKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzd2lyeHhiemJ5aG54c3J6eXppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxMTE0MTksImV4cCI6MjA2NDY4NzQxOX0.eIpOuCszUaldsiIxb9WzQcra34VbImWaRHx5lysPtOg';

// Nouveau (vos nouvelles credentials)
static const defaultUrl = 'https://VOTRE-NOUVELLE-URL.supabase.co';
static const defaultKey = 'VOTRE-NOUVELLE-CLE-API';
```

### 6. Exécuter les scripts SQL

Dans l'éditeur SQL de Supabase, exécutez dans l'ordre :

1. **D'abord** : `supabase/create_partner_questionnaire_system.sql`
2. **Ensuite** : `supabase/test_partner_questionnaire_system.sql`

### 7. Tester l'application

Relancez votre application Flutter et testez le questionnaire partenaire.

## ✅ Vérification

Si tout fonctionne, vous devriez voir :
```
flutter: ✅ Supabase initialisé avec succès
flutter: ✅ Profil partenaire créé avec succès
```

Au lieu de l'erreur DNS précédente.
