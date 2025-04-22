// lib/widgets/side_menu.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user_role.dart';

class SideMenu extends StatelessWidget {
  final UserRole? userRole;
  final String selectedRoute;
  
  const SideMenu({
    Key? key,
    required this.userRole,
    this.selectedRoute = '/dashboard',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isAssociate = userRole == UserRole.associe;
    final bool isAdmin = userRole == UserRole.admin;
    final bool isClient = userRole == UserRole.client;

    return Container(
      width: 250,
      color: const Color(0xFF2A4B63),
      child: Column(
        children: [
          const SizedBox(height: 16),
          if (isClient)
            _buildClientMenu(context)
          else
            _buildStandardMenu(context, isAssociate, isAdmin),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildLogoutButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
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
            await SupabaseService.signOut();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        hoverColor: Colors.white.withAlpha(38),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withAlpha(51),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.white.withAlpha(217),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Déconnexion',
                style: TextStyle(
                  color: Colors.white.withAlpha(217),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientMenu(BuildContext context) {
    return Column(
      children: [
        _buildMenuButton(
          context,
          Icons.dashboard,
          'Tableau de bord',
          '/client',
          isSelected: selectedRoute == '/client',
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          Icons.business_center,
          'Projets',
          '/client/projects',
          isSelected: selectedRoute == '/client/projects',
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          Icons.task_alt,
          'Tâches',
          '/client/tasks',
          isSelected: selectedRoute == '/client/tasks',
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          Icons.receipt_long,
          'Factures',
          '/client/invoices',
          isSelected: selectedRoute == '/client/invoices',
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          Icons.person,
          'Profil',
          '/profile',
          isSelected: selectedRoute == '/profile',
        ),
      ],
    );
  }

  Widget _buildStandardMenu(BuildContext context, bool isAssociate, bool isAdmin) {
    return Column(
      children: [
        _buildMenuButton(
          context,
          Icons.person,
          'Fiche Associé',
          '/associate',
          isSelected: selectedRoute == '/associate',
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          Icons.dashboard,
          'Dashboard',
          isAssociate ? '/' : '/dashboard',
          isSelected: (isAssociate && selectedRoute == '/') || 
                      (!isAssociate && selectedRoute == '/dashboard'),
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          Icons.calendar_month,
          'Planning',
          '/planning',
          isSelected: selectedRoute == '/planning',
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          Icons.access_time,
          'Timesheet',
          '/timesheet',
          isSelected: selectedRoute == '/timesheet',
        ),
        if (!isAssociate) ...[
          const SizedBox(height: 12),
          _buildMenuButton(
            context,
            Icons.group,
            'Partenaires',
            '/partners',
            isSelected: selectedRoute == '/partners',
          ),
        ],
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          Icons.business_center,
          'Actions Commerciales',
          '/actions',
          isSelected: selectedRoute == '/actions',
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          Icons.people,
          'Clients',
          '/clients',
          isSelected: selectedRoute == '/clients',
        ),
        const SizedBox(height: 12),
        _buildMenuButton(
          context,
          Icons.insert_chart,
          'Chiffres Entreprise',
          '/figures',
          isSelected: selectedRoute == '/figures',
        ),
        if (isAdmin) ...[
          const SizedBox(height: 12),
          _buildMenuButton(
            context,
            Icons.admin_panel_settings,
            'Gestion des rôles',
            '/admin/roles',
            isSelected: selectedRoute == '/admin/roles',
          ),
        ],
      ],
    );
  }

  Widget _buildMenuButton(BuildContext context, IconData icon, String label, String route, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Éviter la navigation si nous sommes déjà sur la page
            if (selectedRoute != route) {
              Navigator.pushNamed(context, route);
            }
          },
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withAlpha(38),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withAlpha(51) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.white.withAlpha(77) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white.withAlpha(isSelected ? 255 : 217),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withAlpha(isSelected ? 255 : 217),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}