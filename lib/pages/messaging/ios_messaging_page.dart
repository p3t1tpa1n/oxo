import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';
import '../../services/messaging_service.dart';
import 'ios_conversation_detail_page.dart';

class IOSMessagingPage extends StatefulWidget {
  const IOSMessagingPage({super.key});

  @override
  State<IOSMessagingPage> createState() => _IOSMessagingPageState();
}

class _IOSMessagingPageState extends State<IOSMessagingPage> {
  List<Map<String, dynamic>> users = [];
  List<Map<String, dynamic>> filteredUsers = [];
  bool isLoading = false;
  bool isInitializing = true;
  String? error;
  String searchQuery = '';

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
      searchQuery = query;
      filteredUsers = users
          .where((u) => 
              (u['email']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (u['first_name']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (u['last_name']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    });
  }

  Future<void> _startConversation(Map<String, dynamic> user) async {
    try {
      final userId = user['user_id'];
      final userName = user['first_name'] != null && user['last_name'] != null
          ? '${user['first_name']} ${user['last_name']}'
          : user['email'] ?? 'Utilisateur';

      // Créer ou récupérer la conversation
      final conversationId = await MessagingService().getOrCreateConversation(userId);
      
      if (mounted) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            builder: (context) => IOSConversationDetailPage(
              conversationId: conversationId,
              conversationName: userName,
              isGroup: false,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erreur'),
            content: Text('Impossible de créer la conversation: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isInitializing) {
      return IOSScaffold(
        navigationBar: const IOSNavigationBar(title: "Messagerie"),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(),
              SizedBox(height: 16),
              Text(
                'Initialisation de la messagerie...',
                style: IOSTheme.body,
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return IOSScaffold(
        navigationBar: const IOSNavigationBar(title: "Messagerie"),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                CupertinoIcons.exclamationmark_triangle,
                size: 64,
                color: IOSTheme.systemRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur',
                style: IOSTheme.title2,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  error!,
                  style: IOSTheme.body,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _initializeMessaging,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Messagerie",
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _loadUsers,
            child: const Icon(
              CupertinoIcons.refresh,
              color: IOSTheme.primaryBlue,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            child: CupertinoSearchTextField(
              placeholder: 'Rechercher un utilisateur...',
              onChanged: _filterUsers,
              style: IOSTheme.body,
            ),
          ),
          
          // Liste des utilisateurs
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          searchQuery.isEmpty 
                              ? CupertinoIcons.person_2
                              : CupertinoIcons.search,
                          size: 64,
                          color: IOSTheme.systemGray3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty 
                              ? 'Aucun utilisateur disponible'
                              : 'Aucun résultat pour "$searchQuery"',
                          style: IOSTheme.headline,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isEmpty
                              ? 'Les utilisateurs apparaîtront ici'
                              : 'Essayez un autre terme de recherche',
                          style: IOSTheme.footnote,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      
                      // Ne pas afficher l'utilisateur connecté
                      if (user['user_id'] == SupabaseService.currentUser?.id) {
                        return const SizedBox.shrink();
                      }
                      
                      return _buildUserTile(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user) {
    final firstName = user['first_name']?.toString() ?? '';
    final lastName = user['last_name']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final role = user['user_role']?.toString() ?? '';
    
    final displayName = firstName.isNotEmpty && lastName.isNotEmpty
        ? '$firstName $lastName'
        : email;
    
    final initials = firstName.isNotEmpty 
        ? firstName[0].toUpperCase()
        : email.isNotEmpty 
            ? email[0].toUpperCase()
            : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IOSTheme.systemGray5, width: 1),
      ),
      child: IOSListTile(
        leading: CircleAvatar(
          backgroundColor: IOSTheme.primaryBlue,
          radius: 20,
          child: Text(
            initials,
            style: IOSTheme.headline.copyWith(color: Colors.white),
          ),
        ),
        title: Text(
          displayName,
          style: IOSTheme.body,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (firstName.isNotEmpty && lastName.isNotEmpty)
              Text(
                email,
                style: IOSTheme.footnote,
              ),
            Text(
              _formatRole(role),
              style: IOSTheme.caption1.copyWith(
                color: _getRoleColor(role),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: const Icon(
          CupertinoIcons.chat_bubble,
          color: IOSTheme.primaryBlue,
          size: 20,
        ),
        onTap: () => _startConversation(user),
      ),
    );
  }

  String _formatRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return 'Administrateur';
      case 'associe': return 'Associé';
      case 'partenaire': return 'Partenaire';
      case 'client': return 'Client';
      default: return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return IOSTheme.systemRed;
      case 'associe': return IOSTheme.primaryBlue;
      case 'partenaire': return IOSTheme.systemOrange;
      case 'client': return IOSTheme.systemGreen;
      default: return IOSTheme.systemGray;
    }
  }
} 