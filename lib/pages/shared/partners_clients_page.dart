// ============================================================================
// PAGE PARTENAIRES ET CLIENTS - Vue unifiée avec onglets
// ============================================================================

import 'package:flutter/material.dart';
import '../../widgets/side_menu.dart';
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
            SideMenu(
              userRole: _userRole,
              selectedRoute: '/partners-clients',
            ),
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
      body: Row(
        children: [
          SideMenu(
            userRole: _userRole,
            selectedRoute: '/partners-clients',
          ),
          Expanded(
            child: Column(
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people,
                        color: Color(0xFF2A4B63),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Partenaires et Clients',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2A4B63),
                        ),
                      ),
                    ],
                  ),
                ),
                // Barre d'onglets
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF2A4B63),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFF2A4B63),
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.people_alt),
                        text: 'Profils Partenaires',
                      ),
                      Tab(
                        icon: Icon(Icons.business),
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

