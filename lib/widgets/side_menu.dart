// lib/widgets/side_menu.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user_role.dart';

class SideMenu extends StatelessWidget {
  final String selectedRoute;
  
  const SideMenu({
    super.key,
    this.selectedRoute = '/',
  });

  @override
  Widget build(BuildContext context) {
    final userRole = SupabaseService.currentUserRole;
    final bool isAssociate = userRole == UserRole.associe;

    return Container(
      width: 250,
      color: const Color(0xFF2A4B63),
      child: Column(
        children: [
          const SizedBox(height: 16),
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
            Icons.insert_chart,
            'Chiffres Entreprise',
            '/figures',
            isSelected: selectedRoute == '/figures',
          ),
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
          await SupabaseService.signOut();
          if (context.mounted) {
            Navigator.pushReplacementNamed(context, '/login');
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

  Widget _buildMenuButton(BuildContext context, IconData icon, String label, String route, {bool isSelected = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
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