// lib/widgets/side_menu.dart
import 'package:flutter/material.dart';
import '../widgets/chat_widget.dart';
import '../services/supabase_service.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final userRole = SupabaseService.currentUserRole;

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
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            context,
            Icons.dashboard,
            'Dashboard',
            '/',
            isSelected: true,
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            context,
            Icons.calendar_month,
            'Planning',
            '/planning',
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            context,
            Icons.access_time,
            'Timesheet',
            '/timesheet',
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            context,
            Icons.group,
            'Partenaires',
            '/partners',
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            context,
            Icons.business_center,
            'Actions Commerciales',
            '/actions',
          ),
          const SizedBox(height: 12),
          _buildMenuButton(
            context,
            Icons.insert_chart,
            'Chiffres Entreprise',
            '/figures',
          ),
          const Spacer(),
        ],
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
          hoverColor: Colors.white.withOpacity(0.15),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.white.withOpacity(0.3) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white.withOpacity(isSelected ? 1 : 0.85),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(isSelected ? 1 : 0.85),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
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