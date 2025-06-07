// lib/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../services/auth_middleware.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton;
  final String title;

  const CustomAppBar({super.key, this.showBackButton = false, required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF122b35)),
              onPressed: () => AuthMiddleware.handleBackNavigation(context),
            )
          : null,
      title: GestureDetector(
        onTap: () => AuthMiddleware.handleBackNavigation(context),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF1784af),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.home, color: Color(0xFF122b35)),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF122b35),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      centerTitle: false,
    );
  }
}