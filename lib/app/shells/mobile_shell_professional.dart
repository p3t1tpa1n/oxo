// ============================================================================
// MOBILE SHELL PROFESSIONAL - OXO TIME SHEETS
// Shell iOS professionnel avec navigation stack par tab
// Utilise STRICTEMENT AppTheme (pas IOSTheme)
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../config/app_icons.dart';
import '../../utils/device_detector.dart';

// Import des tabs
import '../../features/timesheet/presentation/mobile_timesheet_tab.dart';
import '../../features/missions/presentation/mobile_missions_tab.dart';
import '../../features/reporting/presentation/mobile_reporting_tab.dart';
import '../../features/clients/presentation/mobile_clients_tab.dart';
import '../../features/messaging/presentation/mobile_messaging_tab.dart';

class MobileShellProfessional extends StatefulWidget {
  const MobileShellProfessional({Key? key}) : super(key: key);

  @override
  State<MobileShellProfessional> createState() => _MobileShellProfessionalState();
}

class _MobileShellProfessionalState extends State<MobileShellProfessional> {
  int _currentIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [];
  
  @override
  void initState() {
    super.initState();
    final tabCount = _getTabCount();
    for (int i = 0; i < tabCount; i++) {
      _navigatorKeys.add(GlobalKey<NavigatorState>());
    }
  }

  int _getTabCount() {
    // Tous les rôles ont maintenant 5 onglets fixes
    return 5; // Timesheet, Mission, Reporting, Clients, Messages
  }

  @override
  Widget build(BuildContext context) {
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
    // 5 onglets fixes pour tous les rôles
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
    // 5 onglets fixes pour tous les rôles
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


