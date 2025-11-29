// ============================================================================
// SERVICE DE NAVIGATION iOS - OXO TIME SHEETS
// Gestion de la navigation programmatique pour iOS avec tabs
// ============================================================================

import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/supabase_service.dart';

/// Service de navigation iOS pour gérer les tabs programmatiquement
/// Résout le problème de navigation incohérente sur iOS
class IOSNavigationService {
  IOSNavigationService._();
  
  // ══════════════════════════════════════════════════════════════════════════
  // MAPPING ROUTE → TAB INDEX
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Retourne l'index du tab pour une route donnée selon le rôle
  static int? getTabIndexForRoute(String route, UserRole userRole) {
    switch (userRole) {
      case UserRole.admin:
        return _getAdminTabIndex(route);
      case UserRole.associe:
        return _getAssociateTabIndex(route);
      case UserRole.partenaire:
        return _getPartnerTabIndex(route);
      case UserRole.client:
        return _getClientTabIndex(route);
      default:
        return null;
    }
  }
  
  static int? _getAdminTabIndex(String route) {
    switch (route) {
      case '/':
      case '/dashboard':
      case '/home':
        return 0; // Accueil
      case '/missions':
      case '/projects':
        return 1; // Missions
      case '/admin':
      case '/admin/roles':
      case '/admin/client-requests':
        return 2; // Gestion
      case '/profile':
      case '/settings':
        return 3; // Profil
      default:
        return null;
    }
  }
  
  static int? _getAssociateTabIndex(String route) {
    switch (route) {
      case '/':
      case '/dashboard':
      case '/home':
      case '/associate':
        return 0; // Accueil
      case '/missions':
      case '/projects':
        return 1; // Missions
      case '/partners':
      case '/partners-clients':
        return 2; // Partenaires
      case '/profile':
      case '/settings':
        return 3; // Profil
      default:
        return null;
    }
  }
  
  static int? _getPartnerTabIndex(String route) {
    switch (route) {
      case '/':
      case '/dashboard':
      case '/home':
      case '/partner':
        return 0; // Accueil
      case '/missions':
      case '/projects':
      case '/partner/proposed-missions':
        return 1; // Mes Missions
      case '/profile':
      case '/settings':
        return 2; // Profil
      default:
        return null;
    }
  }
  
  static int? _getClientTabIndex(String route) {
    switch (route) {
      case '/':
      case '/dashboard':
      case '/home':
      case '/client':
        return 0; // Accueil
      case '/client/projects':
      case '/missions':
        return 1; // Mes Missions
      case '/client/requests':
        return 2; // Demandes
      case '/profile':
      case '/settings':
        return 3; // Profil
      default:
        return null;
    }
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // NAVIGATION PROGRAMMATIQUE
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Navigue vers un tab spécifique du dashboard iOS
  /// Remplace Navigator.pushNamed pour une navigation cohérente sur iOS
  static Future<void> navigateToTab(
    BuildContext context,
    String route, {
    bool replace = false,
  }) async {
    final userRole = SupabaseService.currentUserRole;
    
    // Vérifier que l'utilisateur a un rôle
    if (userRole == null) {
      debugPrint('⚠️ IOSNavigationService: Aucun rôle utilisateur trouvé');
      return;
    }
    
    final tabIndex = getTabIndexForRoute(route, userRole);
    
    if (tabIndex == null) {
      debugPrint('⚠️ IOSNavigationService: Route "$route" non mappée pour le rôle $userRole');
      return;
    }
    
    debugPrint('📱 IOSNavigationService: Navigation vers tab $tabIndex (route: $route)');
    
    // Importer dynamiquement IOSDashboardPage pour éviter les dépendances circulaires
    final dashboardPage = await _createDashboardPage(tabIndex);
    
    if (!context.mounted) return;
    
    if (replace) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => dashboardPage),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => dashboardPage),
      );
    }
  }
  
  static Future<Widget> _createDashboardPage(int initialTab) async {
    // Import dynamique pour éviter les dépendances circulaires
    // La page IOSDashboardPage doit être importée ici
    // Pour l'instant, on retourne un placeholder
    // TODO: Implémenter l'import dynamique ou utiliser un callback
    throw UnimplementedError('Utiliser navigateToTabDirect avec une instance de IOSDashboardPage');
  }
  
  /// Navigation directe avec une instance de IOSDashboardPage
  /// À utiliser depuis les widgets qui ont déjà accès à IOSDashboardPage
  static void navigateToTabDirect(
    BuildContext context,
    int tabIndex, {
    bool replace = true,
  }) {
    // Cette méthode sera utilisée par les widgets enfants du dashboard
    // pour communiquer le changement de tab au parent
    debugPrint('📱 IOSNavigationService: Navigation directe vers tab $tabIndex');
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // GESTION DU RETOUR EN ARRIÈRE
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Gère le retour en arrière de manière cohérente sur iOS
  static void handleBackNavigation(BuildContext context) {
    final userRole = SupabaseService.currentUserRole;
    
    // Vérifier que l'utilisateur a un rôle
    if (userRole == null) {
      debugPrint('⚠️ IOSNavigationService: Aucun rôle utilisateur trouvé');
      return;
    }
    
    final defaultTab = _getDefaultTabIndex(userRole);
    
    debugPrint('📱 IOSNavigationService: Retour en arrière → tab $defaultTab');
    
    // Revenir au tab par défaut (Accueil)
    navigateToTabDirect(context, defaultTab);
  }
  
  static int _getDefaultTabIndex(UserRole userRole) {
    // Tous les rôles ont "Accueil" en tab 0
    return 0;
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS POUR DÉTECTION DE PLATEFORME
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Vérifie si on doit utiliser la navigation iOS
  static bool shouldUseIOSNavigation() {
    // À implémenter avec DeviceDetector
    // Pour l'instant, on suppose que si on est sur iOS natif ou web mobile iOS
    return false; // TODO: Implémenter la détection
  }
  
  /// Wrapper pour Navigator.pushNamed qui utilise automatiquement
  /// la navigation iOS ou standard selon la plateforme
  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    if (shouldUseIOSNavigation()) {
      await navigateToTab(context, routeName);
      return null;
    } else {
      return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════
// EXTENSION POUR NAVIGATOR
// ══════════════════════════════════════════════════════════════════════════

extension IOSNavigationExtension on NavigatorState {
  /// Version iOS-aware de pushNamed
  Future<T?> pushNamedIOS<T>(
    String routeName, {
    Object? arguments,
  }) {
    return IOSNavigationService.pushNamed<T>(
      context,
      routeName,
      arguments: arguments,
    );
  }
}

