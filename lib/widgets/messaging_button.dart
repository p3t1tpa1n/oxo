import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../pages/messaging/messaging_page.dart';

class MessagingFloatingButton extends StatelessWidget {
  final Color backgroundColor;
  final Color iconColor;

  const MessagingFloatingButton({
    super.key,
    this.backgroundColor = const Color(0xFF1E3D54),
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'messagingBtn',
      backgroundColor: backgroundColor,
      foregroundColor: iconColor,
      child: const Icon(Icons.chat_outlined),
      onPressed: () {
        // Naviguer vers la page de messagerie
        Navigator.pushNamed(context, '/messaging');
      },
    );
  }
}

class MessagingBadge extends StatelessWidget {
  final Widget child;

  const MessagingBadge({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Ici, vous pourriez implémenter un StreamBuilder pour afficher un badge
    // avec le nombre de messages non lus, en utilisant Supabase pour récupérer ces informations
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -5,
          right: -5,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 16,
              minHeight: 16,
            ),
            child: const Text(
              '3', // Nombre de messages non lus (à remplacer par la vraie valeur)
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
} 