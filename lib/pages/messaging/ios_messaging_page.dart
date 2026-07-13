import 'package:flutter/material.dart';
import 'dart:async';
import '../../config/app_theme.dart';
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

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeMessaging();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMessaging() async {
    try {
      setState(() {
        isInitializing = true;
        error = null;
      });
      await MessagingService().initialize();
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

  Future<List<Map<String, dynamic>>> _filterUsersForMessaging(List<Map<String, dynamic>> allUsers) async {
    final currentUserRole = await SupabaseService.getCurrentUserRole();
    if (currentUserRole == null) return allUsers;
    if (currentUserRole.value == 'associe' || currentUserRole.value == 'admin') {
      return allUsers;
    }
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

      final conversationId = await MessagingService().getOrCreateConversation(userId);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
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
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Impossible de créer la conversation: $e'),
            actions: [
              TextButton(
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
      return Scaffold(
        backgroundColor: AppTheme.colors.background,
        appBar: AppBar(title: const Text('Messagerie'), backgroundColor: AppTheme.colors.surface),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.colors.primary, strokeWidth: 2),
              const SizedBox(height: 16),
              Text('Initialisation de la messagerie...', style: AppTheme.typography.bodyMedium),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: AppTheme.colors.background,
        appBar: AppBar(title: const Text('Messagerie'), backgroundColor: AppTheme.colors.surface),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 64, color: AppTheme.colors.error),
              const SizedBox(height: 16),
              Text('Erreur', style: AppTheme.typography.h3),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(error!, style: AppTheme.typography.bodyMedium, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _initializeMessaging,
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colors.primary),
                child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      appBar: AppBar(
        title: const Text('Messagerie'),
        backgroundColor: AppTheme.colors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: Icon(Icons.search, color: AppTheme.colors.textSecondary),
                filled: true,
                fillColor: AppTheme.colors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: _filterUsers,
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
                          searchQuery.isEmpty ? Icons.people : Icons.search,
                          size: 64,
                          color: AppTheme.colors.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          searchQuery.isEmpty
                              ? 'Aucun utilisateur disponible'
                              : 'Aucun résultat pour "$searchQuery"',
                          style: AppTheme.typography.h4,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isEmpty
                              ? 'Les utilisateurs apparaîtront ici'
                              : 'Essayez un autre terme de recherche',
                          style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
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
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors.border, width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.colors.primary,
          radius: 20,
          child: Text(
            initials,
            style: AppTheme.typography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(displayName, style: AppTheme.typography.bodyMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (firstName.isNotEmpty && lastName.isNotEmpty)
              Text(email, style: AppTheme.typography.caption.copyWith(color: AppTheme.colors.textSecondary)),
            Text(
              _formatRole(role),
              style: AppTheme.typography.caption.copyWith(
                color: _getRoleColor(role),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chat_bubble_outline, color: AppTheme.colors.primary, size: 20),
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
      case 'admin': return AppTheme.colors.error;
      case 'associe': return AppTheme.colors.primary;
      case 'partenaire': return AppTheme.colors.warning;
      case 'client': return AppTheme.colors.success;
      default: return AppTheme.colors.textSecondary;
    }
  }
}
