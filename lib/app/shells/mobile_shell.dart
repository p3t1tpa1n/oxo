// ============================================================================
// MOBILE SHELL - OXO TIME SHEETS
// Shell pour iOS/mobile avec tabs + navigation stack par tab
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/ios_theme.dart';
import '../../services/supabase_service.dart';
import '../../models/user_role.dart';
import '../../pages/dashboard/ios_dashboard_page.dart';

class MobileShell extends StatefulWidget {
  final int? initialTab;
  
  const MobileShell({
    Key? key,
    this.initialTab,
  }) : super(key: key);

  @override
  State<MobileShell> createState() => _MobileShellState();
}

class _MobileShellState extends State<MobileShell> {
  late int _currentIndex;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [];
  
  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab ?? 0;
    final tabCount = _getTabCount();
    for (int i = 0; i < tabCount; i++) {
      _navigatorKeys.add(GlobalKey<NavigatorState>());
    }
  }

  int _getTabCount() {
    final role = SupabaseService.currentUserRole;
    switch (role) {
      case UserRole.admin:
      case UserRole.associe:
        return 4; // Dashboard, Missions, Partenaires, Profil
      case UserRole.partenaire:
        return 3; // Dashboard, Missions, Profil
      case UserRole.client:
        return 4; // Dashboard, Projets, Demandes, Profil
      default:
        return 2; // Dashboard, Profil
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: IOSTheme.systemBackground,
        activeColor: IOSTheme.primaryBlue,
        inactiveColor: IOSTheme.systemGray,
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
    final role = SupabaseService.currentUserRole;
    
    if (role == UserRole.admin || role == UserRole.associe) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.house),
          activeIcon: Icon(CupertinoIcons.house_fill),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.folder),
          activeIcon: Icon(CupertinoIcons.folder_fill),
          label: 'Missions',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person_2),
          activeIcon: Icon(CupertinoIcons.person_2_fill),
          label: 'Partenaires',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person),
          activeIcon: Icon(CupertinoIcons.person_fill),
          label: 'Profil',
        ),
      ];
    } else if (role == UserRole.partenaire) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.house),
          activeIcon: Icon(CupertinoIcons.house_fill),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.briefcase),
          activeIcon: Icon(CupertinoIcons.briefcase_fill),
          label: 'Missions',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person),
          activeIcon: Icon(CupertinoIcons.person_fill),
          label: 'Profil',
        ),
      ];
    } else if (role == UserRole.client) {
      return const [
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.house),
          activeIcon: Icon(CupertinoIcons.house_fill),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.folder),
          activeIcon: Icon(CupertinoIcons.folder_fill),
          label: 'Projets',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.paperplane),
          activeIcon: Icon(CupertinoIcons.paperplane_fill),
          label: 'Demandes',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.person),
          activeIcon: Icon(CupertinoIcons.person_fill),
          label: 'Profil',
        ),
      ];
    }
    
    return const [
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.house),
        label: 'Accueil',
      ),
      BottomNavigationBarItem(
        icon: Icon(CupertinoIcons.person),
        label: 'Profil',
      ),
    ];
  }

  Widget _buildTabContent(int index) {
    final role = SupabaseService.currentUserRole;
    
    // Pour l'instant, on réutilise IOSDashboardPage qui gère déjà les tabs
    // TODO: Migrer vers des widgets séparés dans Phase 4
    if (role == UserRole.admin || role == UserRole.associe) {
      switch (index) {
        case 0:
          return const IOSDashboardPage(initialTab: 0);
        case 1:
          return const IOSDashboardPage(initialTab: 1);
        case 2:
          return const IOSDashboardPage(initialTab: 2);
        case 3:
          return const IOSDashboardPage(initialTab: 3);
        default:
          return const IOSDashboardPage(initialTab: 0);
      }
    } else if (role == UserRole.partenaire) {
      switch (index) {
        case 0:
          return const IOSDashboardPage(initialTab: 0);
        case 1:
          return const IOSDashboardPage(initialTab: 1);
        case 2:
          return const IOSDashboardPage(initialTab: 2);
        default:
          return const IOSDashboardPage(initialTab: 0);
      }
    } else if (role == UserRole.client) {
      switch (index) {
        case 0:
          return const IOSDashboardPage(initialTab: 0);
        case 1:
          return const IOSDashboardPage(initialTab: 1);
        case 2:
          return const IOSDashboardPage(initialTab: 2);
        case 3:
          return const IOSDashboardPage(initialTab: 3);
        default:
          return const IOSDashboardPage(initialTab: 0);
      }
    }
    
    return const IOSDashboardPage(initialTab: 0);
  }
}


