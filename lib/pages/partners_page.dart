// lib/pages/partners_page.dart
import 'package:flutter/material.dart';
import 'partner_dashboard_page.dart';

class PartnersPage extends StatelessWidget {
  const PartnersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser le dashboard partenaire au lieu d'une page vide
    return const PartnerDashboardPage();
  }
}