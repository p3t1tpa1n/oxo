// ============================================================================
// MOBILE SHELL PROFESSIONAL - OXO TIME SHEETS
// Shell professionnel avec navigation stack par tab
// Adapte les onglets selon le rôle de l'utilisateur
// Utilise STRICTEMENT AppTheme
// ============================================================================

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/app_icons.dart';
import '../../services/supabase_service.dart';
import '../../models/user_role.dart';

// Import des tabs communs
import '../../features/timesheet/presentation/mobile_timesheet_tab.dart';
import '../../features/missions/presentation/mobile_missions_tab.dart';
import '../../features/reporting/presentation/mobile_reporting_tab.dart';
import '../../features/clients/presentation/mobile_clients_tab.dart';
import '../../features/messaging/presentation/mobile_messaging_tab.dart';
import '../../features/profile/presentation/mobile_profile_tab.dart';
import '../../features/dashboard/presentation/mobile_dashboard_tab.dart';

// Import des tabs spécifiques par rôle
import '../../features/partner/presentation/mobile_partner_availability_tab.dart';
import '../../features/client/presentation/mobile_client_projects_tab.dart';
import '../../features/client/presentation/mobile_client_invoices_tab.dart';
import '../../features/client/presentation/mobile_client_requests_tab.dart';
import '../../features/admin/presentation/mobile_admin_tab.dart';

class MobileShellProfessional extends StatefulWidget {
  /// Onglet initial demandé, par clé sémantique :
  /// 'timesheet', 'missions', 'reporting', 'clients', 'messages', 'profile',
  /// 'availability', 'dashboard', 'admin', 'projects', 'invoices', 'requests'.
  /// Si la clé n'existe pas pour le rôle courant, l'onglet 0 est utilisé.
  final String? initialTab;

  const MobileShellProfessional({Key? key, this.initialTab}) : super(key: key);

  @override
  State<MobileShellProfessional> createState() => _MobileShellProfessionalState();
}

class _MobileShellProfessionalState extends State<MobileShellProfessional> {
  int _currentIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [];
  UserRole? _userRole;
  bool _isLoading = true;
  bool _roleLoadError = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    setState(() {
      _isLoading = true;
      _roleLoadError = false;
    });

    try {
      // D'abord essayer de récupérer le rôle depuis le cache
      _userRole = SupabaseService.currentUserRole;

      // Si pas de rôle en cache, le charger depuis Supabase
      _userRole ??= await SupabaseService.getCurrentUserRole();

      debugPrint('📱 MobileShellProfessional: Rôle utilisateur = $_userRole');

      if (_userRole == null) {
        // Rôle introuvable : ne pas deviner une interface, afficher l'erreur.
        throw Exception('Rôle utilisateur introuvable');
      }

      // Initialiser les clés de navigation
      final tabCount = _getTabCount();
      _navigatorKeys.clear();
      for (int i = 0; i < tabCount; i++) {
        _navigatorKeys.add(GlobalKey<NavigatorState>());
      }

      // Onglet initial demandé via la route
      _currentIndex = _tabIndexFor(widget.initialTab);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement rôle: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _roleLoadError = true;
        });
      }
    }
  }

  /// Traduit une clé sémantique d'onglet en index selon le rôle courant.
  int _tabIndexFor(String? key) {
    if (key == null) return 0;
    final Map<String, int> mapping;
    switch (_userRole) {
      case UserRole.partenaire:
        mapping = {'timesheet': 0, 'missions': 1, 'availability': 2,
                   'messages': 3, 'profile': 4};
        break;
      case UserRole.client:
        mapping = {'projects': 0, 'missions': 0, 'invoices': 1, 'requests': 2,
                   'messages': 3, 'profile': 4};
        break;
      case UserRole.admin:
        mapping = {'dashboard': 0, 'missions': 1, 'admin': 2, 'clients': 2,
                   'requests': 2, 'messages': 3, 'profile': 4};
        break;
      case UserRole.associe:
      default:
        mapping = {'timesheet': 0, 'missions': 1, 'reporting': 2,
                   'clients': 3, 'messages': 4};
        break;
    }
    return mapping[key] ?? 0;
  }

  int _getTabCount() {
    switch (_userRole) {
      case UserRole.partenaire:
        return 5; // Timesheet, Missions, Disponibilités, Messages, Profil
      case UserRole.client:
        return 5; // Projets, Factures, Demandes, Messages, Profil
      case UserRole.admin:
        return 5; // Dashboard, Missions, Gestion, Messages, Profil
      case UserRole.associe:
      default:
        return 5; // Timesheet, Mission, Reporting, Clients, Messages (actuel)
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.colors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.colors.primary, strokeWidth: 2),
              SizedBox(height: AppTheme.spacing.md),
              Text('Chargement...', style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary)),
            ],
          ),
        ),
      );
    }

    if (_roleLoadError) {
      return Scaffold(
        backgroundColor: AppTheme.colors.background,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 56, color: AppTheme.colors.textSecondary),
                SizedBox(height: AppTheme.spacing.md),
                Text('Impossible de charger votre profil.', textAlign: TextAlign.center, style: AppTheme.typography.bodyLarge),
                SizedBox(height: AppTheme.spacing.sm),
                Text('Vérifiez votre connexion internet puis réessayez.', textAlign: TextAlign.center, style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary)),
                SizedBox(height: AppTheme.spacing.lg),
                ElevatedButton(
                  onPressed: _loadUserRole,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.colors.primary),
                  child: const Text('Réessayer'),
                ),
                TextButton(
                  onPressed: () async {
                    await SupabaseService.signOut();
                    if (context.mounted) {
                      Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil('/login', (route) => false);
                    }
                  },
                  child: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(
          _getTabCount(),
          (index) => Navigator(
            key: _navigatorKeys[index],
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => _buildTabContent(index),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: AppTheme.colors.surface,
        selectedItemColor: AppTheme.colors.primary,
        unselectedItemColor: AppTheme.colors.textSecondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: _getTabItems(),
        onTap: (index) {
          if (_currentIndex == index) {
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
          }
          setState(() => _currentIndex = index);
        },
      ),
    );
  }

  List<BottomNavigationBarItem> _getTabItems() {
    switch (_userRole) {
      case UserRole.partenaire:
        return _getPartnerTabItems();
      case UserRole.client:
        return _getClientTabItems();
      case UserRole.admin:
        return _getAdminTabItems();
      case UserRole.associe:
      default:
        return _getAssociateTabItems();
    }
  }

  // ============================================================================
  // ONGLETS PARTENAIRE
  // ============================================================================
  List<BottomNavigationBarItem> _getPartnerTabItems() {
    return [
      BottomNavigationBarItem(
        icon: Icon(AppIcons.timesheet),
        activeIcon: Icon(AppIcons.timesheet),
        label: 'Timesheet',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.missions),
        activeIcon: Icon(AppIcons.missions),
        label: 'Missions',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.planning),
        activeIcon: Icon(AppIcons.planning),
        label: 'Dispo',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.messaging),
        activeIcon: Icon(AppIcons.messaging),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.profile),
        activeIcon: Icon(AppIcons.profile),
        label: 'Profil',
      ),
    ];
  }

  // ============================================================================
  // ONGLETS CLIENT
  // ============================================================================
  List<BottomNavigationBarItem> _getClientTabItems() {
    return [
      BottomNavigationBarItem(
        icon: Icon(AppIcons.missions),
        activeIcon: Icon(AppIcons.missions),
        label: 'Projets',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.reporting),
        activeIcon: Icon(AppIcons.reporting),
        label: 'Factures',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.actions),
        activeIcon: Icon(AppIcons.actions),
        label: 'Demandes',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.messaging),
        activeIcon: Icon(AppIcons.messaging),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.profile),
        activeIcon: Icon(AppIcons.profile),
        label: 'Profil',
      ),
    ];
  }

  // ============================================================================
  // ONGLETS ADMIN
  // ============================================================================
  List<BottomNavigationBarItem> _getAdminTabItems() {
    return [
      BottomNavigationBarItem(
        icon: Icon(AppIcons.home),
        activeIcon: Icon(AppIcons.home),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.missions),
        activeIcon: Icon(AppIcons.missions),
        label: 'Missions',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.admin),
        activeIcon: Icon(AppIcons.admin),
        label: 'Admin',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.messaging),
        activeIcon: Icon(AppIcons.messaging),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.profile),
        activeIcon: Icon(AppIcons.profile),
        label: 'Profil',
      ),
    ];
  }

  // ============================================================================
  // ONGLETS ASSOCIÉ (NE PAS MODIFIER)
  // ============================================================================
  List<BottomNavigationBarItem> _getAssociateTabItems() {
    return [
      BottomNavigationBarItem(
        icon: Icon(AppIcons.timesheet),
        activeIcon: Icon(AppIcons.timesheet),
        label: 'Timesheet',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.missions),
        activeIcon: Icon(AppIcons.missions),
        label: 'Mission',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.reporting),
        activeIcon: Icon(AppIcons.reporting),
        label: 'Reporting',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.partners),
        activeIcon: Icon(AppIcons.partners),
        label: 'Clients',
      ),
      BottomNavigationBarItem(
        icon: Icon(AppIcons.messaging),
        activeIcon: Icon(AppIcons.messaging),
        label: 'Messages',
      ),
    ];
  }

  Widget _buildTabContent(int index) {
    switch (_userRole) {
      case UserRole.partenaire:
        return _buildPartnerTabContent(index);
      case UserRole.client:
        return _buildClientTabContent(index);
      case UserRole.admin:
        return _buildAdminTabContent(index);
      case UserRole.associe:
      default:
        return _buildAssociateTabContent(index);
    }
  }

  // ============================================================================
  // CONTENU ONGLETS PARTENAIRE
  // ============================================================================
  Widget _buildPartnerTabContent(int index) {
    switch (index) {
      case 0:
        return const MobileTimesheetTab();
      case 1:
        return const MobileMissionsTab();
      case 2:
        return const MobilePartnerAvailabilityTab();
      case 3:
        return const MobileMessagingTab();
      case 4:
        return const MobileProfileTab();
      default:
        return const MobileTimesheetTab();
    }
  }

  // ============================================================================
  // CONTENU ONGLETS CLIENT
  // ============================================================================
  Widget _buildClientTabContent(int index) {
    switch (index) {
      case 0:
        return const MobileClientProjectsTab();
      case 1:
        return const MobileClientInvoicesTab();
      case 2:
        return const MobileClientRequestsTab();
      case 3:
        return const MobileMessagingTab();
      case 4:
        return const MobileProfileTab();
      default:
        return const MobileClientProjectsTab();
    }
  }

  // ============================================================================
  // CONTENU ONGLETS ADMIN
  // ============================================================================
  Widget _buildAdminTabContent(int index) {
    switch (index) {
      case 0:
        return const MobileDashboardTab();
      case 1:
        return const MobileMissionsTab();
      case 2:
        return const MobileAdminTab();
      case 3:
        return const MobileMessagingTab();
      case 4:
        return const MobileProfileTab();
      default:
        return const MobileDashboardTab();
    }
  }

  // ============================================================================
  // CONTENU ONGLETS ASSOCIÉ (NE PAS MODIFIER)
  // ============================================================================
  Widget _buildAssociateTabContent(int index) {
    switch (index) {
      case 0:
        return const MobileTimesheetTab();
      case 1:
        return const MobileMissionsTab();
      case 2:
        return const MobileReportingTab();
      case 3:
        return const MobileClientsTab();
      case 4:
        return const MobileMessagingTab();
      default:
        return const MobileTimesheetTab();
    }
  }
}
