import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/supabase_service.dart';

class AuthMiddleware extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _checkAuth(route, previousRoute?.navigator?.context);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) {
      _checkAuth(newRoute, oldRoute?.navigator?.context);
    }
  }

  static Future<void> handleBackNavigation(BuildContext context) async {
    if (!context.mounted) return;
    
    final user = SupabaseService.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    final role = await SupabaseService.getCurrentUserRole();
    
    if (!context.mounted) return;
    
    switch (role) {
      case UserRole.admin:
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        break;
      case UserRole.partenaire:
        Navigator.of(context).pushReplacementNamed('/partner/dashboard');
        break;
      case UserRole.associe:
        Navigator.of(context).pushReplacementNamed('/associate/dashboard');
        break;
      case UserRole.client:
        Navigator.of(context).pushReplacementNamed('/client');
        break;
      default:
        Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _checkAuth(Route<dynamic> route, BuildContext? context) async {
    if (context == null || route.settings.name == '/login') return;

    final user = SupabaseService.currentUser;
    if (user == null && context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    final role = await SupabaseService.getCurrentUserRole();
    if (role == null && context.mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    if (!context.mounted) return;

    switch (role) {
      case UserRole.admin:
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        break;
      case UserRole.partenaire:
        Navigator.of(context).pushReplacementNamed('/partner/dashboard');
        break;
      case UserRole.associe:
        Navigator.of(context).pushReplacementNamed('/associate/dashboard');
        break;
      case UserRole.client:
        Navigator.of(context).pushReplacementNamed('/client');
        break;
      default:
        // Aucune action si le rôle est null ou non reconnu
        break;
    }
  }
} 