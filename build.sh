#!/bin/bash

# Script de construction pour Vercel
echo "🚀 Début de la construction Flutter Web"

# Vérifier Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé"
    exit 1
fi

# Nettoyer le projet
echo "🧹 Nettoyage du projet..."
flutter clean

# Récupérer les dépendances
echo "📦 Installation des dépendances..."
flutter pub get

# Activer le support web
echo "🌐 Activation du support web..."
flutter config --enable-web

# Construire pour le web
echo "🔨 Construction de l'application web..."
flutter build web --release --web-renderer html

echo "✅ Construction terminée avec succès!" 