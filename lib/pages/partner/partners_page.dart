// lib/pages/partner/partners_page.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../dashboard/partner_dashboard_page.dart';

class PartnersPage extends StatelessWidget {
  const PartnersPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Utiliser le dashboard partenaire au lieu d'une page vide
    return const PartnerDashboardPage();
  }
}