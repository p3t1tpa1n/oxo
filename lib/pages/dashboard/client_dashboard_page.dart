import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
import '../client/project_request_form_page.dart';
import '../../services/company_service.dart';

class ClientDashboardPage extends StatefulWidget {
  const ClientDashboardPage({super.key});

  @override
  State<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
  bool _isLoading = true;
  String _selectedMenu = 'dashboard';

  Map<String, dynamic>? _clientInfo;
  List<Map<String, dynamic>> _missions = [];

  int _activeProjects = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userCompany = await CompanyService.getUserCompany();
      final missions = await SupabaseService.getClientRecentMissions();
      
      // Récupérer aussi les propositions de projets en attente
      final proposals = await _fetchProjectProposals();
      
      // Combiner missions et propositions
      final allProjects = <Map<String, dynamic>>[];
      allProjects.addAll(missions);
      allProjects.addAll(proposals);

      final activeProjects = allProjects.where((mission) {
        final status = (mission['status'] ?? 'in_progress').toString();
        return [
          'in_progress',
          'accepted',
          'pending',
          'actif',
        ].contains(status);
      }).length;

      if (!mounted) return;
      setState(() {
        _clientInfo = {
          'name': userCompany?['company_name'] ?? 'Entreprise',
          'id': userCompany?['company_id'],
        };
        _missions = allProjects;
        _activeProjects = activeProjects;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement dashboard client: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchProjectProposals() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return [];

      final response = await SupabaseService.client
          .from('project_proposals')
          .select('*')
          .eq('client_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(5);

      // Transformer les propositions en format similaire aux missions
      return List<Map<String, dynamic>>.from(response).map((proposal) {
        return {
          'id': proposal['id'],
          'title': proposal['title'],
          'description': proposal['description'],
          'status': proposal['status'] ?? 'pending',
          'is_proposal': true, // Marquer comme proposition
          'created_at': proposal['created_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Erreur chargement propositions client: $e');
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 32),
                                _buildActivitySummary(),
                                const SizedBox(height: 32),
                                _buildProjectsSection(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_client_dashboard',
        backgroundColor: AppTheme.colors.secondary,
        elevation: 1,
        onPressed: () => Navigator.of(context).pushNamed('/messaging'),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: AppTheme.colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.colors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'OX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'OXO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 6),
            child: Text(
              'ESPACE CLIENT',
              style: TextStyle(
                color: Colors.white.withAlpha(102),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
          _buildSidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Tableau de bord',
            isSelected: _selectedMenu == 'dashboard',
            onTap: () => setState(() => _selectedMenu = 'dashboard'),
          ),
          _buildSidebarItem(
            icon: Icons.receipt_long_outlined,
            label: 'Factures',
            isSelected: _selectedMenu == 'invoices',
            onTap: () {
              setState(() => _selectedMenu = 'invoices');
              Navigator.of(context).pushNamed('/client/invoices');
            },
          ),
          _buildSidebarItem(
            icon: Icons.person_outline,
            label: 'Profil',
            isSelected: _selectedMenu == 'profile',
            onTap: () {
              setState(() => _selectedMenu = 'profile');
              Navigator.of(context).pushNamed('/profile');
            },
          ),
          _buildSidebarItem(
            icon: Icons.chat_bubble_outline,
            label: 'Messages',
            isSelected: _selectedMenu == 'messages',
            onTap: () {
              setState(() => _selectedMenu = 'messages');
              Navigator.of(context).pushNamed('/messaging');
            },
          ),
          const Spacer(),
          // Carte utilisateur + déconnexion
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppTheme.colors.secondaryLight,
                    child: Text(
                      (_clientInfo?['name'] ?? 'E')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _clientInfo?['name'] ?? 'Entreprise',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Client',
                          style: TextStyle(
                            color: Colors.white.withAlpha(153),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await SupabaseService.signOut();
                      if (mounted) {
                        Navigator.of(context)
                            .pushReplacementNamed('/login');
                      }
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Colors.white.withAlpha(191),
                      size: 18,
                    ),
                    tooltip: 'Déconnexion',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withAlpha(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color:
                  isSelected ? Colors.white.withAlpha(31) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.colors.sidebarAccent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon,
                    color: Colors.white.withAlpha(isSelected ? 255 : 191),
                    size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withAlpha(isSelected ? 255 : 204),
                      fontSize: 13.5,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final formattedDate =
        DateFormat('d MMMM yyyy', 'fr_FR').format(DateTime.now());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bienvenue, ${_clientInfo?['name'] ?? 'Entreprise'}',
                style: AppTheme.typography.h2,
              ),
              const SizedBox(height: 4),
              Text(
                'Tableau de bord — $formattedDate',
                style: AppTheme.typography.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/profile'),
          icon: Icon(Icons.person_outline, color: AppTheme.colors.primary),
          tooltip: 'Profil',
        ),
      ],
    );
  }

  Widget _buildActivitySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résumé de votre activité',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF16283C),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActivityCard(
                value: '$_activeProjects',
                label: 'Missions actives',
                icon: Icons.business_center_outlined,
                color: AppTheme.colors.secondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radius.small),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colors.textPrimary,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Vos missions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF16283C),
              ),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16283C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    elevation: 2,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProjectRequestFormPage()),
                    );
                  },
                  icon: const Icon(Icons.add_business_outlined, size: 18),
                  label: const Text('Proposer un projet'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF16283C),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: const BorderSide(color: Color(0xFF16283C)),
                  ),
                  onPressed: () => Navigator.of(context).pushNamed('/projects'),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text('Voir tous'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius.medium),
            border: Border.all(color: AppTheme.colors.border, width: 0.5),
          ),
          child: _missions.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Aucune mission en cours',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _missions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildProjectTile(_missions[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildProjectTile(Map<String, dynamic> mission) {
    final isProposal = mission['is_proposal'] == true;
    final status = mission['status']?.toString() ?? '';
    final isPending = isProposal && (status == 'pending' || status == 'in_review');

    Widget statusPill(String label, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 7, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        border: Border.all(color: AppTheme.colors.borderLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission['title'] ?? 'Mission sans titre',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.colors.textPrimary,
                      ),
                    ),
                    if (mission['description'] != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        mission['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: AppTheme.colors.textSecondary,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isPending)
                statusPill('En attente de validation', AppTheme.colors.warning)
              else if (status == 'approved')
                statusPill('Approuvé', AppTheme.colors.success)
              else if (status == 'rejected')
                statusPill('Refusé', AppTheme.colors.error),
            ],
          ),
        ],
      ),
    );
  }

}













