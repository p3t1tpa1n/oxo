import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../widgets/load_error_view.dart';
import '../../widgets/app_form.dart';
import '../../models/company.dart';
import '../../models/user_role.dart';
import '../../config/app_theme.dart';

class ProjectsPage extends StatefulWidget {
  /// Si fourni, ouvre directement la vue détail de cette mission
  /// (utilisé par les routes /mission_detail et /project_detail sur desktop).
  final String? initialMissionId;

  const ProjectsPage({super.key, this.initialMissionId});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _missions = [];
  List<Map<String, dynamic>> _filteredMissions = [];
  List<Map<String, dynamic>> _partners = [];
  List<Company> _companies = [];
  bool _isLoading = true;
  bool _loadError = false;
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
        _loadError = false;
      });

      _applyFiltersAndSort();

      // Ouverture directe du détail si un id de mission a été passé en route
      if (widget.initialMissionId != null && _currentView == 'grid') {
        final target = _missions.firstWhere(
          (m) => m['id']?.toString() == widget.initialMissionId,
          orElse: () => <String, dynamic>{},
        );
        if (target.isNotEmpty) {
          _showMissionDetails(target);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      setState(() {
        _isLoading = false;
        _loadError = true;
      });
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
          : _loadError
              ? LoadErrorView(
                  message: 'Impossible de charger les missions.',
                  onRetry: _loadData,
                )
              : _currentView == 'grid'
                  ? _buildMissionsGridView()
                  : _buildMissionDetailView(),
      floatingActionButton: _currentView == 'grid' && SupabaseService.currentUserRole != UserRole.partenaire
          ? FloatingActionButton.extended(
              heroTag: 'fab_projects',
              onPressed: _showCreateMissionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle mission'),
              backgroundColor: AppTheme.colors.primary,
              foregroundColor: Colors.white,
              elevation: 1,
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
                      prefixIcon: Icon(Icons.search,
                          size: 20, color: AppTheme.colors.textSecondary),
                      isDense: true,
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
            size: 64,
            color: AppTheme.colors.textDisabled,
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune mission',
            style: AppTheme.typography.h3
                .copyWith(color: AppTheme.colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Créez votre première mission pour commencer.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsGrid() {
    // Grille responsive : le nombre de colonnes s'adapte à la largeur
    // de la fenêtre au lieu d'être figé à 3.
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 380,
        childAspectRatio: 1.35,
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
        progressStatusColor = AppTheme.colors.statusPending;
        badgeText = 'Nouvelle proposition';
      } else if (isProposal && proposalStatus == 'accepted') {
        // Proposition acceptée
        progressStatusLabel = 'Acceptée';
        progressStatusColor = AppTheme.colors.statusCompleted;
        badgeText = 'Proposition acceptée';
      } else if (isAssigned || (isProposal && proposalStatus == 'accepted')) {
        // Mission assignée
        final status = mission['progress_status']?.toString() ?? 'en_cours';
        progressStatusLabel = _getProgressStatusLabel(status);
        progressStatusColor = _getProgressStatusColor(status);
        badgeText = null;
      } else {
        progressStatusLabel = 'En attente';
        progressStatusColor = AppTheme.colors.statusCancelled;
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
      child: InkWell(
        onTap: () => _showMissionDetails(mission),
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bandeau proposition (partenaires)
              if (badgeText != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: progressStatusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: progressStatusColor.withOpacity(0.3),
                        width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notifications_active_outlined,
                          size: 14, color: progressStatusColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: progressStatusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      mission['title'] ?? mission['name'] ?? 'Mission sans nom',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.colors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: progressStatusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: progressStatusColor),
                        const SizedBox(width: 5),
                        Text(
                          progressStatusLabel,
                          style: TextStyle(
                            color: progressStatusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (mission['description'] != null)
                Expanded(
                  child: Text(
                    mission['description'],
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.colors.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              const Spacer(),
              Divider(color: AppTheme.colors.borderLight),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (mission['start_date'] != null)
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 13, color: AppTheme.colors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy').format(
                              DateTime.parse(mission['start_date'])),
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.colors.textSecondary),
                        ),
                      ],
                    ),
                  if (mission['priority'] != null)
                    _buildPriorityChip(mission['priority'].toString()),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    final Color color;
    final String label;
    switch (priority.toLowerCase()) {
      case 'high':
      case 'haute':
        color = AppTheme.colors.error;
        label = 'Haute';
        break;
      case 'low':
      case 'basse':
        color = AppTheme.colors.textSecondary;
        label = 'Basse';
        break;
      default:
        color = AppTheme.colors.warning;
        label = 'Moyenne';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
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
        return AppTheme.colors.statusPending;
      case 'en_cours':
        return AppTheme.colors.statusInProgress;
      case 'fait':
        return AppTheme.colors.statusCompleted;
      default:
        return AppTheme.colors.statusCancelled;
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
        return AppTheme.colors.statusPending;
      case 'accepted':
        return AppTheme.colors.statusCompleted;
      case 'rejected':
        return AppTheme.colors.error;
      default:
        return AppTheme.colors.statusCancelled;
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline,
                    size: 20, color: AppTheme.colors.statusPending),
                const SizedBox(width: 8),
                Text('Proposition de mission', style: AppTheme.typography.h4),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vous avez reçu une proposition de mission. Acceptez-la ou refusez-la.',
              style: AppTheme.typography.bodyMedium
                  .copyWith(color: AppTheme.colors.textSecondary),
            ),
            if (_selectedMission!['proposed_at'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Proposée le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(_selectedMission!['proposed_at'].toString()))}',
                style: AppTheme.typography.caption,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _rejectMissionProposal(),
                  icon: Icon(Icons.close, size: 18, color: AppTheme.colors.error),
                  label: Text(
                    'Refuser',
                    style: TextStyle(color: AppTheme.colors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppTheme.colors.error.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _acceptMissionProposal(),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colors.success,
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
          SnackBar(
            content: const Text('Mission acceptée'),
            backgroundColor: AppTheme.colors.success,
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colors.error,
              foregroundColor: Colors.white,
            ),
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
            backgroundColor: const Color(0xFFB07B2E),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            IconButton(
              onPressed: _backToGrid,
              icon: Icon(Icons.arrow_back, color: AppTheme.colors.primary),
              tooltip: 'Retour aux missions',
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mission['title'] ?? mission['name'] ?? 'Mission sans nom',
                    style: AppTheme.typography.h2,
                  ),
                  if (mission['description'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      mission['description'],
                      style: AppTheme.typography.bodyMedium
                          .copyWith(color: AppTheme.colors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            // Pastille de statut, visible quel que soit le statut
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: progressStatusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 8, color: progressStatusColor),
                  const SizedBox(width: 6),
                  Text(
                    progressStatusLabel,
                    style: TextStyle(
                      color: progressStatusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMissionAction(mission, value),
              icon: Icon(Icons.more_vert, color: AppTheme.colors.primary),
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
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.colors.secondary.withOpacity(0.15),
              child: Icon(Icons.person_outline,
                  size: 16, color: AppTheme.colors.secondary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                partnerName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colors.textPrimary,
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
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppTheme.colors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radius.small),
                ),
                child: Icon(icon, size: 16, color: AppTheme.colors.secondary),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.colors.textPrimary,
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
    
    final Color barColor =
        isLate ? AppTheme.colors.error : AppTheme.colors.secondary;

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
                color: AppTheme.colors.textSecondary,
              ),
            ),
            Text(
              isLate
                  ? 'En retard de $daysLate jour${daysLate > 1 ? 's' : ''}'
                  : '$percentage %',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isLate
                    ? AppTheme.colors.error
                    : AppTheme.colors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: isLate ? 1.0 : percentage / 100,
            minHeight: 6,
            backgroundColor: AppTheme.colors.borderLight,
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
                color: AppTheme.colors.textSecondary,
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(endDate),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.colors.textSecondary,
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
            'Notes générales',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            mission['notes'],
            style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppTheme.colors.textSecondary),
          ),
          if (mission['completion_notes'] != null) const SizedBox(height: 16),
        ],
        if (mission['completion_notes'] != null) ...[
          const Text(
            'Notes de complétion',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            mission['completion_notes'],
            style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppTheme.colors.textSecondary),
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
              fontSize: 13,
              color: AppTheme.colors.textSecondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.colors.textPrimary,
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
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    String priority = 'medium';
    int? selectedCompanyId;

    showDialog(
      context: context,
      // Un clic hors du dialog ne doit pas jeter la saisie en cours
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => Form(
          key: formKey,
          child: AppFormDialog(
            title: 'Nouvelle mission',
            subtitle: 'Les champs marqués * sont obligatoires.',
            submitLabel: 'Créer la mission',
            onSubmit: () async {
              if (!formKey.currentState!.validate()) return;
              try {
                await SupabaseService.createMission({
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'company_id': selectedCompanyId,
                  'start_date': startDate?.toIso8601String(),
                  'end_date': endDate?.toIso8601String(),
                  'priority': priority,
                  'status': 'pending',
                  'progress_status': 'à_assigner',
                });

                if (mounted) {
                  Navigator.pop(dialogContext);
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
            children: [
              AppTextField(
                controller: titleController,
                label: 'Titre de la mission',
                icon: Icons.assignment_outlined,
                required: true,
              ),
              AppDropdown<int>(
                value: selectedCompanyId,
                label: 'Société',
                icon: Icons.business,
                required: true,
                items: _companies
                    .map((company) => DropdownMenuItem<int>(
                          value: company.id,
                          child: Text(
                            company.groupName != null
                                ? '${company.name} (${company.groupName})'
                                : company.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ))
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => selectedCompanyId = value),
              ),
              AppTextField(
                controller: descriptionController,
                label: 'Description',
                icon: Icons.notes,
                maxLines: 3,
              ),
              Row(
                children: [
                  Expanded(
                    child: AppDateField(
                      value: startDate,
                      label: 'Début',
                      firstDate: DateTime.now(),
                      onChanged: (d) => setDialogState(() {
                        startDate = d;
                        if (endDate != null && endDate!.isBefore(d)) {
                          endDate = null;
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AppDateField(
                      value: endDate,
                      label: 'Fin',
                      firstDate: startDate ?? DateTime.now(),
                      onChanged: (d) => setDialogState(() => endDate = d),
                    ),
                  ),
                ],
              ),
              AppDropdown<String>(
                value: priority,
                label: 'Priorité',
                icon: Icons.flag_outlined,
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Basse')),
                  DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                  DropdownMenuItem(value: 'high', child: Text('Haute')),
                ],
                onChanged: (value) =>
                    setDialogState(() => priority = value ?? 'medium'),
              ),
            ],
          ),
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
      // Un clic hors du dialog ne doit pas jeter les modifications en cours
      barrierDismissible: false,
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
                backgroundColor: AppTheme.colors.primary,
                foregroundColor: Colors.white,
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
