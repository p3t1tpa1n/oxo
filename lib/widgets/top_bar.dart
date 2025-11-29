// lib/widgets/top_bar.dart
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user_role.dart';
import '../config/app_theme.dart';
import '../config/app_icons.dart';
import 'breadcrumbs_widget.dart';

class TopBar extends StatelessWidget {
  final String title;
  final String? currentRoute;
  final List<BreadcrumbItem>? customBreadcrumbs;
  
  const TopBar({
    super.key,
    this.title = '',
    this.currentRoute,
    this.customBreadcrumbs,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppTheme.colors.surface,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md),
        decoration: BoxDecoration(
          color: AppTheme.colors.surface,
          boxShadow: AppTheme.shadows.small,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: AppTheme.typography.h3.copyWith(
                        color: AppTheme.colors.primary,
                      ),
                    ),
                  const Spacer(),
                  _buildIconButton(
                    context,
                    icon: AppIcons.home,
                    onTap: () => _navigateToRoleDashboard(context),
                    backgroundColor: AppTheme.colors.secondary,
                  ),
                  SizedBox(width: AppTheme.spacing.md),
                  _buildIconButton(
                    context,
                    icon: AppIcons.settings,
                    onTap: () => Navigator.pushNamed(context, '/settings'),
                  ),
                  SizedBox(width: AppTheme.spacing.sm),
                  _buildIconButton(
                    context,
                    icon: AppIcons.profile,
                    onTap: () => _navigateToProfile(context),
                  ),
                ],
              ),
            ),
            // Breadcrumbs sous le titre
            if (currentRoute != null || customBreadcrumbs != null)
              Padding(
                padding: EdgeInsets.only(
                  bottom: AppTheme.spacing.sm,
                  top: AppTheme.spacing.xs,
                ),
                child: BreadcrumbsWidget(
                  items: customBreadcrumbs ?? 
                    BreadcrumbsHelper.fromRoute(context, currentRoute!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radius.small),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radius.small),
          onTap: onTap,
          child: Icon(
            icon,
            color: backgroundColor != null 
              ? Colors.white 
              : AppTheme.colors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _navigateToRoleDashboard(BuildContext context) {
    final userRole = SupabaseService.currentUserRole;
    if (userRole == UserRole.associe) {
      Navigator.pushReplacementNamed(context, '/');
    } else {
      Navigator.pushReplacementNamed(context, '/missions');
    }
  }

  void _navigateToProfile(BuildContext context) {
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
        SnackBar(
          content: const Text('Une erreur est survenue. Veuillez vous reconnecter.'),
          backgroundColor: AppTheme.colors.error,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  }
}