// ============================================================================
// MOBILE REPORTING TAB - OXO TIME SHEETS
// Tab Reporting avec disponibilité et actions commerciales
// Utilise STRICTEMENT AppTheme
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../pages/partner/ios_mobile_availability_page.dart';
import '../../../pages/partner/ios_mobile_actions_page.dart';
import '../../../utils/device_detector.dart';

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
              // Header personnalisé avec titre dynamique
              _buildHeader(),
              
              // Tabs - wrapped in Material
              Material(
                color: AppTheme.colors.surface,
                child: TabBar(
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
                          Icon(
                            _getIconForPlatform(AppIcons.availability, AppIcons.availabilityIOS),
                            size: 16,
                          ),
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
                          Icon(
                            _getIconForPlatform(AppIcons.actions, AppIcons.actionsIOS),
                            size: 16,
                          ),
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

  IconData _getIconForPlatform(IconData material, IconData cupertino) {
    return DeviceDetector.shouldUseIOSInterface() ? cupertino : material;
  }
}

