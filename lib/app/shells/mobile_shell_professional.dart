// ============================================================================
// MOBILE SHELL PROFESSIONAL - OXO TIME SHEETS
// Shell iOS professionnel avec navigation stack par tab
// Adapte les onglets selon le rôle de l'utilisateur
// Utilise STRICTEMENT AppTheme (pas IOSTheme)
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/app_icons.dart';
import '../../utils/device_detector.dart';
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
  const MobileShellProfessional({Key? key}) : super(key: key);

  @override
  State<MobileShellProfessional> createState() => _MobileShellProfessionalState();
}

class _MobileShellProfessionalState extends State<MobileShellProfessional> {
  int _currentIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [];
  UserRole? _userRole;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      // D'abord essayer de récupérer le rôle depuis le cache
      _userRole = SupabaseService.currentUserRole;
      
      // Si pas de rôle en cache, le charger depuis Supabase
      if (_userRole == null) {
        _userRole = await SupabaseService.getCurrentUserRole();
      }
      
      debugPrint('📱 MobileShellProfessional: Rôle utilisateur = $_userRole');
      
      // Initialiser les clés de navigation
      final tabCount = _getTabCount();
      _navigatorKeys.clear();
      for (int i = 0; i < tabCount; i++) {
        _navigatorKeys.add(GlobalKey<NavigatorState>());
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement rôle: $e');
      // Fallback sur associe par défaut
      _userRole = UserRole.associe;
      final tabCount = _getTabCount();
      _navigatorKeys.clear();
      for (int i = 0; i < tabCount; i++) {
        _navigatorKeys.add(GlobalKey<NavigatorState>());
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
    // Afficher un écran de chargement pendant le chargement du rôle
    if (_isLoading) {
      return CupertinoPageScaffold(
        backgroundColor: AppTheme.colors.background,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CupertinoActivityIndicator(
                radius: 16,
                color: AppTheme.colors.primary,
              ),
              SizedBox(height: AppTheme.spacing.md),
              Text(
                'Chargement...',
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: AppTheme.colors.surface,
        activeColor: AppTheme.colors.primary,
        inactiveColor: AppTheme.colors.textSecondary,
        items: _getTabItems(),
        currentIndex: _currentIndex,
        onTap: (index) {
          // Si on tape sur le même tab, retour à la racine
          if (_currentIndex == index) {
            _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
          }
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          navigatorKey: _navigatorKeys[index],
          builder: (context) => _buildTabContent(index),
        );
      },
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
        icon: Icon(_getIconForPlatform(AppIcons.timesheet, AppIcons.timesheetIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.timesheet, AppIcons.timesheetIOS)),
        label: 'Timesheet',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS)),
        label: 'Missions',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.planning, AppIcons.planningIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.planning, AppIcons.planningIOS)),
        label: 'Dispo',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.messaging, AppIcons.messagingIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.messaging, AppIcons.messagingIOS)),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.profile, AppIcons.profileIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.profile, AppIcons.profileIOS)),
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
        icon: Icon(_getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS)),
        label: 'Projets',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.reporting, AppIcons.reportingIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.reporting, AppIcons.reportingIOS)),
        label: 'Factures',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.actions, AppIcons.actionsIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.actions, AppIcons.actionsIOS)),
        label: 'Demandes',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.messaging, AppIcons.messagingIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.messaging, AppIcons.messagingIOS)),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.profile, AppIcons.profileIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.profile, AppIcons.profileIOS)),
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
        icon: Icon(_getIconForPlatform(AppIcons.home, AppIcons.homeIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.home, AppIcons.homeIOS)),
        label: 'Dashboard',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS)),
        label: 'Missions',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.admin, AppIcons.adminIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.admin, AppIcons.adminIOS)),
        label: 'Admin',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.messaging, AppIcons.messagingIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.messaging, AppIcons.messagingIOS)),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.profile, AppIcons.profileIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.profile, AppIcons.profileIOS)),
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
        icon: Icon(_getIconForPlatform(AppIcons.timesheet, AppIcons.timesheetIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.timesheet, AppIcons.timesheetIOS)),
        label: 'Timesheet',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS)),
        label: 'Mission',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.reporting, AppIcons.reportingIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.reporting, AppIcons.reportingIOS)),
        label: 'Reporting',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.partners, AppIcons.partnersIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.partners, AppIcons.partnersIOS)),
        label: 'Clients',
      ),
      BottomNavigationBarItem(
        icon: Icon(_getIconForPlatform(AppIcons.messaging, AppIcons.messagingIOS)),
        activeIcon: Icon(_getIconForPlatform(AppIcons.messaging, AppIcons.messagingIOS)),
        label: 'Messages',
      ),
    ];
  }

  IconData _getIconForPlatform(IconData material, IconData cupertino) {
    return DeviceDetector.shouldUseIOSInterface() ? cupertino : material;
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


