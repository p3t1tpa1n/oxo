// ============================================================================
// APP FORM — kit de composants de formulaire OXO
//
// Objectif : un style unique et professionnel pour tous les formulaires
// (desktop et mobile). Toujours utiliser ces composants plutôt que des
// TextField/AlertDialog bruts.
//
// Composants :
//   AppFormDialog   : dialogue standardisé (titre, contenu scrollable, actions)
//   AppTextField    : champ texte avec label, validation, icône
//   AppDropdown<T>  : liste déroulante stylée
//   AppDateField    : sélection de date (read-only + date picker)
//   AppFormSection  : titre de section à l'intérieur d'un formulaire
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';

/// Dialogue de formulaire standardisé.
/// Retourne le résultat de [onSubmit] via Navigator.pop si la validation passe.
class AppFormDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final String submitLabel;
  final String cancelLabel;
  final VoidCallback? onSubmit;
  final bool submitEnabled;
  final double maxWidth;

  const AppFormDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.submitLabel = 'Enregistrer',
    this.cancelLabel = 'Annuler',
    this.onSubmit,
    this.submitEnabled = true,
    this.maxWidth = 560,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTheme.spacing.lg,
                AppTheme.spacing.lg,
                AppTheme.spacing.lg,
                subtitle != null ? AppTheme.spacing.sm : AppTheme.spacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.typography.h3),
                  if (subtitle != null) ...[
                    SizedBox(height: AppTheme.spacing.xs),
                    Text(
                      subtitle!,
                      style: AppTheme.typography.bodyMedium.copyWith(
                        color: AppTheme.colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),

            // Contenu scrollable
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < children.length; i++) ...[
                      children[i],
                      if (i < children.length - 1)
                        SizedBox(height: AppTheme.spacing.md),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Actions
            Padding(
              padding: EdgeInsets.all(AppTheme.spacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(cancelLabel),
                  ),
                  SizedBox(width: AppTheme.spacing.sm),
                  FilledButton(
                    onPressed: submitEnabled ? onSubmit : null,
                    child: Text(submitLabel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Champ texte standardisé.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool required;
  final bool obscureText;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.required = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator ??
          (required
              ? (v) =>
                  (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null
              : null),
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        isDense: true,
      ),
    );
  }
}

/// Liste déroulante standardisée.
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final String label;
  final IconData? icon;
  final bool required;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const AppDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.items,
    required this.onChanged,
    this.icon,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: required ? (v) => v == null ? 'Champ obligatoire' : null : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
        isDense: true,
      ),
    );
  }
}

/// Champ date standardisé (ouvre un date picker).
class AppDateField extends StatelessWidget {
  final DateTime? value;
  final String label;
  final bool required;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onChanged;

  const AppDateField({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.required = false,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.radius.small),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime(2035),
          locale: const Locale('fr', 'FR'),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          prefixIcon: const Icon(Icons.calendar_today, size: 20),
          isDense: true,
        ),
        child: Text(
          value != null ? DateFormat('dd/MM/yyyy').format(value!) : 'Choisir…',
          style: value != null
              ? AppTheme.typography.bodyMedium
              : AppTheme.typography.bodyMedium.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
        ),
      ),
    );
  }
}

/// Titre de section dans un formulaire long.
class AppFormSection extends StatelessWidget {
  final String title;

  const AppFormSection(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: AppTheme.spacing.sm),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: AppTheme.typography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 0.8,
              color: AppTheme.colors.textSecondary,
            ),
          ),
          SizedBox(width: AppTheme.spacing.md),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}
