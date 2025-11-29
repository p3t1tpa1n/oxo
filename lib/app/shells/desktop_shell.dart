// ============================================================================
// DESKTOP SHELL - OXO TIME SHEETS
// Shell pour macOS/Web desktop avec sidebar + topbar
// ============================================================================

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/app_icons.dart';
import '../../services/supabase_service.dart';
import '../../widgets/side_menu.dart';

class DesktopShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  
  const DesktopShell({
    Key? key,
    required this.child,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: Row(
        children: [
          // Sidebar gauche (réutilise le SideMenu existant)
          SideMenu(
            userRole: SupabaseService.currentUserRole,
            selectedRoute: widget.currentRoute,
          ),
          
          // Contenu principal
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.colors.border,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Titre de page
          Text(
            _getPageTitle(),
            style: AppTheme.typography.h3,
          ),
          
          // Actions rapides
          Row(
            children: [
              IconButton(
                icon: Icon(AppIcons.notifications),
                tooltip: 'Notifications',
                onPressed: () {
                  // TODO: Implémenter notifications
                },
              ),
              SizedBox(width: AppTheme.spacing.sm),
              IconButton(
                icon: Icon(AppIcons.settings),
                tooltip: 'Paramètres',
                onPressed: () {
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    // Logique pour déterminer le titre de la page selon la route
    if (widget.currentRoute.contains('/dashboard')) return 'Dashboard';
    if (widget.currentRoute.contains('/missions')) return 'Missions';
    if (widget.currentRoute.contains('/timesheet')) return 'Timesheet';
    if (widget.currentRoute.contains('/partners')) return 'Partenaires';
    if (widget.currentRoute.contains('/actions')) return 'Actions commerciales';
    if (widget.currentRoute.contains('/messaging')) return 'Messages';
    if (widget.currentRoute.contains('/profile')) return 'Profil';
    if (widget.currentRoute.contains('/availability')) return 'Disponibilités';
    if (widget.currentRoute.contains('/admin')) return 'Administration';
    return 'OXO Time Sheets';
  }
}

