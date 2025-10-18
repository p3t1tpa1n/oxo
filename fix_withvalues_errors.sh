#!/bin/bash

# Script pour corriger automatiquement toutes les erreurs withValues dans le projet

echo "🔧 Correction des erreurs withValues pour compatibilité Android..."

# Trouver tous les fichiers Dart qui contiennent withValues
find lib -name "*.dart" -type f -exec grep -l "withValues" {} \; | while read file; do
    echo "📝 Correction du fichier: $file"
    
    # Remplacer withValues(alpha: par withOpacity(
    sed -i '' 's/\.withValues(alpha: /\.withOpacity(/g' "$file"
    
    # Remplacer withValues(alpha: par withOpacity( (variante avec espaces)
    sed -i '' 's/\.withValues(alpha:/\.withOpacity(/g' "$file"
done

echo "✅ Correction terminée !"
echo ""
echo "📋 Fichiers corrigés :"
find lib -name "*.dart" -type f -exec grep -l "withOpacity" {} \; | head -10

echo ""
echo "🚀 Vous pouvez maintenant relancer le build Android :"
echo "flutter build apk --release"
