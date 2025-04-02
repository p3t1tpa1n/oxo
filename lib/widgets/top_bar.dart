// lib/widgets/top_bar.dart
import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../services/supabase_service.dart';

class TopBar extends StatelessWidget {
  final String title;
  
  const TopBar({
    super.key,
    this.title = '',
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3D54),
                  ),
                ),
              const Spacer(),
              SizedBox(
                width: 36,
                height: 36,
                child: Material(
                  color: const Color(0xFF1784af),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _navigateToRoleDashboard(context),
                    child: const Icon(
                      Icons.home,
                      color: Color(0xFF122b35),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 36,
                height: 36,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                    child: const Icon(
                      Icons.settings,
                      color: Color(0xFF122b35),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                height: 36,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      try {
                        if (SupabaseService.currentUser != null) {
                          Navigator.pushNamed(context, '/profile');
                        } else {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                            (Route<dynamic> route) => false,
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Une erreur est survenue. Veuillez vous reconnecter.'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (Route<dynamic> route) => false,
                        );
                      }
                    },
                    child: const Icon(
                      Icons.account_circle,
                      color: Color(0xFF122b35),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRoleDashboard(BuildContext context) {
    final userRole = SupabaseService.currentUserRole;
    if (userRole == UserRole.associe) {
      // Rediriger vers le tableau de bord des associés
      Navigator.pushReplacementNamed(context, '/');
    } else {
      // Rediriger vers le tableau de bord des partenaires
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }
}