#!/bin/bash

# Script pour tester localement les étapes du workflow GitHub Actions

echo "====== Début du test du workflow ======"

# Vérification des versions de Flutter et Dart
echo "Vérification des versions de Flutter et Dart..."
flutter --version
dart --version

# Création du fichier .env (utilise le fichier existant dans le développement local)
echo "Vérification du fichier .env..."
if [ -f .env ]; then
  echo "Fichier .env trouvé"
  grep -v "GITHUB_TOKEN" .env
else
  echo "ERREUR: Fichier .env non trouvé"
  exit 1
fi

# Installation des dépendances
echo "Installation des dépendances..."
flutter pub get
flutter pub deps

# Analyse du code source
echo "Analyse du code source..."
flutter analyze --no-fatal-warnings

# Exécution des tests
echo "Exécution des tests..."
flutter test --no-pub --coverage || echo "Certains tests ont échoué, mais on continue"

# Construire l'APK
echo "Construction de l'APK..."
flutter build apk --release --no-pub --verbose || echo "La construction de l'APK a échoué, mais on continue"

echo "====== Fin du test du workflow ======" 