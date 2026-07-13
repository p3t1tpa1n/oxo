// ============================================================================
// PAGE PARTENAIRES ET CLIENTS - Vue unifiée avec onglets
// ============================================================================

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../models/user_role.dart';
import '../associate/partner_profiles_page.dart';
import '../clients/companies_page.dart'; // Nouvelle page pour sociétés/groupes

class PartnersClientsPage extends StatefulWidget {
  const PartnersClientsPage({super.key});

  @override
  State<PartnersClientsPage> createState() => _PartnersClientsPageState();
}

class _PartnersClientsPageState extends State<PartnersClientsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  UserRole? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final role = await SupabaseService.getCurrentUserRole();
      setState(() {
        _userRole = role;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement du rôle: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Row(
          children: [
const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                // Barre d'onglets (le titre est fourni par DesktopShell)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.colors.surface,
                    border: Border(
                      bottom: BorderSide(
                          color: AppTheme.colors.border, width: 0.5),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.colors.primary,
                    unselectedLabelColor: AppTheme.colors.textSecondary,
                    indicatorColor: AppTheme.colors.primary,
                    indicatorWeight: 2,
                    labelStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    unselectedLabelStyle: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.normal),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.people_alt_outlined, size: 20),
                        text: 'Profils Partenaires',
                      ),
                      Tab(
                        icon: Icon(Icons.business_outlined, size: 20),
                        text: 'Sociétés et Groupes',
                      ),
                    ],
                  ),
                ),
                // Contenu des onglets
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      // Onglet Profils Partenaires
                      PartnerProfilesPageContent(),
                      // Onglet Clients
                      ClientsPageContent(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CONTENU DE L'ONGLET PROFILS PARTENAIRES
// ============================================================================

class PartnerProfilesPageContent extends StatelessWidget {
  const PartnerProfilesPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Réutiliser le contenu de PartnerProfilesPage sans l'AppBar et le SideMenu
    return const PartnerProfilesPage(embedded: true);
  }
}

// ============================================================================
// CONTENU DE L'ONGLET SOCIÉTÉS ET GROUPES
// ============================================================================

class ClientsPageContent extends StatelessWidget {
  const ClientsPageContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Réutiliser le contenu de CompaniesPage sans l'AppBar et le SideMenu
    return const CompaniesPage(embedded: true);
  }
}

