// ============================================================================
// SERVICE DE FEEDBACK UTILISATEUR - OXO TIME SHEETS
// Standardisation des messages de succès, erreurs, informations
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../config/app_theme.dart';
import '../config/app_icons.dart';

/// Service centralisé pour tous les feedbacks utilisateurs
/// Utiliser `FeedbackService.showSuccess(context, 'Message')` au lieu de `ScaffoldMessenger`
class FeedbackService {
  FeedbackService._();
  
  // ══════════════════════════════════════════════════════════════════════════
  // SNACKBARS STANDARDISÉS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Affiche un message de succès (vert)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: AppIcons.success,
      backgroundColor: AppTheme.colors.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Affiche un message d'erreur (rouge)
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: AppIcons.error,
      backgroundColor: AppTheme.colors.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Affiche un message d'avertissement (orange)
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: AppIcons.warning,
      backgroundColor: AppTheme.colors.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Affiche un message d'information (bleu)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    _showSnackBar(
      context,
      message: message,
      icon: AppIcons.info,
      backgroundColor: AppTheme.colors.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
  
  /// Affiche un message de chargement
  static void showLoading(
    BuildContext context,
    String message,
  ) {
    _showSnackBar(
      context,
      message: message,
      icon: Icons.hourglass_empty,
      backgroundColor: AppTheme.colors.primary,
      duration: const Duration(days: 1), // Durée infinie, à fermer manuellement
    );
  }
  
  /// Ferme le snackbar actuel
  static void dismiss(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // DIALOGUES STANDARDISÉS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Affiche un dialogue de confirmation
  /// Retourne `true` si l'utilisateur confirme, `false` sinon
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive 
                  ? AppTheme.colors.error 
                  : AppTheme.colors.primary,
              ),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }
  
  /// Affiche un dialogue d'information
  static Future<void> showInfoDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(AppIcons.info, color: AppTheme.colors.info),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }
  
  /// Affiche un dialogue d'erreur
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(AppIcons.error, color: AppTheme.colors.error),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors.error,
              ),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }
  
  /// Affiche un dialogue de succès
  static Future<void> showSuccessDialog(
    BuildContext context, {
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onClose,
  }) async {
    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(AppIcons.success, color: AppTheme.colors.success),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onClose?.call();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors.success,
              ),
              child: Text(buttonText),
            ),
          ],
        );
      },
    );
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // BOTTOM SHEETS STANDARDISÉS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Affiche un bottom sheet avec options
  static Future<T?> showOptionsSheet<T>(
    BuildContext context, {
    required String title,
    required List<OptionItem<T>> options,
  }) async {
    return await showModalBottomSheet<T>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius.large),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                child: Text(
                  title,
                  style: AppTheme.typography.h4,
                ),
              ),
              const Divider(),
              ...options.map((option) => ListTile(
                leading: option.icon != null 
                  ? Icon(option.icon, color: option.iconColor)
                  : null,
                title: Text(option.label),
                subtitle: option.subtitle != null 
                  ? Text(option.subtitle!)
                  : null,
                onTap: () => Navigator.of(sheetContext).pop(option.value),
              )),
              SizedBox(height: AppTheme.spacing.sm),
            ],
          ),
        );
      },
    );
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // MÉTHODES PRIVÉES
  // ══════════════════════════════════════════════════════════════════════════
  
  static void _showSnackBar(
    BuildContext context, {
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        ),
        margin: EdgeInsets.all(AppTheme.spacing.md),
        duration: duration,
        action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction,
            )
          : null,
      ),
    );
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // FEEDBACKS SPÉCIFIQUES À OXO
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Feedback après création d'une mission
  static void showMissionCreated(BuildContext context, String missionName) {
    showSuccess(
      context,
      'Mission "$missionName" créée avec succès',
      actionLabel: 'Voir',
      onAction: () {
        // TODO: Naviguer vers la mission
      },
    );
  }
  
  /// Feedback après mise à jour d'une mission
  static void showMissionUpdated(BuildContext context, String missionName) {
    showSuccess(
      context,
      'Mission "$missionName" mise à jour',
    );
  }
  
  /// Feedback après suppression d'une mission
  static void showMissionDeleted(BuildContext context) {
    showSuccess(
      context,
      'Mission supprimée',
    );
  }
  
  /// Feedback après sauvegarde d'une entrée timesheet
  static void showTimesheetEntrySaved(BuildContext context, String date) {
    showSuccess(
      context,
      '$date enregistré ✓',
      duration: const Duration(seconds: 2),
    );
  }
  
  /// Feedback après acceptation d'une proposition de mission
  static void showMissionProposalAccepted(BuildContext context, String missionName) {
    showSuccess(
      context,
      'Mission "$missionName" acceptée',
    );
  }
  
  /// Feedback après refus d'une proposition de mission
  static void showMissionProposalRejected(BuildContext context) {
    showInfo(
      context,
      'Proposition refusée',
    );
  }
  
  /// Feedback d'erreur générique
  static void showGenericError(BuildContext context, [String? details]) {
    showError(
      context,
      details != null 
        ? 'Une erreur est survenue : $details'
        : 'Une erreur est survenue',
    );
  }
  
  /// Feedback de validation réussie
  static void showValidationSuccess(BuildContext context, String entityName) {
    showSuccess(
      context,
      '$entityName validé avec succès',
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// CLASSES UTILITAIRES
// ══════════════════════════════════════════════════════════════════════════

/// Item d'option pour les bottom sheets
class OptionItem<T> {
  final String label;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final T value;
  
  const OptionItem({
    required this.label,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.value,
  });
}





