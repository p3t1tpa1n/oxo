# 🔒 Restrictions de Messagerie par Rôle

## 📋 Vue d'ensemble

Les restrictions de messagerie ont été implémentées pour contrôler qui peut communiquer avec qui selon les rôles utilisateur.

## ⚖️ Règles de Messagerie

### ✅ **Associés et Admins**
- **Peuvent parler à tout le monde** : clients, partenaires, autres associés, admins
- **Accès complet** à toutes les fonctionnalités de messagerie
- **Rôle de modérateur** dans les communications

### 🔒 **Clients et Partenaires**  
- **Peuvent parler seulement aux associés et admins**
- **Ne peuvent PAS** communiquer directement entre eux
- **Doivent passer par les associés** pour toute communication inter-rôle

## 🛠️ Implémentation

### 1. **Interface Utilisateur**
Les pages de messagerie filtrent automatiquement la liste des utilisateurs :
- `messaging_page.dart` (version web)
- `ios_messaging_page.dart` (version iOS)

**Fonction de filtrage :**
```dart
Future<List<Map<String, dynamic>>> _filterUsersForMessaging(
  List<Map<String, dynamic>> allUsers
) async {
  final currentUserRole = await SupabaseService.getCurrentUserRole();
  
  // Associés et admins voient tout le monde
  if (currentUserRole.name == 'associe' || currentUserRole.name == 'admin') {
    return allUsers;
  }
  
  // Clients et partenaires voient seulement les associés/admins
  return allUsers.where((user) {
    final userRole = user['user_role']?.toString().toLowerCase();
    return userRole == 'associe' || userRole == 'admin';
  }).toList();
}
```

### 2. **Base de Données (RLS)**
Politiques Row Level Security mises à jour dans Supabase :

**Fonctions helper créées :**
- `can_message_user(sender_id, recipient_id)` - Vérifie si un utilisateur peut envoyer un message
- `can_participate_in_conversation(user_id, conversation_id)` - Vérifie l'accès aux conversations

**Politiques RLS :**
- `Restricted conversation access` - Limite l'accès aux conversations
- `Restricted message sending` - Contrôle l'envoi de messages
- `Restricted participant addition` - Gère l'ajout de participants

## 🚀 Installation

### 1. **Exécuter le script SQL**
```bash
1. Aller sur https://app.supabase.com
2. Ouvrir SQL Editor
3. Copier/coller le contenu de : supabase/messaging_role_restrictions.sql
4. Cliquer "Run"
```

### 2. **Vérification**
Après exécution, vérifiez que :
- ✅ Les nouvelles politiques RLS sont actives
- ✅ Les fonctions helper sont créées
- ✅ La fonction `create_conversation` est mise à jour

## 🧪 Tests

### **Test 1 : Client vers Associé** ✅
```
1. Se connecter en tant que client (client@gmail.com)
2. Aller dans Messagerie
3. Vérifier que seuls les associés/admins sont visibles
4. Créer une conversation avec un associé
```

### **Test 2 : Client vers Partenaire** ❌
```
1. Se connecter en tant que client
2. Aller dans Messagerie
3. Vérifier que les partenaires ne sont PAS visibles
```

### **Test 3 : Associé vers Tout le monde** ✅
```
1. Se connecter en tant qu'associé (asso@gmail.com)
2. Aller dans Messagerie
3. Vérifier que tous les utilisateurs sont visibles
4. Créer des conversations avec différents rôles
```

### **Test 4 : Partenaire vers Associé** ✅
```
1. Se connecter en tant que partenaire (part@gmail.com)
2. Aller dans Messagerie
3. Vérifier que seuls les associés/admins sont visibles
4. Créer une conversation avec un associé
```

## 📊 Matrice de Permissions

| De ↓ Vers → | Client | Partenaire | Associé | Admin |
|-------------|---------|------------|---------|-------|
| **Client** | ❌ | ❌ | ✅ | ✅ |
| **Partenaire** | ❌ | ❌ | ✅ | ✅ |
| **Associé** | ✅ | ✅ | ✅ | ✅ |
| **Admin** | ✅ | ✅ | ✅ | ✅ |

## 🔧 Workflow Type

### **Scénario 1 : Client a une question**
1. Client se connecte à la messagerie
2. Voit seulement les associés/admins disponibles
3. Envoie un message à un associé
4. L'associé peut répondre et/ou rediriger vers un partenaire si nécessaire

### **Scénario 2 : Partenaire a besoin d'informations**
1. Partenaire se connecte à la messagerie
2. Voit seulement les associés/admins disponibles
3. Contacte un associé pour obtenir les informations client
4. L'associé fait le lien entre partenaire et client si nécessaire

### **Scénario 3 : Associé gère les communications**
1. Associé a accès à tous les utilisateurs
2. Peut créer des conversations avec n'importe qui
3. Fait office d'intermédiaire entre clients et partenaires
4. Gère les demandes et coordonne les équipes

## ⚠️ Notes Importantes

### **Sécurité**
- Les restrictions sont appliquées à **deux niveaux** : interface ET base de données
- Impossible de contourner les restrictions via l'API directe
- Les conversations existantes restent accessibles (pas de suppression rétroactive)

### **Compatibilité**
- Les conversations existantes continuent de fonctionner
- Pas d'impact sur les messages déjà envoyés
- Migration transparente pour les utilisateurs

### **Performance**
- Filtrage côté client pour une meilleure UX
- Politiques RLS optimisées avec des index appropriés
- Fonctions helper en cache pour de meilleures performances

## 🔄 Rollback (si nécessaire)

Pour revenir à l'ancien système sans restrictions :

```sql
-- Supprimer les nouvelles politiques
DROP POLICY IF EXISTS "Restricted conversation access" ON public.conversations;
DROP POLICY IF EXISTS "Restricted message sending" ON public.messages;
-- ... (supprimer toutes les politiques restrictives)

-- Remettre les anciennes politiques ouvertes
-- (voir le fichier simple_messaging_setup.sql)
```

## 📞 Support

En cas de problème :
1. Vérifier que le script SQL a été exécuté complètement
2. Tester avec différents rôles d'utilisateur
3. Consulter les logs Supabase pour les erreurs RLS
4. Vérifier que la table `profiles` contient les bons rôles

**Les restrictions de messagerie sont maintenant actives ! 🔒**

