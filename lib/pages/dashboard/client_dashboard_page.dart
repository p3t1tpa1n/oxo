import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../client/project_request_form_page.dart';

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
      final userCompany = await SupabaseService.getUserCompany();
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
      backgroundColor: const Color(0xFFF6F7FA),
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
        backgroundColor: const Color(0xFF1E3D54),
        onPressed: () => Navigator.of(context).pushNamed('/messaging'),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF1E3D54),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Espace Client',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () async {
                await SupabaseService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              icon: const Icon(Icons.logout, size: 18, color: Colors.white70),
              label: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final formattedDate = DateFormat('d MMMM yyyy', 'fr_FR').format(DateTime.now());
    final firstLetter = (_clientInfo?['name'] ?? 'E').substring(0, 1).toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte blanche avec le header
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cercle avec initiale
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E3D54),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      firstLetter,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue, ${_clientInfo?['name'] ?? 'Entreprise'}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3D54),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tableau de bord - $formattedDate',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Icônes en haut à droite (en dehors de la carte)
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/dashboard'),
          icon: const Icon(Icons.home_outlined, color: Color(0xFF1E3D54)),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/profile'),
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF1E3D54)),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/profile'),
          icon: const Icon(Icons.person_outline, color: Color(0xFF1E3D54)),
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
            color: Color(0xFF1E3D54),
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
                color: const Color(0xFF3B82F6),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.w500,
            ),
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
                color: Color(0xFF1E3D54),
              ),
            ),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3D54),
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
                    foregroundColor: const Color(0xFF1E3D54),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: const BorderSide(color: Color(0xFF1E3D54)),
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3D54),
                      ),
                    ),
                    if (mission['description'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        mission['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
              if (isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Text(
                    'En attente de validation',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                )
              else if (status == 'approved')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: const Text(
                    'Approuvé',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF10B981),
                    ),
                  ),
                )
              else if (status == 'rejected')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red),
                  ),
                  child: const Text(
                    'Refusé',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

}













