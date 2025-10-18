import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../config/ios_theme.dart';

// Navigation Bar iOS native
class IOSNavigationBar extends StatelessWidget implements ObstructingPreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final bool previousPageTitle;

  const IOSNavigationBar({
    Key? key,
    required this.title,
    this.leading,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.previousPageTitle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoNavigationBar(
      backgroundColor: IOSTheme.systemBackground,
      middle: Text(
        title,
        style: const TextStyle(
          color: IOSTheme.labelPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          fontFamily: '.SF Pro Text',
        ),
      ),
      leading: leading,
      trailing: actions != null && actions!.isNotEmpty 
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: actions!,
            )
          : null,
      automaticallyImplyLeading: automaticallyImplyLeading,
      previousPageTitle: previousPageTitle ? 'Retour' : null,
      // Flat: pas de bordure inférieure ni d'ombre
      border: null,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(44.0);

  @override
  bool shouldFullyObstruct(BuildContext context) {
    return true;
  }
}

// Card iOS native
class IOSCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const IOSCard({
    Key? key,
    required this.child,
    this.margin,
    this.padding,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: IOSTheme.secondarySystemBackground,
        borderRadius: BorderRadius.circular(12),
        // Flat: suppression des ombres, fine bordure discrète
        border: Border.all(
          color: IOSTheme.systemGray4,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Liste iOS native
class IOSListSection extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry? margin;

  const IOSListSection({
    Key? key,
    this.title,
    required this.children,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                title!.toUpperCase(),
                style: const TextStyle(
                  color: IOSTheme.labelSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600, // Hiérarchie renforcée
                  fontFamily: '.SF Pro Text',
                ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: IOSTheme.secondarySystemGroupedBackground,
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: IOSTheme.systemGray4, width: 1), // Flat
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _buildSeparatedChildren(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSeparatedChildren() {
    final List<Widget> separatedChildren = [];
    for (int i = 0; i < children.length; i++) {
      separatedChildren.add(children[i]);
      if (i < children.length - 1) {
        separatedChildren.add(
          const Divider(
            height: 1,
            thickness: 0.5,
            color: IOSTheme.separator,
            indent: 16,
          ),
        );
      }
    }
    return separatedChildren;
  }
}

// List Tile iOS native
class IOSListTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;

  const IOSListTile({
    Key? key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                      style: const TextStyle(
                        color: IOSTheme.labelPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        fontFamily: '.SF Pro Text',
                      ),
                      child: title,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      DefaultTextStyle(
                        style: const TextStyle(
                          color: IOSTheme.labelSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          fontFamily: '.SF Pro Text',
                        ),
                        child: subtitle!,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// Bouton iOS principal
class IOSPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;

  const IOSPrimaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: CupertinoButton(
        color: isEnabled ? IOSTheme.primaryBlue : IOSTheme.systemGray4,
        borderRadius: BorderRadius.circular(12),
        onPressed: isEnabled && !isLoading ? onPressed : null,
        child: isLoading
            ? const CupertinoActivityIndicator(color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700, // bouton principal mis en avant
                  fontFamily: '.SF Pro Text',
                ),
              ),
      ),
    );
  }
}

// Bouton iOS secondaire
class IOSSecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const IOSSecondaryButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: CupertinoButton(
        color: IOSTheme.systemGray6,
        borderRadius: BorderRadius.circular(12),
        onPressed: isEnabled ? onPressed : null,
        child: Text(
          text,
          style: TextStyle(
            color: isEnabled ? IOSTheme.primaryBlue : IOSTheme.systemGray,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
      ),
    );
  }
}

// Champ de texte iOS
class IOSTextField extends StatelessWidget {
  final String? placeholder;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final Widget? prefix;
  final Widget? suffix;
  final bool enabled;

  const IOSTextField({
    Key? key,
    this.placeholder,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.prefix,
    this.suffix,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      enabled: enabled,
      decoration: BoxDecoration(
        color: IOSTheme.tertiarySystemBackground,
        border: Border.all(
          color: IOSTheme.systemGray4,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      style: const TextStyle(
        color: IOSTheme.labelPrimary,
        fontSize: 17,
        fontFamily: '.SF Pro Text',
      ),
      placeholderStyle: const TextStyle(
        color: IOSTheme.systemGray,
        fontSize: 17,
        fontFamily: '.SF Pro Text',
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      prefix: prefix,
      suffix: suffix,
    );
  }
}

// Alerte iOS native
class IOSAlert {
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'OK',
    String? cancelText,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
  }) {
    return showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: '.SF Pro Text',
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontFamily: '.SF Pro Text',
          ),
        ),
        actions: [
          if (cancelText != null)
            CupertinoDialogAction(
              onPressed: () {
                Navigator.of(context).pop();
                onCancel?.call();
              },
              child: Text(cancelText),
            ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

// Indicateur de chargement iOS
class IOSLoadingIndicator extends StatelessWidget {
  final String? text;
  final Color? color;

  const IOSLoadingIndicator({
    Key? key,
    this.text,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoActivityIndicator(
          color: color ?? IOSTheme.primaryBlue,
        ),
        if (text != null) ...[
          const SizedBox(height: 16),
          Text(
            text!,
            style: const TextStyle(
              color: IOSTheme.labelSecondary,
              fontSize: 15,
              fontFamily: '.SF Pro Text',
            ),
          ),
        ],
      ],
    );
  }
}

// Scaffold iOS avec navigation native
class IOSScaffold extends StatelessWidget {
  final IOSNavigationBar? navigationBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final Widget? floatingActionButton;

  const IOSScaffold({
    Key? key,
    this.navigationBar,
    required this.body,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: navigationBar,
      backgroundColor: backgroundColor ?? IOSTheme.systemGroupedBackground,
      child: SafeArea(
        child: body,
      ),
    );
  }
} 