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
    if (!_isLoginRoute(route) && !SupabaseService.isAuthenticated) {
      // Si l'utilisateur n'est pas authentifié et tente d'accéder à une route protégée
      // On récupère le context du Navigator pour rediriger
      Future.delayed(Duration.zero, () {
        final navigator = Navigator.of(route.navigator!.context);
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      });
    }
  }

  bool _isLoginRoute(Route<dynamic> route) {
    return route.settings.name == '/login';
  }
} 