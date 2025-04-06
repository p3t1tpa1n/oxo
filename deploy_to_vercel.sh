#!/bin/bash

# Script pour déployer manuellement l'application sur Vercel

echo "===== Déploiement sur Vercel ====="

# Construction de l'application web
echo "Construction de l'application web..."
flutter build web --release

# Installation de Vercel CLI si ce n'est pas déjà fait
if ! command -v vercel &> /dev/null; then
    echo "Installation de Vercel CLI..."
    npm install -g vercel
fi

# Demande de confirmation avant déploiement
read -p "Êtes-vous sûr de vouloir déployer sur Vercel? (o/n) " reponse
if [[ $reponse != "o" && $reponse != "O" ]]; then
    echo "Déploiement annulé"
    exit 0
fi

# Déploiement sur Vercel
echo "Déploiement en cours..."
cd build/web
vercel deploy --prod

echo "===== Déploiement terminé =====" 