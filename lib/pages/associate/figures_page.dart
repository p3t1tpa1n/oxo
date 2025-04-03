// lib/pages/associate/figures_page.dart
import 'package:flutter/material.dart';
import '../../widgets/custom_app_bar.dart';

class FiguresPage extends StatelessWidget {
  const FiguresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: CustomAppBar(showBackButton: true, title: "Chiffres Entreprise"),
      body: Center(
        child: Text("Page des chiffres de l'entreprise"),
      ),
    );
  }
}