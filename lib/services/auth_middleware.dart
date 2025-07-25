import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user_role.dart';
import 'package:flutter/foundation.dart';

class AuthMiddleware extends RouteObserver<PageRoute> {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _checkAuthentication(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _checkAuthentication(newRoute);
    }
  }

  void _checkAuthentication(Route<dynamic> route) {
    debugPrint('Vérification d\'authentification pour la route: ${route.settings.name}');
    if (!_isLoginRoute(route) && !SupabaseService.isAuthenticated) {
      debugPrint('Non authentifié, redirection vers la page de connexion');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.navigator?.context.mounted == true) {
          Navigator.of(route.navigator!.context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      });
    } else {
      debugPrint('Authentifié, navigation autorisée vers: ${route.settings.name}');
    }
  }

  bool _isLoginRoute(Route<dynamic> route) {
    return route.settings.name == '/login';
  }

  // Méthode pour gérer la navigation en arrière
  static void handleBackNavigation(BuildContext context) {
    final userRole = SupabaseService.currentUserRole;
    String targetRoute;

    // Déterminer la route cible en fonction du rôle de l'utilisateur
    switch (userRole) {
      case UserRole.admin:
        targetRoute = '/associate';
        break;
      case UserRole.associe:
        targetRoute = '/associate';
        break;
      case UserRole.partenaire:
        targetRoute = '/partner';
        break;
      case UserRole.client:
        targetRoute = '/client';
        break;
      default:
        targetRoute = '/login';
    }

    // Si nous sommes déjà sur la page cible, ne rien faire
    if (ModalRoute.of(context)?.settings.name == targetRoute) {
      return;
    }

    // Sinon, naviguer vers la page cible
    Navigator.of(context).pushNamedAndRemoveUntil(
      targetRoute,
      (route) => false,
    );
  }
} 