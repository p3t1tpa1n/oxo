#!/bin/bash

# Script de build pour la version PWA optimisée de OXO

# Définir les couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}    Construction de OXO PWA         ${NC}"
echo -e "${BLUE}=====================================${NC}"

# 1. Vérification que Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter n'est pas installé ou n'est pas dans le PATH.${NC}"
    exit 1
fi

# 2. Nettoyer les builds précédents
echo -e "${GREEN}Nettoyage des builds précédents...${NC}"
flutter clean
rm -rf build/web

# 3. Vérifier que les dépendances sont à jour
echo -e "${GREEN}Mise à jour des dépendances...${NC}"
flutter pub get

# 4. Créer les dossiers nécessaires s'ils n'existent pas
echo -e "${GREEN}Création des dossiers requis...${NC}"
mkdir -p web/screenshots
mkdir -p web/icons

# 5. Vérification des fichiers essentiels
if [ ! -f "web/offline.html" ]; then
    echo -e "${RED}Le fichier offline.html est manquant.${NC}"
    exit 1
fi

if [ ! -f "web/service-worker.js" ]; then
    echo -e "${RED}Le fichier service-worker.js est manquant.${NC}"
    exit 1
fi

# 6. Construction de la PWA
echo -e "${GREEN}Construction de la PWA...${NC}"
flutter build web \
    --web-renderer canvaskit \
    --release \
    --pwa-strategy offline-first \
    --base-href "/" \
    --dart-define=SUPABASE_URL=votre_url_supabase \
    --dart-define=SUPABASE_ANON_KEY=votre_cle_anon

# 7. Copier le service worker personnalisé
echo -e "${GREEN}Configuration du service worker...${NC}"
cp web/service-worker.js build/web/

# 8. Vérification que tout est bien construit
if [ ! -d "build/web" ]; then
    echo -e "${RED}La construction a échoué, le dossier build/web n'existe pas.${NC}"
    exit 1
fi

echo -e "${GREEN}Vérification des fichiers PWA essentiels...${NC}"
if [ ! -f "build/web/index.html" ]; then
    echo -e "${RED}index.html est manquant dans le build.${NC}"
    exit 1
fi

if [ ! -f "build/web/manifest.json" ]; then
    echo -e "${RED}manifest.json est manquant dans le build.${NC}"
    exit 1
fi

if [ ! -f "build/web/flutter_service_worker.js" ]; then
    echo -e "${RED}flutter_service_worker.js est manquant dans le build.${NC}"
    exit 1
fi

# 9. Afficher des instructions pour le déploiement
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}PWA construite avec succès !${NC}"
echo -e "${BLUE}=====================================${NC}"
echo -e "Le build se trouve dans ${BLUE}build/web/${NC}"
echo -e ""
echo -e "Pour tester localement :"
echo -e "  cd build/web"
echo -e "  python -m http.server 8000"
echo -e ""
echo -e "Puis accédez à ${BLUE}http://localhost:8000${NC} dans votre navigateur"
echo -e ""
echo -e "Pour le déploiement en production :"
echo -e "1. Remplacez les valeurs 'votre_url_supabase' et 'votre_cle_anon' dans ce script"
echo -e "2. Copiez le contenu du dossier build/web vers votre serveur web"
echo -e "3. Assurez-vous que votre serveur est configuré pour HTTPS"
echo -e "4. Configurez votre serveur pour rediriger toutes les requêtes vers index.html"
echo -e "" 