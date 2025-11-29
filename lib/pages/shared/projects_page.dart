import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../models/company.dart';
import '../../models/user_role.dart';
import '../../config/app_theme.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _missions = [];
  List<Map<String, dynamic>> _filteredMissions = [];
  List<Map<String, dynamic>> _partners = [];
  List<Company> _companies = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'name';
  String _filterStatus = 'all';
  bool _sortAscending = true;
  
  // Variables pour la vue détaillée
  Map<String, dynamic>? _selectedMission;
  String _currentView = 'grid'; // 'grid' ou 'detail'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger missions, partenaires et sociétés en parallèle
      await Future.wait([
        _loadMissions(),
        _loadPartners(),
        _loadCompanies(),
      ]);

      setState(() {
        _isLoading = false;
      });
      
      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadMissions() async {
    final userRole = SupabaseService.currentUserRole;
    final currentUserId = SupabaseService.client.auth.currentUser?.id;

    // Si c'est un partenaire, charger les propositions ET les missions directement assignées
    if (userRole == UserRole.partenaire && currentUserId != null) {
      _missions = [];
      
      // 1. Récupérer les propositions de mission pour ce partenaire
      try {
        final proposalsResponse = await SupabaseService.client
            .from('mission_proposals')
            .select('''
              *,
              missions:mission_id(*)
            ''')
            .eq('partner_id', currentUserId)
            .inFilter('status', ['pending', 'accepted']);

        final proposals = List<Map<String, dynamic>>.from(proposalsResponse);
        
        for (var proposal in proposals) {
          dynamic missionData = proposal['missions'];
          if (missionData == null && proposal['mission_id'] != null) {
            try {
              final missionResponse = await SupabaseService.client
                  .from('missions')
                  .select('*')
                  .eq('id', proposal['mission_id'])
                  .single();
              missionData = missionResponse;
            } catch (e) {
              debugPrint('Erreur récupération mission: $e');
              continue;
            }
          }
          
          if (missionData != null) {
            final mission = Map<String, dynamic>.from(missionData);
            mission['proposal_id'] = proposal['id'];
            mission['proposal_status'] = proposal['status'];
            mission['proposed_at'] = proposal['proposed_at'];
            mission['response_notes'] = proposal['response_notes'];
            mission['is_proposal'] = true; // Marquer comme proposition
            _missions.add(mission);
          }
        }
      } catch (e) {
        debugPrint('Erreur chargement propositions: $e');
      }

      // 2. Récupérer les missions directement assignées au partenaire (via partner_id)
      try {
        final assignedMissionsResponse = await SupabaseService.client
            .from('missions')
            .select('*')
            .eq('partner_id', currentUserId)
            .inFilter('progress_status', ['en_cours', 'fait']);

        final assignedMissions = List<Map<String, dynamic>>.from(assignedMissionsResponse);
        
        // Ajouter les missions assignées qui ne sont pas déjà dans la liste (via proposition acceptée)
        final existingMissionIds = _missions.map((m) => m['id']?.toString()).toSet();
        
        for (var mission in assignedMissions) {
          final missionId = mission['id']?.toString();
          if (missionId != null && !existingMissionIds.contains(missionId)) {
            mission['is_proposal'] = false; // Mission directement assignée
            mission['is_assigned'] = true;
            _missions.add(mission);
          }
        }
      } catch (e) {
        debugPrint('Erreur chargement missions assignées: $e');
      }

      return _missions;
    } else {
      // Pour les autres rôles, charger toutes les missions
      final response = await SupabaseService.client
          .from('missions')
          .select('*')
          .order('created_at', ascending: false);

      _missions = List<Map<String, dynamic>>.from(response);
      return _missions;
    }
  }

  Future<List<Map<String, dynamic>>> _loadPartners() async {
    _partners = await SupabaseService.getPartners();
    return _partners;
  }

  Future<void> _loadCompanies() async {
    try {
      final response = await SupabaseService.client
          .from('company_with_group')
          .select()
          .eq('company_active', true)
          .order('company_name');

      _companies = (response as List)
          .map((json) => Company.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Erreur lors du chargement des sociétés: $e');
      _companies = [];
    }
  }

  void _applyFiltersAndSort() {
    setState(() {
      _filteredMissions = _missions.where((mission) {
        // Filtre de recherche
        final matchesSearch = _searchQuery.isEmpty ||
            (mission['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (mission['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (mission['description']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);

        // Filtre de statut
        final matchesStatus = _filterStatus == 'all' || mission['progress_status'] == _filterStatus;

        return matchesSearch && matchesStatus;
      }).toList();

      // Tri
      _filteredMissions.sort((a, b) {
        int comparison = 0;
        switch (_sortBy) {
          case 'name':
            final aName = a['title'] ?? a['name'] ?? '';
            final bName = b['title'] ?? b['name'] ?? '';
            comparison = aName.toString().compareTo(bName.toString());
            break;
          case 'date':
            final aDate = a['created_at'] ?? '';
            final bDate = b['created_at'] ?? '';
            comparison = aDate.toString().compareTo(bDate.toString());
            break;
          case 'status':
            final aStatus = a['progress_status'] ?? '';
            final bStatus = b['progress_status'] ?? '';
            comparison = aStatus.toString().compareTo(bStatus.toString());
            break;
        }
        return _sortAscending ? comparison : -comparison;
      });
    });
  }

  void _showMissionDetails(Map<String, dynamic> mission) async {
    // Charger les informations du partenaire si partner_id existe
    final partnerId = mission['partner_id']?.toString();
    if (partnerId != null && partnerId.isNotEmpty) {
      try {
        // Essayer de charger depuis partner_profiles
        final partnerProfile = await SupabaseService.client
            .from('partner_profiles')
            .select('first_name, last_name, email')
            .eq('user_id', partnerId)
            .maybeSingle();
        
        if (partnerProfile != null) {
          mission['partner_first_name'] = partnerProfile['first_name'];
          mission['partner_last_name'] = partnerProfile['last_name'];
          mission['partner_email'] = partnerProfile['email'];
        } else {
          // Essayer depuis profiles
          final profile = await SupabaseService.client
              .from('profiles')
              .select('first_name, last_name, email')
              .eq('id', partnerId)
              .maybeSingle();
          
          if (profile != null) {
            mission['partner_first_name'] = profile['first_name'];
            mission['partner_last_name'] = profile['last_name'];
            mission['partner_email'] = profile['email'];
          }
        }
      } catch (e) {
        debugPrint('Erreur chargement partenaire: $e');
      }
    }
    
    setState(() {
      _selectedMission = mission;
      _currentView = 'detail';
    });
  }

  void _backToGrid() {
    setState(() {
      _currentView = 'grid';
      _selectedMission = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Le SideMenu et TopBar sont maintenant gérés par DesktopShell
    // On retourne uniquement le contenu principal
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _currentView == 'grid'
                          ? _buildMissionsGridView()
                          : _buildMissionDetailView(),
      floatingActionButton: _currentView == 'grid' && SupabaseService.currentUserRole != UserRole.partenaire
          ? FloatingActionButton.extended(
              onPressed: _showCreateMissionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle Mission'),
              backgroundColor: const Color(0xFF2A4B63),
            )
          : null,
    );
  }

  // ============= VUE GRILLE DES MISSIONS =============

  Widget _buildMissionsGridView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildMissionFilters(),
          const SizedBox(height: 24),
          Expanded(
            child: _filteredMissions.isEmpty
                ? _buildEmptyMissionsState()
                : _buildMissionsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionFilters() {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher une mission...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF2A4B63)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF2A4B63)),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFiltersAndSort();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _filterStatus,
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('Tous les statuts')),
                    DropdownMenuItem(value: 'à_assigner', child: Text('À assigner')),
                    DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                    DropdownMenuItem(value: 'fait', child: Text('Terminé')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                    });
                    _applyFiltersAndSort();
                  },
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(value: 'name', child: Text('Trier par nom')),
                    DropdownMenuItem(value: 'date', child: Text('Trier par date')),
                    DropdownMenuItem(value: 'status', child: Text('Trier par statut')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                    });
                    _applyFiltersAndSort();
                  },
                ),
                IconButton(
                  icon: Icon(_sortAscending ? Icons.arrow_upward : Icons.arrow_downward),
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                    _applyFiltersAndSort();
                  },
                  tooltip: _sortAscending ? 'Tri croissant' : 'Tri décroissant',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMissionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune mission',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Créez votre première mission pour commencer.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredMissions.length,
      itemBuilder: (context, index) => _buildMissionCard(_filteredMissions[index]),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final isPartner = SupabaseService.currentUserRole == UserRole.partenaire;
    final isProposal = mission['is_proposal'] == true;
    final proposalStatus = mission['proposal_status'] as String?;
    final isAssigned = mission['is_assigned'] == true;
    
    // Pour les partenaires, déterminer le statut et le label
    String progressStatusLabel;
    Color progressStatusColor;
    String? badgeText;
    
    if (isPartner) {
      if (isProposal && proposalStatus == 'pending') {
        // Proposition en attente
        progressStatusLabel = 'Proposition en attente';
        progressStatusColor = const Color(0xFFFF9800);
        badgeText = 'NOUVELLE PROPOSITION';
      } else if (isProposal && proposalStatus == 'accepted') {
        // Proposition acceptée
        progressStatusLabel = 'Acceptée';
        progressStatusColor = const Color(0xFF4CAF50);
        badgeText = 'PROPOSITION ACCEPTÉE';
      } else if (isAssigned || (isProposal && proposalStatus == 'accepted')) {
        // Mission assignée
        final status = mission['progress_status']?.toString() ?? 'en_cours';
        progressStatusLabel = _getProgressStatusLabel(status);
        progressStatusColor = _getProgressStatusColor(status);
        badgeText = null;
      } else {
        progressStatusLabel = 'En attente';
        progressStatusColor = Colors.grey;
        badgeText = null;
      }
    } else {
      // Pour les autres rôles, utiliser le statut normal
      final status = mission['progress_status']?.toString() ?? 'à_assigner';
      progressStatusLabel = _getProgressStatusLabel(status);
      progressStatusColor = _getProgressStatusColor(status);
      badgeText = null;
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showMissionDetails(mission),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge "NOUVELLE PROPOSITION" si c'est une proposition en attente
              if (badgeText != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active, size: 14, color: const Color(0xFFFF9800)),
                      const SizedBox(width: 6),
                      Text(
                        badgeText,
                        style: const TextStyle(
                          color: Color(0xFFFF9800),
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission['title'] ?? mission['name'] ?? 'Mission sans nom',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2A4B63),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isPartner && isProposal && proposalStatus == 'pending') ...[
                          const SizedBox(height: 4),
                          Text(
                            '📩 Proposition reçue - Cliquez pour voir les détails',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: progressStatusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: progressStatusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      progressStatusLabel,
                      style: TextStyle(
                        color: progressStatusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (mission['description'] != null)
                Expanded(
                  child: Text(
                    mission['description'],
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Spacer(),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (mission['start_date'] != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(DateTime.parse(mission['start_date'])),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  if (mission['priority'] != null)
                    Text(
                      mission['priority'].toString().toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getProgressStatusLabel(String status) {
    switch (status) {
      case 'à_assigner':
        return 'À assigner';
      case 'en_cours':
        return 'En cours';
      case 'fait':
        return 'Terminé';
      default:
        return status;
    }
  }

  Color _getProgressStatusColor(String status) {
    switch (status) {
      case 'à_assigner':
        return const Color(0xFFFF9800);
      case 'en_cours':
        return const Color(0xFF2196F3);
      case 'fait':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  String _getProposalStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'accepted':
        return 'Acceptée';
      case 'rejected':
        return 'Refusée';
      default:
        return status;
    }
  }

  Color _getProposalStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFF9800);
      case 'accepted':
        return const Color(0xFF4CAF50);
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ============= VUE DÉTAIL DE LA MISSION =============

  Widget _buildMissionDetailView() {
    if (_selectedMission == null) return const SizedBox();
    
    final isPartner = SupabaseService.currentUserRole == UserRole.partenaire;
    final proposalStatus = _selectedMission!['proposal_status'] as String?;
    final isPendingProposal = isPartner && proposalStatus == 'pending';
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMissionDetailHeader(),
            const SizedBox(height: 32),
            _buildMissionDetailsGrid(),
            // Boutons d'acceptation/refus pour les partenaires
            if (isPendingProposal) ...[
              const SizedBox(height: 32),
              _buildProposalActions(),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildProposalActions() {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proposition de mission',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2A4B63),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez reçu une proposition de mission. Acceptez-la ou refusez-la.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            if (_selectedMission!['proposed_at'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Proposée le: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(_selectedMission!['proposed_at'].toString()))}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _rejectMissionProposal(),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label: const Text(
                    'Refuser',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => _acceptMissionProposal(),
                  icon: const Icon(Icons.check),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _acceptMissionProposal() async {
    final proposalId = _selectedMission!['proposal_id'] as String?;
    if (proposalId == null) return;

    try {
      await SupabaseService.client
          .from('mission_proposals')
          .update({
            'status': 'accepted',
            'response_at': DateTime.now().toIso8601String(),
          })
          .eq('id', proposalId);

      // Mettre à jour le partner_id de la mission
      await SupabaseService.client
          .from('missions')
          .update({
            'partner_id': SupabaseService.client.auth.currentUser?.id,
            'progress_status': 'en_cours',
          })
          .eq('id', _selectedMission!['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mission acceptée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
        _backToGrid();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectMissionProposal() async {
    final proposalId = _selectedMission!['proposal_id'] as String?;
    if (proposalId == null) return;

    // Demander une raison de refus
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la mission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Voulez-vous vraiment refuser cette mission ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du refus (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await SupabaseService.client
          .from('mission_proposals')
          .update({
            'status': 'rejected',
            'response_at': DateTime.now().toIso8601String(),
            'response_notes': reasonController.text.isEmpty ? null : reasonController.text,
          })
          .eq('id', proposalId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mission refusée'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadData();
        _backToGrid();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildMissionDetailHeader() {
    final mission = _selectedMission!;
    final progressStatus = mission['progress_status']?.toString() ?? 'à_assigner';
    final progressStatusLabel = _getProgressStatusLabel(progressStatus);
    final progressStatusColor = _getProgressStatusColor(progressStatus);

    return Card(
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            IconButton(
              onPressed: _backToGrid,
              icon: const Icon(Icons.arrow_back, color: Color(0xFF2A4B63)),
              tooltip: 'Retour aux missions',
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission['title'] ?? mission['name'] ?? 'Mission sans nom',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2A4B63),
                    ),
                  ),
                  if (mission['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      mission['description'],
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (progressStatus == 'à_assigner')
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: progressStatusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: progressStatusColor.withOpacity(0.3)),
                ),
                child: Text(
                  progressStatusLabel,
                  style: TextStyle(
                    color: progressStatusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(width: 16),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMissionAction(mission, value),
              icon: const Icon(Icons.more_vert, color: Color(0xFF2A4B63)),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Modifier la mission')),
                const PopupMenuItem(value: 'delete', child: Text('Supprimer la mission')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionDetailsGrid() {
    final mission = _selectedMission!;
    final isAssociate = SupabaseService.currentUserRole == UserRole.associe;
    final hasPartner = mission['partner_id'] != null;
    
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildInfoCard('Dates', _buildDatesInfo(mission), Icons.calendar_today)),
            const SizedBox(width: 16),
            Expanded(child: _buildInfoCard('Budget & Tarifs', _buildBudgetInfo(mission), Icons.attach_money)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildInfoCard('Temps', _buildTimeInfo(mission), Icons.access_time)),
            const SizedBox(width: 16),
            Expanded(child: _buildInfoCard('Avancement', _buildTimeProgressInfo(mission), Icons.schedule)),
          ],
        ),
        // Afficher le partenaire si c'est un associé et qu'il y a un partenaire assigné
        if (isAssociate && hasPartner) ...[
          const SizedBox(height: 16),
          _buildInfoCard('Partenaire', _buildPartnerInfo(mission), Icons.person),
        ],
        if (mission['notes'] != null || mission['completion_notes'] != null) ...[
          const SizedBox(height: 16),
          _buildInfoCard('Notes', _buildNotesInfo(mission), Icons.note),
        ],
      ],
    );
  }
  
  Widget _buildPartnerInfo(Map<String, dynamic> mission) {
    final firstName = mission['partner_first_name'] as String?;
    final lastName = mission['partner_last_name'] as String?;
    final email = mission['partner_email'] as String?;
    final partnerId = mission['partner_id']?.toString();
    
    String partnerName = 'Non assigné';
    if (firstName != null && lastName != null) {
      partnerName = '$firstName $lastName';
    } else if (firstName != null) {
      partnerName = firstName;
    } else if (lastName != null) {
      partnerName = lastName;
    } else if (email != null) {
      partnerName = email;
    } else if (partnerId != null) {
      partnerName = 'Partenaire (ID: ${partnerId.substring(0, 8)}...)';
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom du partenaire en plus grand et visible
        Row(
          children: [
            Icon(Icons.person, size: 18, color: const Color(0xFF2A4B63)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                partnerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A4B63),
                ),
              ),
            ),
          ],
        ),
        if (email != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow('Email', email),
        ],
      ],
    );
  }

  Widget _buildInfoCard(String title, Widget content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2A4B63)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2A4B63),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  Widget _buildDatesInfo(Map<String, dynamic> mission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Créée le', mission['created_at'] != null 
            ? DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(mission['created_at'])) 
            : 'Non spécifié'),
        const SizedBox(height: 12),
        _buildInfoRow('Mise à jour', mission['updated_at'] != null 
            ? DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(mission['updated_at'])) 
            : 'Non spécifié'),
        const SizedBox(height: 12),
        _buildInfoRow('Date de début', mission['start_date'] != null 
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(mission['start_date'])) 
            : 'Non spécifié'),
        const SizedBox(height: 12),
        _buildInfoRow('Date de fin', mission['end_date'] != null 
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(mission['end_date'])) 
            : 'Non spécifié'),
      ],
    );
  }

  Widget _buildBudgetInfo(Map<String, dynamic> mission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Budget', mission['budget'] != null 
            ? '${mission['budget']} €' 
            : 'Non spécifié'),
        const SizedBox(height: 12),
        _buildInfoRow('Tarif journalier', mission['daily_rate'] != null 
            ? '${mission['daily_rate']} €/jour' 
            : 'Non spécifié'),
        const SizedBox(height: 12),
        _buildInfoRow('Priorité', mission['priority']?.toString().toUpperCase() ?? 'MOYENNE'),
      ],
    );
  }

  Widget _buildTimeInfo(Map<String, dynamic> mission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Jours estimés', mission['estimated_days'] != null 
            ? '${mission['estimated_days']} jours' 
            : 'Non spécifié'),
        const SizedBox(height: 12),
        _buildInfoRow('Jours travaillés', mission['worked_days'] != null 
            ? '${mission['worked_days']} jours' 
            : '0 jours'),
        const SizedBox(height: 12),
        _buildInfoRow('Heures estimées', mission['estimated_hours'] != null 
            ? '${mission['estimated_hours']} h' 
            : 'Non spécifié'),
        const SizedBox(height: 12),
        _buildInfoRow('Heures travaillées', mission['worked_hours'] != null 
            ? '${mission['worked_hours']} h' 
            : '0 h'),
      ],
    );
  }

  Widget _buildTimeProgressInfo(Map<String, dynamic> mission) {
    final now = DateTime.now();
    final startDate = mission['start_date'] != null 
        ? DateTime.parse(mission['start_date']) 
        : now;
    final endDate = mission['end_date'] != null 
        ? DateTime.parse(mission['end_date']) 
        : now.add(const Duration(days: 30));
    
    final totalDuration = endDate.difference(startDate).inDays;
    final elapsedDuration = now.difference(startDate).inDays;
    
    final percentage = totalDuration > 0 
        ? (elapsedDuration / totalDuration * 100).clamp(0, 100).toInt()
        : 0;
    
    final isLate = now.isAfter(endDate);
    final daysLate = isLate ? now.difference(endDate).inDays : 0;
    
    final Color barColor = isLate 
        ? const Color(0xFFD32F2F)
        : const Color(0xFF2A4B63);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Temps écoulé',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            Text(
              isLate 
                  ? 'En retard de $daysLate jour${daysLate > 1 ? 's' : ''}'
                  : '$percentage%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isLate ? const Color(0xFFD32F2F) : const Color(0xFF2A4B63),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: isLate ? 1.0 : percentage / 100,
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('dd/MM/yyyy').format(startDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(endDate),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNotesInfo(Map<String, dynamic> mission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (mission['notes'] != null) ...[
          const Text(
            'Notes générales:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            mission['notes'],
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          if (mission['completion_notes'] != null) const SizedBox(height: 16),
        ],
        if (mission['completion_notes'] != null) ...[
          const Text(
            'Notes de complétion:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            mission['completion_notes'],
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2A4B63),
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  // ============= ACTIONS SUR LES MISSIONS =============

  void _handleMissionAction(Map<String, dynamic> mission, String action) {
    switch (action) {
      case 'edit':
        _showEditMissionDialog(mission);
        break;
      case 'delete':
        _deleteMission(mission);
        break;
    }
  }

  void _showCreateMissionDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    String priority = 'medium';
    int? selectedCompanyId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle Mission'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la mission',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCompanyId,
                    decoration: const InputDecoration(
                      labelText: 'Société *',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Sélectionner une société'),
                    items: _companies.map((company) {
                      return DropdownMenuItem<int>(
                        value: company.id,
                        child: Text(
                          company.groupName != null
                              ? '${company.name} (${company.groupName})'
                              : company.name,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCompanyId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Veuillez sélectionner une société';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                startDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(startDate != null
                              ? DateFormat('dd/MM/yyyy').format(startDate!)
                              : 'Date de début'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                endDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(endDate != null
                              ? DateFormat('dd/MM/yyyy').format(endDate!)
                              : 'Date de fin'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priorité',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Basse')),
                      DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                      DropdownMenuItem(value: 'high', child: Text('Haute')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        priority = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le titre est requis')),
                  );
                  return;
                }

                if (selectedCompanyId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez sélectionner une société')),
                  );
                  return;
                }

                try {
                  await SupabaseService.createMission({
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'company_id': selectedCompanyId,
                    'start_date': startDate?.toIso8601String(),
                    'end_date': endDate?.toIso8601String(),
                    'priority': priority,
                    'status': 'pending',
                    'progress_status': 'à_assigner',
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mission créée avec succès')),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A4B63),
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMissionDialog(Map<String, dynamic> mission) {
    final titleController = TextEditingController(text: mission['title'] ?? mission['name']);
    final descriptionController = TextEditingController(text: mission['description']);
    DateTime? startDate = mission['start_date'] != null ? DateTime.parse(mission['start_date']) : null;
    DateTime? endDate = mission['end_date'] != null ? DateTime.parse(mission['end_date']) : null;
    String priority = mission['priority'] ?? 'medium';
    int? selectedCompanyId = mission['company_id'] != null 
        ? (mission['company_id'] is int ? mission['company_id'] : int.tryParse(mission['company_id'].toString()))
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier la Mission'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la mission',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: selectedCompanyId,
                    decoration: const InputDecoration(
                      labelText: 'Société *',
                      prefixIcon: Icon(Icons.business),
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Sélectionner une société'),
                    items: _companies.map((company) {
                      return DropdownMenuItem<int>(
                        value: company.id,
                        child: Text(
                          company.groupName != null
                              ? '${company.name} (${company.groupName})'
                              : company.name,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCompanyId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                startDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(startDate != null
                              ? DateFormat('dd/MM/yyyy').format(startDate!)
                              : 'Date de début'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? startDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                endDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(endDate != null
                              ? DateFormat('dd/MM/yyyy').format(endDate!)
                              : 'Date de fin'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: const InputDecoration(
                      labelText: 'Priorité',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Basse')),
                      DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                      DropdownMenuItem(value: 'high', child: Text('Haute')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        priority = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedCompanyId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez sélectionner une société')),
                  );
                  return;
                }

                try {
                  await SupabaseService.client
                      .from('missions')
                      .update({
                        'title': titleController.text,
                        'description': descriptionController.text,
                        'company_id': selectedCompanyId,
                        'start_date': startDate?.toIso8601String(),
                        'end_date': endDate?.toIso8601String(),
                        'priority': priority,
                      })
                      .eq('id', mission['id']);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mission mise à jour avec succès')),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A4B63),
              ),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMission(Map<String, dynamic> mission) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la mission'),
        content: Text('Êtes-vous sûr de vouloir supprimer la mission "${mission['title'] ?? mission['name']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await SupabaseService.client
                    .from('missions')
                    .delete()
                    .eq('id', mission['id']);

                if (mounted) {
                  Navigator.pop(context);
                  _backToGrid();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mission supprimée avec succès')),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
