// lib/widgets/side_menu.dart
// Sidebar OXO : sections groupées, état sélectionné par barre d'accent,
// carte utilisateur en bas (avec déconnexion).
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/supabase_service.dart';
import '../models/user_role.dart';

class SideMenu extends StatelessWidget {
  final UserRole? userRole;
  final String selectedRoute;

  const SideMenu({
    Key? key,
    required this.userRole,
    this.selectedRoute = '/projects',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isAssociate = userRole == UserRole.associe;
    final bool isAdmin = userRole == UserRole.admin;
    final bool isClient = userRole == UserRole.client;
    final bool isPartner = userRole == UserRole.partenaire;

    return Container(
      width: 250,
      color: AppTheme.colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          // Le menu défile si la fenêtre est trop petite (évite l'overflow)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: isClient
                  ? _buildClientMenu(context)
                  : _buildStandardMenu(
                      context, isAssociate, isAdmin, isPartner),
            ),
          ),
          _buildUserCard(context),
        ],
      ),
    );
  }

  // ── En-tête : marque OXO ──────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppTheme.colors.secondary,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: const Text(
              'OX',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'OXO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Menus par rôle ────────────────────────────────────────────────────────

  Widget _buildClientMenu(BuildContext context) {
    // Mêmes entrées et libellés que la sidebar des pages client
    // (client_dashboard_page / client_invoices_page) pour une navigation
    // cohérente quel que soit l'écran.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionLabel('Espace client'),
        _buildMenuButton(context, Icons.dashboard_outlined, 'Tableau de bord',
            '/client_dashboard'),
        _buildMenuButton(
            context, Icons.receipt_long_outlined, 'Factures', '/client/invoices'),
        _buildMenuButton(context, Icons.person_outline, 'Profil', '/profile'),
        _buildMenuButton(context, Icons.chat_bubble_outline, 'Messages', '/messaging'),
      ],
    );
  }

  Widget _buildStandardMenu(
      BuildContext context, bool isAssociate, bool isAdmin, bool isPartner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Pilotage ──
        _buildSectionLabel('Pilotage'),
        if (!isAssociate && !isPartner)
          _buildMenuButton(context, Icons.person_outline, 'Fiche Associé', '/associate'),
        _buildMenuButton(context, Icons.folder_outlined, 'Missions', '/missions'),
        if (!isAssociate && !isPartner)
          _buildMenuButton(context, Icons.calendar_month_outlined, 'Planning', '/planning'),

        // ── Activité ──
        _buildSectionLabel('Activité'),
        _buildMenuButton(context, Icons.schedule_outlined, 'Saisie du temps', '/timesheet/entry'),
        if (isAssociate) ...[
          _buildMenuButton(context, Icons.tune_outlined, 'Paramètres Timesheet', '/timesheet/settings'),
          _buildMenuButton(context, Icons.assessment_outlined, 'Reporting Timesheet', '/timesheet/reporting'),
        ],
        _buildMenuButton(context, Icons.event_available_outlined, 'Disponibilités', '/availability'),
        if (!isPartner)
          _buildMenuButton(context, Icons.business_center_outlined, 'Actions Commerciales', '/actions'),

        // ── Réseau ──
        _buildSectionLabel('Réseau'),
        if (!isPartner)
          _buildMenuButton(context, Icons.people_outline, 'Partenaires et Clients', '/partners-clients'),
        if (isAssociate || isAdmin)
          _buildMenuButton(context, Icons.request_page_outlined, 'Demandes Client', '/admin/client-requests'),
        _buildMenuButton(context, Icons.chat_outlined, 'Messages', '/messaging'),

        // ── Administration ──
        if (isAdmin) ...[
          _buildSectionLabel('Administration'),
          _buildMenuButton(context, Icons.admin_panel_settings_outlined, 'Gestion des rôles', '/admin/roles'),
        ],
      ],
    );
  }

  // ── Composants ────────────────────────────────────────────────────────────

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: Colors.white.withAlpha(102),
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, IconData icon, String label, String route) {
    final bool isSelected = selectedRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // pushReplacementNamed : changer de section ne doit pas empiler
            // les écrans (le retour arrière est réservé aux pages de détail).
            if (selectedRoute != route) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withAlpha(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withAlpha(31) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                // Barre d'accent : signale la section active
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.colors.sidebarAccent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  icon,
                  color: Colors.white.withAlpha(isSelected ? 255 : 191),
                  size: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withAlpha(isSelected ? 255 : 204),
                      fontSize: 13.5,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Carte utilisateur + déconnexion ──────────────────────────────────────

  String get _roleLabel {
    switch (userRole) {
      case UserRole.associe:
        return 'Associé';
      case UserRole.partenaire:
        return 'Partenaire';
      case UserRole.client:
        return 'Client';
      case UserRole.admin:
        return 'Administrateur';
      default:
        return '';
    }
  }

  String get _displayName {
    final user = SupabaseService.currentUser;
    if (user == null) return 'Utilisateur';
    final meta = user.userMetadata ?? {};
    final firstName = (meta['first_name'] ?? '').toString().trim();
    final lastName = (meta['last_name'] ?? '').toString().trim();
    if (firstName.isNotEmpty || lastName.isNotEmpty) {
      return '$firstName $lastName'.trim();
    }
    // Repli : partie locale de l'email
    return user.email?.split('@').first ?? 'Utilisateur';
  }

  String get _initials {
    final name = _displayName;
    final parts =
        name.split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Widget _buildUserCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 15,
              backgroundColor: AppTheme.colors.secondaryLight,
              child: Text(
                _initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _roleLabel,
                    style: TextStyle(
                      color: Colors.white.withAlpha(153),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _confirmLogout(context),
              icon: Icon(
                Icons.logout,
                color: Colors.white.withAlpha(191),
                size: 18,
              ),
              tooltip: 'Déconnexion',
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
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
      await SupabaseService.signOut();
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }
}
