# OXO - Plateforme de Gestion des Missions

OXO est une application Flutter qui facilite la gestion des missions entre différents types d'utilisateurs : associés, partenaires, clients et administrateurs.

## Table des matières

- [Technologies utilisées](#technologies-utilisées)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Fonctionnalités](#fonctionnalités)
- [Déploiement](#déploiement)
- [Résolution des problèmes connus](#résolution-des-problèmes-connus)

## Technologies utilisées

- Flutter / Dart
- Supabase (base de données et authentification)
- GitHub (gestion de code source)
- Vercel (déploiement)

## Installation

1. Clonez le dépôt :
   ```bash
   git clone https://github.com/p3t1tpa1n/oxo.git
   ```

2. Accédez au répertoire du projet :
   ```bash
   cd oxo
   ```

3. Installez les dépendances :
   ```bash
   flutter pub get
   ```

4. Créez un fichier `.env` à la racine du projet et ajoutez les variables d'environnement Supabase :
   ```
   SUPABASE_URL=votre_url_supabase
   SUPABASE_ANON_KEY=votre_clé_anon_supabase
   ```

## Utilisation

Pour exécuter l'application en mode développement, utilisez la commande suivante :
```bash
flutter run
```

Pour compiler l'application pour le web :
```bash
flutter build web
```

Pour servir l'application localement :
```bash
cd build/web
python3 -m http.server 8080
```
Puis, ouvrez votre navigateur à l'adresse [http://localhost:8080](http://localhost:8080).

## Fonctionnalités

- **Authentification multi-rôles** : Connexion adaptée aux associés, partenaires, clients et administrateurs
- **Tableau de bord personnalisé** pour chaque type d'utilisateur
- **Gestion des projets** : Création, modification et suivi des projets
- **Gestion des tâches** : Attribution, suivi et mise à jour du statut des tâches
- **Interface responsive** compatible avec les appareils mobiles et de bureau

## Déploiement

### Déploiement Web sur Vercel

1. Connectez votre dépôt GitHub à Vercel
2. Configurez les variables d'environnement dans le projet Vercel :
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
3. Utilisez la commande de build : `flutter build web`
4. Définissez le répertoire de déploiement : `build/web`

### Déploiement Android

Pour créer un APK de l'application :
```bash
flutter build apk --release
```

## Résolution des problèmes connus

### Erreur de relation Supabase

Si vous rencontrez l'erreur "Could not find a relationship between 'tasks' and 'profiles' in the schema cache", vérifiez que les clés étrangères sont correctement définies dans la requête Supabase. Utilisez une sélection directe des tables au lieu de spécifier des clés de relation.

### Problèmes d'authentification

Si vous rencontrez des problèmes avec l'authentification, vérifiez les points suivants :
- Configuration correcte des variables d'environnement
- Accès aux bonnes URLs Supabase
- Gestion des rôles utilisateur correctement implémentée

---

© 2023 OXO. Tous droits réservés.
