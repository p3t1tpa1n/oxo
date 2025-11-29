# Configuration des Statuts de Missions

## 📋 Vue d'ensemble

Ce système permet de gérer **deux types de statuts** pour les missions :

### 1. **Statut d'acceptation** (`status`)
- `pending` : Mission proposée au partenaire
- `accepted` : Mission acceptée par le partenaire
- `rejected` : Mission refusée par le partenaire

### 2. **Statut d'avancement** (`progress_status`)
- `à_assigner` : Mission acceptée mais pas encore assignée
- `en_cours` : Mission en cours d'exécution
- `fait` : Mission terminée

## 🗄️ Structure de la base de données

### Colonnes ajoutées à la table `missions`

| Colonne | Type | Description |
|---------|------|-------------|
| `status` | text | Statut d'acceptation (pending/accepted/rejected) |
| `progress_status` | mission_progress_type | Statut d'avancement (à_assigner/en_cours/fait) |
| `rejection_reason` | text | Raison du refus (optionnel) |

### Index créés
- `idx_missions_progress_status` : Index sur `progress_status` pour améliorer les performances

## 🚀 Installation

### 1. Exécuter le script SQL dans Supabase

```sql
-- Copiez et exécutez le contenu du fichier suivant dans Supabase SQL Editor
\i supabase/add_progress_status_to_missions.sql
```

Ce script va :
- Créer l'enum `mission_progress_type`
- Ajouter la colonne `progress_status` à la table `missions`
- Migrer les données existantes
- Créer les index nécessaires
- Créer une vue `missions_with_full_status` pour faciliter les requêtes

### 2. Vérifier l'installation

```sql
-- Vérifier que la colonne existe
SELECT column_name, data_type, udt_name 
FROM information_schema.columns 
WHERE table_name = 'missions' 
AND column_name = 'progress_status';

-- Vérifier les valeurs possibles
SELECT enumlabel 
FROM pg_enum 
WHERE enumtypid = 'mission_progress_type'::regtype
ORDER BY enumsortorder;

-- Voir quelques exemples de missions
SELECT id, title, status, progress_status 
FROM missions 
LIMIT 5;
```

## 📱 Fonctionnalités de l'application

### Dashboard (pour tous les utilisateurs)
- **Trois colonnes** : "À assigner", "En cours", "Fait"
- **Glisser-déposer** : Déplacez les missions entre les colonnes pour changer leur statut d'avancement
- **Couleurs** :
  - 🟠 Orange : À assigner
  - 🔵 Bleu : En cours
  - 🟢 Vert : Fait

### Page des missions proposées (pour les partenaires)
**Route** : `/partner/proposed-missions`

Cette page permet aux partenaires de :
- Voir toutes les missions qui leur sont proposées (`status = 'pending'`)
- Accepter une mission → change le `status` à `accepted` et `progress_status` à `à_assigner`
- Refuser une mission → change le `status` à `rejected` et permet d'ajouter une raison

## 🔧 API / Méthodes du service

### SupabaseService

```dart
// Mettre à jour le statut d'acceptation
await SupabaseService.updateMissionStatus(missionId, 'accepted');

// Mettre à jour le statut d'avancement
await SupabaseService.updateMissionProgressStatus(missionId, 'en_cours');

// Récupérer les missions proposées à un partenaire
final missions = await SupabaseService.getProposedMissionsForPartner(partnerId);

// Accepter une mission
await SupabaseService.acceptMission(missionId);

// Refuser une mission
await SupabaseService.rejectMission(missionId, reason: 'Trop occupé');
```

## 📊 Workflow complet

```
1. CRÉATION
   └─> Mission créée avec status='pending' et progress_status='à_assigner'

2. PROPOSITION
   └─> Le partenaire voit la mission dans "Missions proposées"
   
3. DÉCISION DU PARTENAIRE
   ├─> ACCEPTATION
   │   └─> status='accepted', progress_status='à_assigner'
   │       └─> La mission apparaît dans le dashboard "À assigner"
   │
   └─> REFUS
       └─> status='rejected'
           └─> La mission n'apparaît plus pour le partenaire

4. PROGRESSION (après acceptation)
   ├─> À assigner → progress_status='à_assigner'
   ├─> En cours → progress_status='en_cours'
   └─> Fait → progress_status='fait'
```

## 🎨 Interface utilisateur

### Dashboard
```
┌─────────────┬─────────────┬─────────────┐
│ À assigner  │  En cours   │    Fait     │
│   (🟠)      │    (🔵)     │    (🟢)     │
├─────────────┼─────────────┼─────────────┤
│ Mission 1   │ Mission 3   │ Mission 5   │
│ Mission 2   │ Mission 4   │ Mission 6   │
└─────────────┴─────────────┴─────────────┘
```

### Page missions proposées (partenaires)
```
┌──────────────────────────────────────┐
│ 📋 Missions Proposées                │
├──────────────────────────────────────┤
│ Mission : Développement site web     │
│ Description : Créer un site...       │
│ Dates : 01/01/2025 → 31/01/2025     │
│ Budget : 5000€                       │
│                                      │
│ [Refuser]  [Accepter]               │
└──────────────────────────────────────┘
```

## 🔐 Politiques RLS (Row Level Security)

Les politiques RLS existantes sur la table `missions` continuent de fonctionner.
Assurez-vous que :

1. Les partenaires peuvent voir leurs missions (`partner_id = auth.uid()`)
2. Les admins/associés peuvent voir toutes les missions de leur entreprise
3. Les partenaires peuvent mettre à jour le `status` de leurs missions
4. Tous les utilisateurs autorisés peuvent mettre à jour `progress_status`

## ✅ Tests à effectuer

1. ✅ Créer une mission et vérifier qu'elle a `status='pending'` et `progress_status='à_assigner'`
2. ✅ Vérifier que la mission apparaît dans "Missions proposées" du partenaire
3. ✅ Accepter une mission et vérifier le changement de statut
4. ✅ Refuser une mission et vérifier qu'elle disparaît
5. ✅ Glisser-déposer une mission dans le dashboard pour changer son `progress_status`
6. ✅ Vérifier que les couleurs et les labels s'affichent correctement

## 🐛 Dépannage

### La colonne `progress_status` n'existe pas
```sql
-- Vérifier si la colonne existe
SELECT column_name FROM information_schema.columns 
WHERE table_name='missions' AND column_name='progress_status';

-- Si elle n'existe pas, exécutez le script SQL complet
```

### Les missions n'apparaissent pas pour les partenaires
```sql
-- Vérifier les missions pending pour un partenaire
SELECT id, title, status, partner_id 
FROM missions 
WHERE partner_id = 'PARTNER_UUID' AND status = 'pending';
```

### Erreur de type enum
```sql
-- Vérifier que l'enum existe
SELECT enumlabel FROM pg_enum 
WHERE enumtypid = 'mission_progress_type'::regtype;
```
