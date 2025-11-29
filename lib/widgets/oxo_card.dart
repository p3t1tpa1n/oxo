// ============================================================================
// OXO CARD - OXO TIME SHEETS
// Widget card OXO-styled : flat, clean, compact, professionnel
// Utilise STRICTEMENT AppTheme
// ============================================================================

import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Card OXO professionnelle : flat, compacte, sans ombres excessives
class OxoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final double? height;

  const OxoCard({
    Key? key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      height: height,
      padding: padding ?? EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        border: Border.all(
          color: AppTheme.colors.border,
          width: 1,
        ),
        // Ombre subtile uniquement
        boxShadow: AppTheme.shadows.small,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

