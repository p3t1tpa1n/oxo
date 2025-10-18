#!/bin/bash

# Script de build pour toutes les plateformes OXO
# Ce script construit l'application pour Web, iOS, macOS et Android

# Définir les couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}    BUILD OXO - TOUTES PLATEFORMES  ${NC}"
echo -e "${BLUE}=====================================${NC}"

# 1. Vérification des prérequis
echo -e "${YELLOW}Vérification des prérequis...${NC}"

# Vérifier Flutter
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}Flutter n'est pas installé ou n'est pas dans le PATH.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Flutter détecté${NC}"

# 2. Nettoyage
echo -e "${YELLOW}Nettoyage des builds précédents...${NC}"
flutter clean
flutter pub get

# 3. Correction automatique des erreurs withValues
echo -e "${YELLOW}Correction des erreurs withValues...${NC}"
find lib -name "*.dart" -type f -exec sed -i '' 's/\.withValues(alpha: /\.withOpacity(/g' {} \;
find lib -name "*.dart" -type f -exec sed -i '' 's/\.withValues(alpha:/\.withOpacity(/g' {} \;

echo -e "${GREEN}✅ Erreurs withValues corrigées${NC}"

# 4. Build Web (PWA)
echo -e "${YELLOW}Construction de la version Web (PWA)...${NC}"
flutter build web \
    --web-renderer canvaskit \
    --release \
    --pwa-strategy offline-first \
    --base-href "/" \
    --dart-define=SUPABASE_URL=https://dswirxxbzbyhnxsrzyzi.supabase.co \
    --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzd2lyeHhiemJ5aG54c3J6eXppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxMTE0MTksImV4cCI6MjA2NDY4NzQxOX0.eIpOuCszUaldsiIxb9WzQcra34VbImWaRHx5lysPtOg

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build Web réussi${NC}"
else
    echo -e "${RED}❌ Build Web échoué${NC}"
fi

# 5. Build macOS
echo -e "${YELLOW}Construction de la version macOS...${NC}"
flutter build macos --release

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build macOS réussi${NC}"
else
    echo -e "${RED}❌ Build macOS échoué${NC}"
fi

# 6. Build iOS (si sur macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${YELLOW}Construction de la version iOS...${NC}"
    flutter build ios --release --no-codesign
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Build iOS réussi${NC}"
    else
        echo -e "${RED}❌ Build iOS échoué${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Build iOS ignoré (pas sur macOS)${NC}"
fi

# 7. Build Android (si Android SDK disponible)
if [ -n "$ANDROID_HOME" ] || command -v adb &> /dev/null; then
    echo -e "${YELLOW}Construction de la version Android...${NC}"
    flutter build apk --release
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Build Android réussi${NC}"
    else
        echo -e "${RED}❌ Build Android échoué${NC}"
    fi
else
    echo -e "${YELLOW}⚠️ Build Android ignoré (Android SDK non trouvé)${NC}"
    echo -e "${YELLOW}   Pour activer Android, installez Android Studio et configurez ANDROID_HOME${NC}"
fi

# 8. Résumé
echo -e "${BLUE}=====================================${NC}"
echo -e "${GREEN}BUILD TERMINÉ !${NC}"
echo -e "${BLUE}=====================================${NC}"
echo -e ""
echo -e "📱 Plateformes construites :"
echo -e "✅ Web (PWA) - build/web/"
echo -e "✅ macOS - build/macos/"
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "✅ iOS - build/ios/"
fi
if [ -n "$ANDROID_HOME" ] || command -v adb &> /dev/null; then
    echo -e "✅ Android - build/app/outputs/flutter-apk/"
fi
echo -e ""
echo -e "🚀 Pour déployer :"
echo -e "   Web: ./deploy_complete.sh"
echo -e "   macOS: flutter run -d macos"
echo -e "   iOS: flutter run -d ios"
echo -e "   Android: flutter run -d android"
echo -e ""
echo -e "${GREEN}🎉 Toutes les plateformes sont prêtes ! 🎉${NC}"
