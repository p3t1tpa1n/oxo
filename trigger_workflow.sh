#!/bin/bash

# Configuration
GITHUB_TOKEN="YOUR_GITHUB_TOKEN"
REPO_OWNER="votre-org"
REPO_NAME="votre-repo"

# Déclencher le workflow
curl -X POST \
  -H "Authorization: token $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/dispatches" \
  -d '{"event_type":"run_workflow"}'

echo "Workflow déclenché avec succès" 