#!/bin/bash

# Script pour déployer manuellement l'application sur Vercel

echo "===== Déploiement sur Vercel ====="

# Construction de l'application web avec les bonnes variables d'environnement
echo "Construction de l'application web..."
flutter build web \
    --web-renderer canvaskit \
    --release \
    --pwa-strategy offline-first \
    --base-href "/" \
    --dart-define=SUPABASE_URL=https://dswirxxbzbyhnxsrzyzi.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzd2lyeHhiemJ5aG54c3J6eXppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxMTE0MTksImV4cCI6MjA2NDY4NzQxOX0.eIpOuCszUaldsiIxb9WzQcra34VbImWaRHx5lysPtOg

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