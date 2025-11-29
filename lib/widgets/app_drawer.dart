// lib/widgets/app_drawer.dart
import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF1784af)),
            child: Center(
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Exemple de boutons du menu
          ListTile(
            leading: const Icon(Icons.person, color: Color(0xFF122b35)),
            title: const Text("Fiche Associé", style: TextStyle(color: Color(0xFF122b35))),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/associate');
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Color(0xFF122b35)),
            title: const Text("Dashboard", style: TextStyle(color: Color(0xFF122b35))),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/missions');
            },
          ),
        ],
      ),
    );
  }
}