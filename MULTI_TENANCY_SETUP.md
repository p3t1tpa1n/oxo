# Configuration Multi-Tenancy par Entreprise

## Vue d'ensemble

Le système de multi-tenancy par entreprise permet à chaque client de voir uniquement les projets et tâches de son entreprise. Cela assure une séparation complète des données entre différentes organisations.

## Structure de la base de données

### Nouvelles tables créées

1. **`companies`** - Table des entreprises
   - `id` (BIGINT, PK) - Identifiant unique
   - `name` (VARCHAR) - Nom de l'entreprise
   - `description` (TEXT) - Description 
   - `address` (TEXT) - Adresse
   - `phone` (VARCHAR) - Téléphone
   - `email` (VARCHAR) - Email de contact
   - `website` (VARCHAR) - Site web
   - `status` (VARCHAR) - Statut (active, inactive, suspended)

### Tables modifiées

2. **`profiles`** - Ajout de la relation entreprise
   - `company_id` (BIGINT, FK) - Référence vers l'entreprise

3. **`projects`** - Ajout de la relation entreprise
   - `company_id` (BIGINT, FK) - Référence vers l'entreprise

## Politiques de sécurité (RLS)

### Règles d'accès par rôle

- **Admins/Associés** : Accès à toutes les données (tous projets, toutes entreprises)
- **Clients** : Accès uniquement aux projets/tâches de leur entreprise
- **Partenaires** : Accès aux projets/tâches de leur entreprise + tâches assignées

### Implémentation RLS

Les politiques Row Level Security filtrent automatiquement :
- **Projets** : Par `company_id` selon l'entreprise de l'utilisateur
- **Tâches** : Via les projets de l'entreprise ou assignation directe
- **Entreprises** : Chaque utilisateur ne voit que son entreprise

## Installation

### 1. Exécuter le script SQL

Exécutez `supabase/create_company_multi_tenancy.sql` dans l'éditeur SQL de Supabase :

```sql
-- Le script va automatiquement :
-- ✅ Créer la table companies
-- ✅ Ajouter company_id aux tables profiles et projects  
-- ✅ Configurer les contraintes FK
-- ✅ Mettre en place les politiques RLS
-- ✅ Créer des entreprises de démonstration
-- ✅ Assigner les clients existants aux entreprises
```

### 2. Vérification de l'installation

Après l'exécution, vérifiez :

```sql
-- Entreprises créées
SELECT id, name, status FROM public.companies ORDER BY id;

-- Distribution des utilisateurs
SELECT 
    c.name as entreprise,
    p.user_role as role,
    COUNT(*) as nombre_utilisateurs
FROM public.profiles p
LEFT JOIN public.companies c ON p.company_id = c.id
GROUP BY c.name, p.user_role
ORDER BY c.name, p.user_role;
```

## Fonctionnalités

### Pour les Clients

- **Vue filtrée** : Seuls les projets/tâches de leur entreprise
- **Statistiques entreprise** : Nombres de projets, tâches en cours/terminées
- **Navigation sécurisée** : Impossible d'accéder aux données d'autres entreprises

### Pour les Admins/Associés

- **Gestion des entreprises** : Création, modification, suppression
- **Assignation utilisateurs** : Affecter des clients à des entreprises
- **Vue globale** : Accès à toutes les données

## API disponibles

### Gestion des entreprises

```dart
// Récupérer toutes les entreprises (admins seulement)
await SupabaseService.getAllCompanies();

// Récupérer l'entreprise de l'utilisateur connecté
await SupabaseService.getUserCompany();

// Créer une entreprise
await SupabaseService.createCompany(
  name: 'Nouvelle Entreprise',
  description: 'Description...',
);

// Assigner un utilisateur à une entreprise
await SupabaseService.assignUserToCompany(userId, companyId);
```

### Données filtrées par entreprise

```dart
// Projets de l'entreprise
await SupabaseService.getCompanyProjects();

// Tâches de l'entreprise  
await SupabaseService.getCompanyTasks();

// Statistiques client
await SupabaseService.getClientCompanyStats();
```

## Migration des données existantes

Le script handle automatiquement :

1. **Création d'entreprises de test** si aucune n'existe
2. **Répartition des clients** entre les entreprises (50/50 par défaut)
3. **Conservation des données** : Aucune perte de données existantes
4. **Compatibilité** : Les anciennes méthodes continuent de fonctionner

## Sécurité

### Isolation des données

- **Niveau base de données** : RLS empêche l'accès inter-entreprises
- **Niveau application** : Les requêtes filtrent automatiquement
- **Niveau interface** : Les clients ne voient que leurs données

### Gestion des permissions

```sql
-- Fonction de sécurité : récupère l'entreprise de l'utilisateur connecté
CREATE FUNCTION get_user_company_id() RETURNS BIGINT

-- Politiques RLS automatiques sur :
-- ✅ projects (filtrage par company_id)
-- ✅ tasks (via projects)  
-- ✅ companies (accès restreint)
```

## Test et validation

### Scénarios de test

1. **Client A** ne peut voir que les projets de son entreprise
2. **Client B** (autre entreprise) voit des projets différents
3. **Admin** voit tous les projets de toutes les entreprises
4. **Création projet** : Associé automatiquement à l'entreprise du créateur

### Commandes de validation

```sql
-- Vérifier l'isolation des données par entreprise
SELECT DISTINCT p.company_id, c.name 
FROM projects p 
JOIN companies c ON p.company_id = c.id;

-- Tester les permissions RLS
SET ROLE authenticated;
SELECT * FROM projects; -- Doit être filtré selon l'utilisateur
```

## Migration en production

1. **Sauvegarde** : Créer un backup complet avant migration
2. **Test en dev** : Valider le script sur environnement de développement
3. **Migration graduelle** : Exécuter pendant une maintenance
4. **Validation** : Tester l'accès client après migration

## Support et dépannage

### Problèmes courants

**Utilisateur sans entreprise** :
```sql
-- Assigner manuellement
UPDATE profiles SET company_id = 1 WHERE user_id = 'user-uuid';
```

**Projet sans entreprise** :
```sql
-- Assigner à l'entreprise du créateur
UPDATE projects SET company_id = (
    SELECT company_id FROM profiles WHERE user_id = projects.created_by
) WHERE company_id IS NULL;
```

**Debug des permissions** :
```sql
-- Vérifier les politiques RLS actives
SELECT * FROM pg_policies WHERE tablename IN ('projects', 'tasks', 'companies');
```

## Évolutions futures

- [ ] Interface d'administration des entreprises
- [ ] Gestion des sous-entreprises (filiales)
- [ ] Rapports multi-entreprises pour admins
- [ ] API de synchronisation inter-entreprises 