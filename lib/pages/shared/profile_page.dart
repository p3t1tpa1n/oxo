// lib/pages/profile_page.dart
// Pas d'AppBar : le chrome (titre, retour) est fourni par DesktopShell.
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../models/user_role.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  String _roleLabel(UserRole? role) {
    switch (role) {
      case UserRole.associe:
        return 'Associé';
      case UserRole.partenaire:
        return 'Partenaire';
      case UserRole.client:
        return 'Client';
      case UserRole.admin:
        return 'Administrateur';
      default:
        return 'Non défini';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;

    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return const SizedBox.shrink();
    }

    final meta = user.userMetadata ?? {};
    final firstName = (meta['first_name'] ?? '').toString().trim();
    final lastName = (meta['last_name'] ?? '').toString().trim();
    final displayName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : user.email?.split('@').first ?? 'Utilisateur';
    final initials = displayName.length >= 2
        ? displayName.substring(0, 2).toUpperCase()
        : displayName.toUpperCase();
    final role = SupabaseService.currentUserRole;

    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.colors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radius.large),
              border: Border.all(color: AppTheme.colors.border, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor:
                        AppTheme.colors.secondary.withOpacity(0.15),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: AppTheme.colors.secondary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayName,
                  style: AppTheme.typography.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? '',
                  style: AppTheme.typography.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.colors.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _roleLabel(role),
                      style: TextStyle(
                        color: AppTheme.colors.secondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Divider(color: AppTheme.colors.borderLight),
                const SizedBox(height: 16),
                if (role == UserRole.admin) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/admin/roles');
                    },
                    icon: const Icon(Icons.admin_panel_settings_outlined,
                        size: 18),
                    label: const Text('Gérer les rôles utilisateurs'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.colors.primary,
                      side: BorderSide(color: AppTheme.colors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context),
                  icon: Icon(Icons.logout,
                      size: 18, color: AppTheme.colors.error),
                  label: Text(
                    'Déconnexion',
                    style: TextStyle(color: AppTheme.colors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppTheme.colors.error.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
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
              child: Text(
                'Déconnexion',
                style: TextStyle(color: AppTheme.colors.error),
              ),
            ),
          ],
        );
      },
    );

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
  }
}
