// lib/pages/figures_page.dart
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart'; // Assure-toi que le fichier existe bien

class FiguresPage extends StatelessWidget {
  const FiguresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(showBackButton: true, title: "Chiffres Entreprise"),
      body: const Center(
        child: Text("Page des chiffres de l'entreprise"),
      ),
    );
  }
}