# 👥 Rôles Utilisateur - Interface iOS

## 🎯 **Adaptation par Rôle Implémentée**

L'interface iOS s'adapte maintenant automatiquement selon le rôle de l'utilisateur connecté, offrant une expérience personnalisée et des permissions appropriées.

---

## 🔴 **ADMIN** - Contrôle Total

### **Onglets Disponibles (5) :**
1. **🏠 Accueil** - Vue d'ensemble complète
2. **📄 Projets** - Tous les projets de toutes les entreprises
3. **✅ Tâches** - Toutes les tâches système
4. **⚙️ Gestion** - Outils d'administration
5. **👤 Profil** - Paramètres personnels

### **Permissions & Actions :**
- ✅ Voir **toutes les données** de toutes les entreprises
- ✅ Créer/modifier/supprimer **projets et tâches**
- ✅ **Gestion des utilisateurs** (ajouter, modifier rôles)
- ✅ **Gestion des entreprises** (créer, assigner)
- ✅ **Examiner les demandes clients** (propositions de projets)
- ✅ **Messagerie** avec tous les utilisateurs
- ✅ Accès à **tous les outils d'administration**

### **Données Affichées :**
- Statistiques globales de toutes les entreprises
- Tous les projets et tâches système
- Interface complète sans restrictions

---

## 🔵 **ASSOCIÉ** - Gestion d'Entreprise

### **Onglets Disponibles (4) :**
1. **🏠 Accueil** - Vue d'ensemble de son entreprise
2. **📄 Projets** - Projets de son entreprise
3. **✅ Tâches** - Tâches de son entreprise
4. **👤 Profil** - Paramètres personnels

### **Permissions & Actions :**
- ✅ Voir **toutes les données de son entreprise**
- ✅ Créer/modifier **projets et tâches** pour son entreprise
- ✅ **Messagerie** avec les utilisateurs de son entreprise
- ✅ Gérer les projets et équipes
- ❌ Pas de gestion globale des utilisateurs
- ❌ Pas d'accès aux autres entreprises

### **Données Affichées :**
- Statistiques de son entreprise uniquement
- Projets où son entreprise est impliquée
- Tâches de son équipe et projets

---

## 🟠 **PARTENAIRE** - Vue Limitée aux Assignations

### **Onglets Disponibles (4) :**
1. **🏠 Mon Activité** - Ses projets et tâches
2. **💼 Mes Projets** - Projets où il est assigné
3. **📋 Mes Tâches** - Tâches qui lui sont assignées
4. **👤 Profil** - Paramètres personnels

### **Permissions & Actions :**
- ✅ Voir **seulement ses projets/tâches assignés**
- ✅ **Messagerie** avec son équipe
- ✅ Consulter les détails de ses assignations
- ❌ **Pas de création** de projets/tâches
- ❌ Pas d'accès aux autres projets
- ❌ Vue limitée aux données qui le concernent

### **Données Affichées :**
- Filtrage automatique : `assigned_to = user_id` ou `created_by = user_id`
- Statistiques personnelles uniquement
- Projets liés à ses tâches

### **Interface Spécialisée :**
- **Actions rapides limitées** : Messagerie, Profil
- **Pas de boutons de création** 
- **Affichage en lecture seule** pour les détails

---

## 🟢 **CLIENT** - Suivi de Projets

### **Onglets Disponibles (4) :**
1. **🏠 Mes Projets** - Vue client de ses projets
2. **📁 Mes Projets** - Liste détaillée
3. **📨 Demandes** - Nouvelles demandes de projets
4. **👤 Profil** - Paramètres personnels

### **Permissions & Actions :**
- ✅ Voir **seulement ses projets** et leur progression
- ✅ **Créer des demandes** de projets
- ✅ **Messagerie** avec l'équipe du projet
- ✅ Suivre l'avancement des tâches de ses projets
- ❌ **Aucune modification** des projets/tâches
- ❌ Pas d'accès aux outils de gestion

### **Données Affichées :**
- Appels API spécifiques : `getClientRecentProjects()`, `getClientActiveTasks()`
- Filtrage par entreprise du client
- Vue en lecture seule des tâches

### **Interface Client :**
- **Actions principales** : Nouvelle demande, Messagerie
- **Formulaire de demande** avec titre, description, budget
- **Suivi d'avancement** sans modification
- **Interface simplifiée** et claire

---

## 🔧 **Implémentation Technique**

### **Chargement des Données Adaptatif :**
```dart
switch (_userRole) {
  case UserRole.admin:
  case UserRole.associe:
    // Toutes les données de l'entreprise
    tasks = await SupabaseService.getCompanyTasks();
    projects = await SupabaseService.getProjectProposals();
    
  case UserRole.partenaire:
    // Filtre par assignation
    tasks = allTasks.where((t) => 
      t['assigned_to'] == currentUserId ||
      t['created_by'] == currentUserId).toList();
    
  case UserRole.client:
    // Données client uniquement
    projects = await SupabaseService.getClientRecentProjects();
    tasks = await SupabaseService.getClientActiveTasks();
}
```

### **Navigation Adaptative :**
```dart
int _getTabCount() {
  switch (_userRole) {
    case UserRole.admin: return 5;
    case UserRole.associe: return 4;
    case UserRole.partenaire: return 4;
    case UserRole.client: return 4;
    default: return 2;
  }
}
```

### **Interface Conditionnelle :**
- **Boutons de création** : Affichés selon les permissions
- **Actions disponibles** : Adaptées au rôle
- **Titres et messages** : Personnalisés par contexte
- **Couleurs et icônes** : Cohérentes avec le rôle

---

## 🛡️ **Sécurité Implémentée**

### **Côté Client (Flutter) :**
- Filtrage des données selon le rôle
- Interface adaptée aux permissions
- Actions désactivées si non autorisées

### **Côté Serveur (Supabase RLS) :**
- Politiques Row Level Security par entreprise
- Filtrage automatique des requêtes SQL
- Fonction `get_user_company_id()` pour la sécurité

### **Double Protection :**
1. **Interface** : L'utilisateur ne voit que ce qu'il doit voir
2. **Base de données** : RLS empêche l'accès aux données non autorisées

---

## 🎨 **Design Cohérent**

- **Couleurs de marque** : `#1784AF` et `#122B35` sur toutes les interfaces
- **Typographie Apple** : SF Pro pour tous les rôles
- **Icons adaptées** : Chaque rôle a ses icônes spécifiques
- **Workflow unifié** : Navigation cohérente malgré les différences

Chaque utilisateur a maintenant une expérience parfaitement adaptée à son rôle et ses responsabilités ! 🎉 