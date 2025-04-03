import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../pages/login_page.dart';

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
    // Ne pas rediriger si c'est la page de login ou si l'utilisateur est authentifié
    if (_isLoginRoute(route) || SupabaseService.isAuthenticated) {
      return;
    }

    // Rediriger vers la page de login uniquement si l'utilisateur n'est pas authentifié
    // et tente d'accéder à une route protégée
    Future.delayed(Duration.zero, () {
      if (route.navigator?.context != null) {
        final navigator = Navigator.of(route.navigator!.context);
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    });
  }

  bool _isLoginRoute(Route<dynamic> route) {
    return route.settings.name == '/login' || 
           route.settings.name == null && route is MaterialPageRoute && route.builder is LoginPage;
  }
} 