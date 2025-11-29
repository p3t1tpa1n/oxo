// ============================================================================
// WIDGET BREADCRUMBS - OXO TIME SHEETS
// Fil d'Ariane pour afficher le chemin de navigation
// ============================================================================

import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Widget de fil d'Ariane (breadcrumbs) pour la navigation
/// Affiche le chemin: Dashboard > Missions > Détail Mission
class BreadcrumbsWidget extends StatelessWidget {
  final List<BreadcrumbItem> items;
  
  const BreadcrumbsWidget({
    Key? key,
    required this.items,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) _buildSeparator(),
          _buildBreadcrumbItem(context, items[i], isLast: i == items.length - 1),
        ],
      ],
    );
  }
  
  Widget _buildSeparator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.xs),
      child: Icon(
        Icons.chevron_right,
        size: 16,
        color: AppTheme.colors.textSecondary,
      ),
    );
  }
  
  Widget _buildBreadcrumbItem(BuildContext context, BreadcrumbItem item, {required bool isLast}) {
    final textStyle = isLast
        ? AppTheme.typography.bodyMedium.copyWith(
            color: AppTheme.colors.primary,
            fontWeight: FontWeight.w600,
          )
        : AppTheme.typography.bodyMedium.copyWith(
            color: AppTheme.colors.textSecondary,
          );
    
    if (isLast || item.onTap == null) {
      return Text(item.label, style: textStyle);
    }
    
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius.small),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.xs,
          vertical: 4,
        ),
        child: Text(
          item.label,
          style: textStyle.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: AppTheme.colors.textSecondary.withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

/// Item du fil d'Ariane
class BreadcrumbItem {
  final String label;
  final VoidCallback? onTap;
  
  const BreadcrumbItem({
    required this.label,
    this.onTap,
  });
}

// ══════════════════════════════════════════════════════════════════════════
// HELPER POUR GÉNÉRER AUTOMATIQUEMENT LES BREADCRUMBS
// ══════════════════════════════════════════════════════════════════════════

/// Génère automatiquement les breadcrumbs selon la route actuelle
class BreadcrumbsHelper {
  static List<BreadcrumbItem> fromRoute(BuildContext context, String route) {
    switch (route) {
      case '/missions':
        return [
          BreadcrumbItem(
            label: 'Accueil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
          const BreadcrumbItem(label: 'Missions'),
        ];
      
      case '/mission_detail':
        return [
          BreadcrumbItem(
            label: 'Accueil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
          BreadcrumbItem(
            label: 'Missions',
            onTap: () => Navigator.of(context).pushReplacementNamed('/missions'),
          ),
          const BreadcrumbItem(label: 'Détail'),
        ];
      
      case '/timesheet/entry':
        return [
          BreadcrumbItem(
            label: 'Accueil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
          const BreadcrumbItem(label: 'Saisie du temps'),
        ];
      
      case '/timesheet/reporting':
        return [
          BreadcrumbItem(
            label: 'Accueil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
          BreadcrumbItem(
            label: 'Saisie du temps',
            onTap: () => Navigator.of(context).pushReplacementNamed('/timesheet/entry'),
          ),
          const BreadcrumbItem(label: 'Reporting'),
        ];
      
      case '/timesheet/settings':
        return [
          BreadcrumbItem(
            label: 'Accueil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
          BreadcrumbItem(
            label: 'Saisie du temps',
            onTap: () => Navigator.of(context).pushReplacementNamed('/timesheet/entry'),
          ),
          const BreadcrumbItem(label: 'Paramètres'),
        ];
      
      case '/partners-clients':
        return [
          BreadcrumbItem(
            label: 'Accueil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
          const BreadcrumbItem(label: 'Partenaires et Clients'),
        ];
      
      case '/actions':
        return [
          BreadcrumbItem(
            label: 'Accueil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
          const BreadcrumbItem(label: 'Actions Commerciales'),
        ];
      
      case '/availability':
        return [
          BreadcrumbItem(
            label: 'Accueil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
          const BreadcrumbItem(label: 'Disponibilités'),
        ];
      
      case '/planning':
        return [
          BreadcrumbItem(
            label: 'Accueil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
          const BreadcrumbItem(label: 'Planning'),
        ];
      
      case '/profile':
        return [
          BreadcrumbItem(
            label: 'Accueil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
          const BreadcrumbItem(label: 'Profil'),
        ];
      
      case '/messaging':
        return [
          BreadcrumbItem(
            label: 'Accueil',
            onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
          const BreadcrumbItem(label: 'Messages'),
        ];
      
      default:
        return [const BreadcrumbItem(label: 'Accueil')];
    }
  }
  
  /// Génère des breadcrumbs personnalisés avec un titre spécifique
  static List<BreadcrumbItem> custom({
    required BuildContext context,
    required String parentRoute,
    required String parentLabel,
    required String currentLabel,
  }) {
    return [
      BreadcrumbItem(
        label: 'Accueil',
        onTap: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
      ),
      BreadcrumbItem(
        label: parentLabel,
        onTap: () => Navigator.of(context).pushReplacementNamed(parentRoute),
      ),
      BreadcrumbItem(label: currentLabel),
    ];
  }
}





