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
      color: Colors.white,
      child: Column(
        children: [
          Material(
            color: const Color(0xFF1784af),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Menu',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF122b35),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (userRole == UserRole.associe) ...[
                    _buildMenuButton(context, Icons.person, 'Fiche Associé', '/associate'),
                    _buildMenuButton(context, Icons.calendar_today, 'Planning Global', '/planning'),
                    _buildMenuButton(context, Icons.handshake, 'Partenaires', '/partners'),
                    _buildMenuButton(context, Icons.message, 'Messagerie', '/messaging'),
                    _buildMenuButton(context, Icons.business, 'Actions Commerciales', '/actions'),
                    _buildMenuButton(context, Icons.bar_chart, 'Chiffres Entreprise', '/figures'),
                  ] else if (userRole == UserRole.partenaire) ...[
                    _buildMenuButton(context, Icons.calendar_today, 'Planning', '/planning'),
                    _buildMenuButton(context, Icons.message, 'Messagerie', '/messaging'),
                    _buildMenuButton(context, Icons.business, 'Mes Projets', '/partners'),
                  ],
                ],
              ),
            ),
          ),
          if (userRole != null) // N'affiche le chat que si l'utilisateur est connecté
            Expanded(
              child: Material(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messages',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF122b35),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Expanded(
                        child: ChatWidget(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, IconData icon, String label, String route) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, route),
          child: SizedBox(
            height: 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: const Color(0xFF122b35)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF122b35),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}