import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/user_role.dart';
import 'add_user_page.dart';

class UserRolesPage extends StatefulWidget {
  const UserRolesPage({super.key});

  @override
  State<UserRolesPage> createState() => _UserRolesPageState();
}

class _UserRolesPageState extends State<UserRolesPage> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final users = await SupabaseService.getAllUsers();
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des utilisateurs: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des utilisateurs'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddUserPage(),
                ),
              ).then((_) => _loadUsers());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text('${user['first_name']} ${user['last_name']}'),
                    subtitle: Text(user['email']),
                    trailing: Text(
                      user['user_role'].toString().toUpperCase(),
                      style: TextStyle(
                        color: _getRoleColor(user['user_role'].toString()),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'associe':
        return Colors.blue;
      case 'partenaire':
        return Colors.green;
      case 'client':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
} 