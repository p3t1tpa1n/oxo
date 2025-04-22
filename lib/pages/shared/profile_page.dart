// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../models/user_role.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: const Color(0xFF1E3D54),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle, size: 80, color: Color(0xFF1E3D54)),
                const SizedBox(height: 16),
                Text(
                  user.email?.split('@').first ?? 'Utilisateur',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3D54),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? '',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Rôle: ${SupabaseService.currentUserRole?.toString().split('.').last ?? 'Non défini'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                if (SupabaseService.currentUserRole == UserRole.admin) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin/roles');
                    },
                    icon: const Icon(Icons.admin_panel_settings),
                    label: const Text('Gérer les rôles utilisateurs'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3D54),
                      side: const BorderSide(color: Color(0xFF1E3D54)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  onPressed: () async {
                    // Afficher une boîte de dialogue de confirmation
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirmation'),
                          content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Annuler'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Déconnexion',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                    
                    // Si l'utilisateur a confirmé, procéder à la déconnexion
                    if (confirm == true && context.mounted) {
                      try {
                        await SupabaseService.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur lors de la déconnexion: $e')),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3D54),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}