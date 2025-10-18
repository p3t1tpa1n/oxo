#!/bin/bash

# Script de déploiement complet sur Vercel pour OXO
# Ce script construit et déploie l'application avec toutes les optimisations

# Définir les couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}    DÉPLOIEMENT OXO SUR VERCEL      ${NC}"
echo -e "${BLUE}=====================================${NC}"

# 1. Vérification des prérequis
echo -e "${YELLOW}Vérification des prérequis...${NC}"

# Vérifier Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter n'est pas installé ou n'est pas dans le PATH.${NC}"
    exit 1
fi

# Vérifier Node.js et npm
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js n'est pas installé.${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}npm n'est pas installé.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prérequis vérifiés${NC}"

# 2. Nettoyage
echo -e "${YELLOW}Nettoyage des builds précédents...${NC}"
flutter clean
rm -rf build/web

# 3. Mise à jour des dépendances
echo -e "${YELLOW}Mise à jour des dépendances...${NC}"
flutter pub get

# 4. Construction optimisée pour la production
echo -e "${YELLOW}Construction de l'application web...${NC}"
flutter build web \
    --web-renderer canvaskit \
    --release \
    --pwa-strategy offline-first \
    --base-href "/" \
    --dart-define=SUPABASE_URL=https://dswirxxbzbyhnxsrzyzi.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzd2lyeHhiemJ5aG54c3J6eXppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxMTE0MTksImV4cCI6MjA2NDY4NzQxOX0.eIpOuCszUaldsiIxb9WzQcra34VbImWaRHx5lysPtOg

# 5. Vérification du build
if [ ! -d "build/web" ]; then
    echo -e "${RED}La construction a échoué, le dossier build/web n'existe pas.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Application construite avec succès${NC}"

# 6. Installation de Vercel CLI si nécessaire
if ! command -v vercel &> /dev/null; then
    echo -e "${YELLOW}Installation de Vercel CLI...${NC}"
    npm install -g vercel
fi

# 7. Configuration Vercel
echo -e "${YELLOW}Configuration de Vercel...${NC}"

# Créer un fichier .vercelignore si il n'existe pas
if [ ! -f ".vercelignore" ]; then
    cat > .vercelignore << EOF
# Fichiers à ignorer pour Vercel
node_modules/
.git/
.dart_tool/
build/
*.log
.env
*.md
supabase/
test/
EOF
    echo -e "${GREEN}✅ Fichier .vercelignore créé${NC}"
fi

# 8. Déploiement
echo -e "${YELLOW}Déploiement sur Vercel...${NC}"

# Aller dans le dossier build/web
cd build/web

# Déploiement
echo -e "${BLUE}Lancement du déploiement...${NC}"
vercel --prod

# 9. Instructions finales
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}DÉPLOIEMENT TERMINÉ !${NC}"
echo -e "${BLUE}=====================================${NC}"
echo -e ""
echo -e "Votre application OXO est maintenant déployée sur Vercel !"
echo -e ""
echo -e "Prochaines étapes :"
echo -e "1. ${YELLOW}Configurez votre domaine personnalisé${NC} (optionnel)"
echo -e "2. ${YELLOW}Testez toutes les fonctionnalités${NC}"
echo -e "3. ${YELLOW}Partagez le lien avec vos utilisateurs${NC}"
echo -e ""
echo -e "Fonctionnalités déployées :"
echo -e "✅ Authentification utilisateurs"
echo -e "✅ Gestion des profils partenaires"
echo -e "✅ Système de missions"
echo -e "✅ Messagerie"
echo -e "✅ Calendrier des disponibilités"
echo -e "✅ Interface responsive (mobile/desktop)"
echo -e ""
echo -e "${GREEN}🎉 Félicitations ! Votre application OXO est en ligne ! 🎉${NC}"
