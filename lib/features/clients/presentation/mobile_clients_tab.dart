// ============================================================================
// MOBILE CLIENTS TAB - OXO TIME SHEETS
// Tab Clients avec partenaires, clients et demandes client
// Utilise STRICTEMENT AppTheme
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../features/partners/presentation/mobile_partners_tab.dart';
import '../../../pages/admin/ios_mobile_admin_clients_page.dart';
import '../../../pages/admin/ios_mobile_client_requests_page.dart';
import '../../../services/supabase_service.dart';
import '../../../models/user_role.dart';
import '../../../utils/device_detector.dart';

class MobileClientsTab extends StatefulWidget {
  const MobileClientsTab({Key? key}) : super(key: key);

  @override
  State<MobileClientsTab> createState() => _MobileClientsTabState();
}

class _MobileClientsTabState extends State<MobileClientsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final UserRole? _userRole = SupabaseService.currentUserRole;

  @override
  void initState() {
    super.initState();
    final tabCount = _getTabCount();
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getTabCount() {
    switch (_userRole) {
      case UserRole.admin:
      case UserRole.associe:
        return 3; // Partenaires, Clients, Demandes
      case UserRole.partenaire:
        return 1; // Partenaires seulement
      case UserRole.client:
        return 1; // Demandes seulement
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.colors.background,
      child: DefaultTextStyle(
        style: TextStyle(
          decoration: TextDecoration.none,
          color: AppTheme.colors.textPrimary,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header personnalisé
              _buildHeader(),
              
              // Tabs (seulement si plusieurs onglets) - wrapped in Material
              if (_getTabCount() > 1)
                Material(
                  color: AppTheme.colors.surface,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.colors.primary,
                    unselectedLabelColor: AppTheme.colors.textSecondary,
                    indicatorColor: AppTheme.colors.primary,
                    tabs: _buildTabs(),
                  ),
                ),
              
              // Contenu
              Expanded(
                child: _getTabCount() > 1
                  ? TabBarView(
                      controller: _tabController,
                      children: _buildTabViews(),
                    )
                  : _buildSingleView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.sm,
      ),
      color: AppTheme.colors.surface,
      child: Row(
        children: [
          // Titre "Clients" en grand et gras
          Expanded(
            child: Text(
              'Clients',
              style: AppTheme.typography.h1.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.colors.textPrimary,
                decoration: TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          // Icône engrenage (paramètres)
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/profile');
            },
            child: Icon(
              _getIconForPlatform(AppIcons.settings, AppIcons.settingsIOS),
              color: AppTheme.colors.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTabs() {
    switch (_userRole) {
      case UserRole.admin:
      case UserRole.associe:
        return [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForPlatform(AppIcons.partners, AppIcons.partnersIOS),
                  size: 16,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Partenaires',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForPlatform(AppIcons.clients, AppIcons.clientsIOS),
                  size: 16,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Clients',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForPlatform(AppIcons.requests, AppIcons.requestsIOS),
                  size: 16,
                ),
                SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Demandes',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ];
      default:
        return [];
    }
  }

  List<Widget> _buildTabViews() {
    switch (_userRole) {
      case UserRole.admin:
      case UserRole.associe:
        return [
          const MobilePartnersTab(),
          const IOSMobileAdminClientsPage(),
          const IOSMobileClientRequestsPage(),
        ];
      default:
        return [];
    }
  }

  Widget _buildSingleView() {
    switch (_userRole) {
      case UserRole.partenaire:
        return const MobilePartnersTab();
      case UserRole.client:
        return const IOSMobileClientRequestsPage();
      default:
        return const MobilePartnersTab();
    }
  }

  IconData _getIconForPlatform(IconData material, IconData cupertino) {
    return DeviceDetector.shouldUseIOSInterface() ? cupertino : material;
  }
}

