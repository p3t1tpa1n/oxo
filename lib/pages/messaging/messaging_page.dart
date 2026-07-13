import 'package:flutter/material.dart';
import 'dart:async';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/messaging_service.dart';
import 'conversation_detail_page.dart';

class MessagingPage extends StatefulWidget {
  const MessagingPage({super.key});

  @override
  State<MessagingPage> createState() => _MessagingPageState();
}

class _MessagingPageState extends State<MessagingPage> {
  String? selectedUserId;
  String? selectedUserName;
  String? conversationId;
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = false;
  bool isInitializing = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _initializeMessaging();
  }

  Future<void> _initializeMessaging() async {
    try {
      setState(() {
        isInitializing = true;
        error = null;
      });
      
      // Initialiser le service de messagerie
      await MessagingService().initialize();
      
      // Charger les utilisateurs
      await _loadUsers();
      
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de la messagerie: $e');
      setState(() {
        error = 'Erreur lors de l\'initialisation: $e';
      });
    } finally {
      setState(() {
        isInitializing = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    try {
      final usersList = await SupabaseService.getAllUsers();
      debugPrint('Utilisateurs chargés: ${usersList.length}');
      debugPrint('Premier utilisateur: ${usersList.isNotEmpty ? usersList.first : 'Aucun'}');
      
      // Filtrer les utilisateurs selon les restrictions de messagerie
      final filteredUsersList = await _filterUsersForMessaging(usersList);
      
      setState(() {
        users = filteredUsersList;
        filteredUsers = filteredUsersList;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des utilisateurs: $e');
      setState(() {
        error = 'Erreur lors du chargement des utilisateurs: $e';
      });
    }
  }

  Future<void> _selectUser(String userId, String userName) async {
    setState(() {
      isLoading = true;
      selectedUserId = userId;
      selectedUserName = userName;
      conversationId = null;
      error = null;
    });
    
    try {
      debugPrint('Sélection de l\'utilisateur: $userId ($userName)');
      // Essaie de trouver une conversation existante ou en crée une si besoin
      final newConversationId = await MessagingService().getOrCreateConversation(userId);
      debugPrint('Conversation ID: $newConversationId');
      
      setState(() {
        conversationId = newConversationId;
      });
    } catch (e) {
      debugPrint('Erreur lors de la sélection de l\'utilisateur: $e');
      setState(() {
        error = 'Erreur lors de la création de la conversation: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Filtre les utilisateurs selon les restrictions de messagerie :
  /// - Associés : peuvent parler à tout le monde
  /// - Clients/Partenaires : peuvent parler seulement aux associés
  Future<List<Map<String, dynamic>>> _filterUsersForMessaging(List<Map<String, dynamic>> allUsers) async {
    final currentUserRole = await SupabaseService.getCurrentUserRole();
    
    if (currentUserRole == null) {
      return allUsers; // Par défaut, retourner tous les utilisateurs
    }
    
    // Les associés et admins peuvent parler à tout le monde
    if (currentUserRole.value == 'associe' || currentUserRole.value == 'admin') {
      return allUsers;
    }
    
    // Les clients et partenaires ne peuvent parler qu'aux associés et admins
    return allUsers.where((user) {
      final userRole = user['user_role']?.toString().toLowerCase();
      return userRole == 'associe' || userRole == 'admin';
    }).toList();
  }

  void _filterUsers(String query) {
    setState(() {
      filteredUsers = users
          .where((u) => 
              (u['email']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (u['first_name']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (u['last_name']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  String _roleLabel(String? role) {
    switch (role?.toLowerCase()) {
      case 'associe':
      case 'associé':
        return 'Associé';
      case 'partenaire':
        return 'Partenaire';
      case 'client':
        return 'Client';
      case 'admin':
        return 'Administrateur';
      default:
        return role ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le titre et le chrome sont fournis par DesktopShell : pas d'AppBar ici.
    if (isInitializing) {
      return Scaffold(
        backgroundColor: AppTheme.colors.background,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initialisation de la messagerie...'),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: AppTheme.colors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 48, color: AppTheme.colors.error),
              const SizedBox(height: 16),
              Text(error!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeMessaging,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: Row(
        children: [
          // Colonne de gauche : liste des utilisateurs
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: AppTheme.colors.surface,
              border: Border(
                right: BorderSide(color: AppTheme.colors.border, width: 0.5),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Rechercher...',
                            prefixIcon: Icon(Icons.search,
                                size: 20,
                                color: AppTheme.colors.textSecondary),
                            isDense: true,
                          ),
                          onChanged: _filterUsers,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.refresh,
                            size: 20, color: AppTheme.colors.textSecondary),
                        tooltip: 'Actualiser',
                        onPressed: _loadUsers,
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.colors.borderLight),
                Expanded(
                  child: ListView(
                    children: filteredUsers
                        .where((u) => u['user_id'] != SupabaseService.currentUser?.id)
                        .map((user) {
                      final bool isSelected =
                          selectedUserId == user['user_id'];
                      final String displayName = user['first_name'] != null &&
                              user['last_name'] != null
                          ? '${user['first_name']} ${user['last_name']}'
                          : user['email'] ?? 'Utilisateur sans nom';
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: isSelected
                              ? AppTheme.colors.primary
                              : AppTheme.colors.secondary.withOpacity(0.15),
                          child: Text(
                            (user['first_name']?.toString().isNotEmpty == true
                                    ? user['first_name'][0]
                                    : user['email']?[0] ?? '?')
                                .toUpperCase(),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.colors.secondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: AppTheme.colors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          _roleLabel(user['user_role']?.toString()),
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.colors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => _selectUser(user['user_id'], displayName),
                        selected: isSelected,
                        selectedTileColor:
                            AppTheme.colors.secondary.withOpacity(0.08),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Colonne de droite : messages ou message d'absence
          Expanded(
            child: isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Chargement de la conversation...'),
                      ],
                    ),
                  )
                : (selectedUserId == null)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 56, color: AppTheme.colors.textDisabled),
                            const SizedBox(height: 16),
                            Text(
                              'Sélectionnez un utilisateur pour commencer une conversation',
                              style: TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.colors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : (conversationId == null)
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline,
                                    size: 48, color: AppTheme.colors.warning),
                                const SizedBox(height: 16),
                                Text(
                                  'Impossible de créer une conversation avec $selectedUserName',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: AppTheme.colors.textSecondary),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                if (error?.contains('tables de messagerie') == true) ...[
                                  Text(
                                    'Les tables de messagerie n\'existent pas dans la base de données.',
                                    style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.colors.error),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Veuillez exécuter le script SQL fix_conversations_table.sql dans l\'interface web de Supabase.',
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _selectUser(selectedUserId!, selectedUserName!),
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          )
                        : ConversationDetailPage(
                            conversationId: conversationId!,
                            conversationName: selectedUserName ?? '',
                            isGroup: false,
                          ),
          ),
        ],
      ),
    );
  }
} 