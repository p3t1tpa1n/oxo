import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../pages/auth/login_page.dart';

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
      // Utilisation de WidgetsBinding pour éviter les problèmes de BuildContext
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (route.navigator?.context.mounted == true) {
          Navigator.of(route.navigator!.context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      });
    }
  }

  bool _isLoginRoute(Route<dynamic> route) {
    return route.settings.name == '/login';
  }
} 