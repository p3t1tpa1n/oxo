# 🏢 **CONFIGURATION DES ACTIONS COMMERCIALES**

## 📋 **ÉTAPES DE CONFIGURATION**

### **1. EXÉCUTER LE SCRIPT SQL DANS SUPABASE**

Pour activer les actions commerciales, vous devez d'abord créer la table dans Supabase :

#### **🔗 Étapes :**
1. **Ouvrir l'éditeur SQL de Supabase** :
   - Aller sur [https://app.supabase.com](https://app.supabase.com)
   - Ouvrir votre projet
   - Cliquer sur **"SQL Editor"** dans le menu de gauche

2. **Copier et exécuter le script** :
   - Ouvrir le fichier `supabase/create_commercial_actions_table.sql`
   - Copier **tout le contenu** du fichier
   - Coller dans l'éditeur SQL de Supabase
   - Cliquer sur **"Run"** pour exécuter

3. **Vérifier la création** :
   - Aller dans **"Table Editor"**
   - Vous devriez voir la nouvelle table `commercial_actions`

---

## 🗄️ **STRUCTURE DE LA TABLE CRÉÉE**

### **📊 Colonnes principales :**
```sql
commercial_actions (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) -- 'call', 'email', 'meeting', 'follow_up', 'proposal', 'negotiation'
    status VARCHAR(50) -- 'planned', 'in_progress', 'completed', 'cancelled'
    priority VARCHAR(20) -- 'low', 'medium', 'high', 'urgent'
    
    -- Informations client
    client_name VARCHAR(255) NOT NULL,
    contact_person VARCHAR(255),
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    
    -- Informations commerciales
    estimated_value DECIMAL(12,2),
    actual_value DECIMAL(12,2),
    
    -- Dates
    due_date TIMESTAMPTZ,
    completed_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Relations
    assigned_to UUID REFERENCES auth.users(id),
    partner_id UUID REFERENCES auth.users(id),
    company_id BIGINT REFERENCES companies(id),
    created_by UUID REFERENCES auth.users(id),
    
    -- Informations supplémentaires
    notes TEXT,
    follow_up_date TIMESTAMPTZ,
    outcome TEXT
);
```

### **🔒 Sécurité RLS :**
- ✅ **Row Level Security activé**
- ✅ **Lecture** : Utilisateurs de la même entreprise
- ✅ **Création** : Admin/Associé uniquement
- ✅ **Modification** : Créateur ou Admin/Associé
- ✅ **Suppression** : Créateur ou Admin uniquement

### **⚡ Optimisations :**
- ✅ **Index** sur company_id, status, due_date, etc.
- ✅ **Vue** `commercial_actions_view` avec jointures
- ✅ **Fonction RPC** `get_commercial_actions_for_company()`

---

## 🚀 **FONCTIONNALITÉS IMPLÉMENTÉES**

### **✅ CRUD Complet :**
- **Créer** une nouvelle action commerciale
- **Lire** toutes les actions de l'entreprise
- **Modifier** une action existante (titre, description, statut, etc.)
- **Supprimer** une action

### **✅ Fonctionnalités avancées :**
- **Filtrage** par statut et priorité
- **Tri** par date d'échéance, priorité, nom du client
- **Statistiques** automatiques (en cours, terminées, urgentes)
- **Marquer comme terminée** en un clic
- **Gestion des valeurs estimées** et réelles

### **✅ Interface :**
- **Formulaires dynamiques** avec validation
- **Dialogues de confirmation** pour les suppressions
- **Messages de succès/erreur** appropriés
- **État de chargement** pendant les opérations

---

## 🛠️ **SERVICES SUPABASE AJOUTÉS**

### **📁 Dans `lib/services/supabase_service.dart` :**

```dart
// Nouvelles fonctions ajoutées :
- getCommercialActions()           // Récupérer toutes les actions
- createCommercialAction(...)      // Créer une action
- updateCommercialAction(...)      // Modifier une action  
- deleteCommercialAction(id)       // Supprimer une action
- completeCommercialAction(...)    // Marquer comme terminée
```

### **📁 Dans `lib/pages/partner/actions_page.dart` :**

```dart
// Fonctions corrigées :
- _loadActions()                   // Charge depuis Supabase (plus de mock)
- _showCreateActionDialog()        // Crée réellement dans Supabase
- _showEditActionDialog()          // Modifie réellement dans Supabase
- _deleteAction()                  // Supprime réellement de Supabase
- _markAsCompleted()               // Met à jour le statut dans Supabase
```

---

## 🎯 **RÉSULTAT ATTENDU**

### **Avant les corrections :**
- ❌ Données de mock/test uniquement
- ❌ Aucune persistance des actions créées
- ❌ Fonctionnalités factices

### **Après les corrections :**
- ✅ **Vraie base de données** Supabase
- ✅ **Persistance complète** des actions commerciales
- ✅ **CRUD fonctionnel** avec toutes les validations
- ✅ **Sécurité RLS** : chaque entreprise voit ses propres actions
- ✅ **Interface complète** avec formulaires avancés

---

## 🔧 **PROCHAINES ÉTAPES**

1. **Exécuter le script SQL** dans Supabase (étape obligatoire)
2. **Redémarrer l'application** Flutter
3. **Tester la création** d'une nouvelle action commerciale
4. **Vérifier dans Supabase** que les données sont bien sauvegardées

---

## 📞 **EN CAS DE PROBLÈME**

### **Erreur : "relation commercial_actions does not exist"**
➡️ **Solution** : Le script SQL n'a pas été exécuté. Suivre l'étape 1.

### **Erreur : "permission denied"**
➡️ **Solution** : Vérifier que l'utilisateur est bien connecté et appartient à une entreprise.

### **Actions non visibles**
➡️ **Solution** : Vérifier que l'utilisateur a le bon rôle (admin/associé pour créer).

**Les actions commerciales sont maintenant prêtes ! 🎉** 