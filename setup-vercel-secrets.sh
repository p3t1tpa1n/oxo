#!/bin/bash

# Assurez-vous d'être connecté à Vercel (vercel login) avant d'exécuter ce script

# Variables d'environnement Supabase
vercel env add SUPABASE_URL
vercel env add SUPABASE_ANON_KEY

# Variables d'environnement Flutter
vercel env add FLUTTER_WEB_CANVASKIT_URL -v "/canvaskit/"
vercel env add FLUTTER_BUILD_MODE -v "release" 
vercel env add FLUTTER_BASE_HREF -v "/"

echo "Secrets configurés avec succès!"
echo "Pour vérifier les secrets configurés, exécutez: vercel env ls" 