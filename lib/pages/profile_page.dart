// lib/pages/profile_page.dart
import 'package:flutter/material.dart';
import '../models/profile.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/app_drawer.dart';

class ProfilePage extends StatelessWidget {
  final Profile profile;
  const ProfilePage({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(showBackButton: true, title: 'Mon Profil'),
      drawer: const AppDrawer(),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle, size: 80, color: Color(0xFF1784af)),
                const SizedBox(height: 16),
                Text(
                  profile.displayName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF122b35)),
                ),
                const SizedBox(height: 8),
                Text(profile.email, style: const TextStyle(fontSize: 16, color: Color(0xFF122b35))),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    currentProfile = null;
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: const Text('Déconnexion'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}