import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/supabase_service.dart';

class AuthMiddleware {
  static Future<void> handleBackNavigation(BuildContext context) async {
    final user = SupabaseService.instance.client.auth.currentUser;
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    final role = await SupabaseService.instance.getUserRole(user.id);
    switch (role) {
      case UserRole.admin:
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
        break;
      case UserRole.partner:
        Navigator.of(context).pushReplacementNamed('/partner/dashboard');
        break;
      case UserRole.associate:
        Navigator.of(context).pushReplacementNamed('/associate/dashboard');
        break;
      default:
        Navigator.of(context).pushReplacementNamed('/login');
    }
  }
} 