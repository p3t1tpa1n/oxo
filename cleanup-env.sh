#!/bin/bash

# Sauvegarder le contenu du fichier .env localement
cp .env .env.backup

# Supprimer le fichier .env du dépôt Git sans le supprimer localement
git rm --cached .env

# Restaurer le fichier .env localement (il ne sera plus suivi par Git)
cp .env.backup .env

# Supprimer la sauvegarde
rm .env.backup

echo "Le fichier .env a été retiré du suivi Git mais conservé localement."
echo "IMPORTANT: Changez immédiatement vos tokens de sécurité car ils ont été exposés dans l'historique Git." 