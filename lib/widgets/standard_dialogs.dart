import 'package:flutter/material.dart';

/// Classe utilitaire pour tous les dialogues standardisés de l'application
class StandardDialogs {
  
  /// Dialogue de confirmation standard
  static Future<bool?> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirmer',
    String cancelText = 'Annuler',
    Color? confirmColor,
    IconData? icon,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: confirmColor ?? const Color(0xFF1784af)),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor ?? const Color(0xFF1784af),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Dialogue de suppression standard
  static Future<bool?> showDeleteDialog({
    required BuildContext context,
    required String itemName,
    String itemType = 'élément',
    String? additionalWarning,
  }) {
    return showConfirmDialog(
      context: context,
      title: 'Supprimer $itemType',
      message: 'Êtes-vous sûr de vouloir supprimer "$itemName" ?\n'
          '${additionalWarning ?? ''}'
          '\n\nCette action est irréversible.',
      confirmText: 'Supprimer',
      cancelText: 'Annuler',
      confirmColor: Colors.red,
      icon: Icons.delete_outline,
    );
  }

  /// Dialogue d'information standard
  static Future<void> showInfoDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    IconData icon = Icons.info_outline,
    Color iconColor = const Color(0xFF1784af),
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(child: Text(title)),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Dialogue de sélection standard
  static Future<T?> showSelectionDialog<T>({
    required BuildContext context,
    required String title,
    required List<SelectionItem<T>> items,
    T? selectedValue,
    String confirmText = 'Sélectionner',
    String cancelText = 'Annuler',
  }) {
    T? tempSelected = selectedValue;

    return showDialog<T>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: items.map((item) => RadioListTile<T>(
                title: Text(item.label),
                subtitle: item.subtitle != null ? Text(item.subtitle!) : null,
                value: item.value,
                groupValue: tempSelected,
                onChanged: (value) {
                  setState(() {
                    tempSelected = value;
                  });
                },
                activeColor: const Color(0xFF1784af),
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(tempSelected),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1784af),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(confirmText),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialogue de formulaire standard
  static Future<Map<String, dynamic>?> showFormDialog({
    required BuildContext context,
    required String title,
    required List<FormField> fields,
    String confirmText = 'Enregistrer',
    String cancelText = 'Annuler',
    Map<String, dynamic>? initialValues,
  }) {
    final formKey = GlobalKey<FormState>();
    final controllers = <String, TextEditingController>{};
    final values = <String, dynamic>{};

    // Initialiser les contrôleurs
    for (final field in fields) {
      if (field.type == FormFieldType.text || field.type == FormFieldType.email) {
        controllers[field.key] = TextEditingController(
          text: initialValues?[field.key]?.toString() ?? '',
        );
      } else {
        values[field.key] = initialValues?[field.key];
      }
    }

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title),
          content: SizedBox(
            width: 500,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: fields.map((field) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildFormField(field, controllers, values, setState),
                  )).toList(),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Nettoyer les contrôleurs après la fermeture du dialogue
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  controllers.values.forEach((controller) => controller.dispose());
                });
              },
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  // Récupérer les valeurs des contrôleurs
                  final result = <String, dynamic>{};
                  for (final field in fields) {
                    if (controllers.containsKey(field.key)) {
                      result[field.key] = controllers[field.key]!.text;
                    } else {
                      result[field.key] = values[field.key];
                    }
                  }
                  
                  Navigator.of(context).pop(result);
                  // Nettoyer les contrôleurs après la fermeture du dialogue
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    controllers.values.forEach((controller) => controller.dispose());
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1784af),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(confirmText),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildFormField(
    FormField field,
    Map<String, TextEditingController> controllers,
    Map<String, dynamic> values,
    StateSetter setState,
  ) {
    switch (field.type) {
      case FormFieldType.text:
      case FormFieldType.email:
        return TextFormField(
          controller: controllers[field.key],
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            border: const OutlineInputBorder(),
          ),
          keyboardType: field.type == FormFieldType.email 
              ? TextInputType.emailAddress 
              : TextInputType.text,
          validator: field.required
              ? (value) => value?.isEmpty == true ? 'Ce champ est requis' : null
              : null,
        );
      
      case FormFieldType.dropdown:
        return DropdownButtonFormField<dynamic>(
          value: values[field.key],
          decoration: InputDecoration(
            labelText: field.label + (field.required ? ' *' : ''),
            border: const OutlineInputBorder(),
          ),
          items: field.options!.map((option) => DropdownMenuItem(
            value: option.value,
            child: Text(option.label),
          )).toList(),
          onChanged: (value) {
            setState(() {
              values[field.key] = value;
            });
          },
          validator: field.required
              ? (value) => value == null ? 'Ce champ est requis' : null
              : null,
        );
      
      case FormFieldType.date:
        return InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: field.context!,
              initialDate: values[field.key] ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            );
            if (date != null) {
              setState(() {
                values[field.key] = date;
              });
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: field.label + (field.required ? ' *' : ''),
              border: const OutlineInputBorder(),
            ),
            child: Text(
              values[field.key] != null
                  ? _formatDateValue(values[field.key])
                  : 'Sélectionner une date',
            ),
          ),
        );
    }
  }

  /// Helper pour formater une valeur de date (String ou DateTime)
  static String _formatDateValue(dynamic dateValue) {
    if (dateValue == null) return 'Sélectionner une date';
    
    DateTime? date;
    if (dateValue is DateTime) {
      date = dateValue;
    } else if (dateValue is String) {
      date = DateTime.tryParse(dateValue);
    }
    
    if (date != null) {
      return '${date.day}/${date.month}/${date.year}';
    } else {
      return 'Date invalide';
    }
  }
}

/// Classe pour les messages standardisés
class StandardMessages {
  
  /// Afficher un message de succès
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Afficher un message d'erreur
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Afficher un message d'information
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF1784af),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Afficher un message d'avertissement
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_outlined, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

/// Classes de données pour les dialogues

class SelectionItem<T> {
  final T value;
  final String label;
  final String? subtitle;

  const SelectionItem({
    required this.value,
    required this.label,
    this.subtitle,
  });
}

class FormField {
  final String key;
  final String label;
  final FormFieldType type;
  final bool required;
  final List<SelectionItem>? options;
  final BuildContext? context;

  const FormField({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.options,
    this.context,
  });
}

enum FormFieldType {
  text,
  email,
  dropdown,
  date,
}

/// Extension pour simplifier l'utilisation
extension ContextDialogExtension on BuildContext {
  Future<bool?> showConfirm(String title, String message) =>
      StandardDialogs.showConfirmDialog(
        context: this,
        title: title,
        message: message,
      );

  Future<bool?> showDelete(String itemName, {String itemType = 'élément'}) =>
      StandardDialogs.showDeleteDialog(
        context: this,
        itemName: itemName,
        itemType: itemType,
      );

  void showSuccess(String message) =>
      StandardMessages.showSuccess(this, message);

  void showError(String message) =>
      StandardMessages.showError(this, message);

  void showInfo(String message) =>
      StandardMessages.showInfo(this, message);

  void showWarning(String message) =>
      StandardMessages.showWarning(this, message);
} 