// ============================================================================
// MOBILE REPORTING TAB - OXO TIME SHEETS
// Tab Reporting avec disponibilité et actions commerciales
// Utilise STRICTEMENT AppTheme
// ============================================================================


import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../pages/partner/ios_mobile_availability_page.dart';
import '../../../pages/partner/ios_mobile_actions_page.dart';


class MobileReportingTab extends StatefulWidget {
  const MobileReportingTab({Key? key}) : super(key: key);

  @override
  State<MobileReportingTab> createState() => _MobileReportingTabState();
}

class _MobileReportingTabState extends State<MobileReportingTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getHeaderTitle() {
    switch (_currentTabIndex) {
      case 0:
        return 'Disponibilités';
      case 1:
        return 'Actions Commerciales';
      default:
        return 'Reporting';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header personnalisé avec titre dynamique
            _buildHeader(),

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppTheme.colors.primary,
              unselectedLabelColor: AppTheme.colors.textSecondary,
              indicatorColor: AppTheme.colors.primary,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppIcons.availability, size: 16),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Disponibilités',
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
                      Icon(AppIcons.actions, size: 16),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Actions Comm.',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Contenu
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const IOSMobileAvailabilityPage(showHeader: false),
                  const IOSMobileActionsPage(showHeader: false),
                ],
              ),
            ),
          ],
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
          // Titre dynamique selon l'onglet sélectionné - avec Flexible pour éviter overflow
          Expanded(
            child: Text(
              _getHeaderTitle(),
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
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/profile');
            },
            icon: Icon(
              AppIcons.settings,
              color: AppTheme.colors.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

}

