import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../widgets/messaging_button.dart';
import '../shared/calendar_page.dart';
import '../../config/app_theme.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> _missions = [];
  String? _statusFilter; // null = toutes
  int _sortColumnIndex = 0;
  bool _sortAscending = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMissions();
    _loadEvents();
  }

  Future<void> _loadMissions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Vérifier l'utilisateur connecté
      final currentUser = SupabaseService.currentUser;
      final currentRole = SupabaseService.currentUserRole;
      debugPrint('👤 Utilisateur connecté: ${currentUser?.id}');
      debugPrint('🎭 Rôle: $currentRole');
      
      final response = await SupabaseService.getMissionsWithStatus();
      debugPrint('📊 Missions récupérées depuis Supabase: ${response.length}');
      
      if (response.isNotEmpty) {
        debugPrint('📋 Première mission: ${response.first}');
        
        // Vérifier si progress_status existe
        if (response.first.containsKey('progress_status')) {
          debugPrint('✅ Colonne progress_status existe');
          debugPrint('🔍 Valeur: ${response.first['progress_status']}');
        } else {
          debugPrint('❌ Colonne progress_status MANQUANTE!');
          debugPrint('📝 Colonnes disponibles: ${response.first.keys.toList()}');
        }
        
        // Compter par statut
        final parStatut = <String, int>{};
        for (var mission in response) {
          final status = mission['progress_status']?.toString() ?? 'null';
          parStatut[status] = (parStatut[status] ?? 0) + 1;
        }
        debugPrint('📈 Distribution des statuts: $parStatut');
        
        // Afficher quelques exemples de missions
        debugPrint('📝 Exemples de missions:');
        for (var i = 0; i < response.length && i < 3; i++) {
          final m = response[i];
          debugPrint('  - ${m['title']} (progress_status: ${m['progress_status']})');
        }
      } else {
        debugPrint('⚠️ AUCUNE MISSION récupérée depuis Supabase!');
        debugPrint('🔍 Cela peut être dû à:');
        debugPrint('   1. Aucune mission dans la base');
        debugPrint('   2. Problème de permissions RLS');
        debugPrint('   3. Problème de company_id');
      }
      
      if (mounted) {
        setState(() {
          _missions = response.map((mission) => mission).toList();
          _isLoading = false;
        });
        debugPrint('✅ ${_missions.length} missions chargées dans le state');
        
        // Compter combien de missions par colonne
        final aAssigner = _missions.where((m) => m['progress_status'] == 'à_assigner').length;
        final enCours = _missions.where((m) => m['progress_status'] == 'en_cours').length;
        final fait = _missions.where((m) => m['progress_status'] == 'fait').length;
        debugPrint('📊 Répartition dans l\'UI:');
        debugPrint('   - À assigner: $aAssigner');
        debugPrint('   - En cours: $enCours');
        debugPrint('   - Fait: $fait');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ ERREUR lors du chargement des missions: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadEvents() async {
    // Cette méthode charge les événements du calendrier
    // Pour l'instant, elle est vide car nous n'avons pas encore implémenté le calendrier
    debugPrint('Chargement des événements du calendrier...');
    // Implémentation à venir
  }

  Future<void> _updateMissionStatus(Map<String, dynamic> missionData, String newProgressStatus) async {
    if (!mounted) return;
    
    try {
      final success = await SupabaseService.updateMissionProgressStatus(missionData['id'], newProgressStatus);
      if (success) {
        await _loadMissions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Statut mis à jour vers: ${_getStatusDisplayName(newProgressStatus)}'),
              backgroundColor: const Color(0xFF2E7D5B),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du statut: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status) {
      case 'à_assigner':
        return 'À assigner';
      case 'en_cours':
        return 'En cours';
      case 'fait':
        return 'Fait';
      default:
        return status;
    }
  }

  Future<void> _showAddMissionDialog() async {
    if (!mounted) return;
    final dialogContext = context;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final dueDateController = TextEditingController();
    final projectNameController = TextEditingController();
    final projectDescriptionController = TextEditingController();
    DateTime? selectedDate;
    String? selectedProject;
    String? selectedPartnerId;
    bool isCreatingNewProject = false;

    try {
      await showDialog(
        context: dialogContext,
        // Un clic hors du dialog ne doit pas jeter la saisie en cours
        barrierDismissible: false,
        builder: (BuildContext context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Nouvelle mission'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<List<dynamic>>(
                          future: SupabaseService.client
                            .from('projects')
                            .select()
                            .order('name'),
                          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                            if (snapshot.hasError) {
                              return Text('Erreur: ${snapshot.error}');
                            }

                            final projects = List<Map<String, dynamic>>.from(snapshot.data ?? []);

                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Mission',
                                border: OutlineInputBorder(),
                              ),
                              value: selectedProject,
                              items: projects.map((project) => DropdownMenuItem<String>(
                                value: project['id'].toString(),
                                child: Text(project['name'] as String),
                              )).toList(),
                              onChanged: isCreatingNewProject ? null : (String? value) {
                                setState(() {
                                  selectedProject = value;
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          isCreatingNewProject ? Icons.close : Icons.add_circle,
                          color: const Color(0xFF3E5C76),
                        ),
                        onPressed: () {
                          setState(() {
                            isCreatingNewProject = !isCreatingNewProject;
                            if (!isCreatingNewProject) {
                              projectNameController.clear();
                              projectDescriptionController.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (isCreatingNewProject) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: projectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom de la mission',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: projectDescriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description de la mission',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la mission',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description de la mission',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                          dueDateController.text = DateFormat('dd/MM/yyyy').format(date);
                        });
                      }
                    },
                    child: IgnorePointer(
                      child: TextField(
                        controller: dueDateController,
                        decoration: const InputDecoration(
                          labelText: 'Date d\'échéance',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: SupabaseService.getPartners(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      
                      if (snapshot.hasError) {
                        return Text('Erreur: ${snapshot.error}');
                      }
                      
                      final partners = snapshot.data ?? [];
                      
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Attribuer à un partenaire',
                          border: OutlineInputBorder(),
                          helperText: 'Facultatif - Laissez vide pour attribution automatique',
                        ),
                        value: selectedPartnerId,
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Attribution automatique'),
                          ),
                          ...partners.map((partner) => DropdownMenuItem<String>(
                            value: partner['user_id'],
                            child: Text(partner['user_email'] ?? 'Partenaire sans email'),
                          )).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedPartnerId = value;
                          });
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty || selectedDate == null || 
                      (isCreatingNewProject && projectNameController.text.isEmpty) ||
                      (!isCreatingNewProject && selectedProject == null)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                      );
                    }
                    return;
                  }

                  try {
                    if (isCreatingNewProject) {
                      await SupabaseService.client
                          .from('projects')
                          .insert({
                            'name': projectNameController.text,
                            'description': projectDescriptionController.text,
                            'status': 'active',
                            'start_date': DateTime.now().toIso8601String(),
                            'end_date': selectedDate!.toIso8601String(),
                            'created_at': DateTime.now().toIso8601String(),
                            'updated_at': DateTime.now().toIso8601String(),
                          });
                    }

                    if (selectedPartnerId == null) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Veuillez sélectionner un partenaire')),
                        );
                      }
                      return;
                    }

                    await SupabaseService.createMission({
                      'title': titleController.text,
                      'description': descriptionController.text,
                      'assigned_to': selectedPartnerId,
                      'due_date': selectedDate?.toIso8601String(),
                      'status': 'pending',
                      'progress_status': 'à_assigner',
                      'priority': 'medium',
                    });
                    
                    if (!mounted) return;
                    Navigator.pop(context);
                    await _loadMissions();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isCreatingNewProject 
                              ? 'Mission créée avec succès' 
                              : 'Mission créée avec succès'
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: ${e.toString()}')),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3E5C76),
                ),
                child: const Text(
                  'Ajouter',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      titleController.dispose();
      descriptionController.dispose();
      dueDateController.dispose();
      projectNameController.dispose();
      projectDescriptionController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Le SideMenu et TopBar sont maintenant gérés par DesktopShell
    // On retourne uniquement le contenu principal
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildDashboardContent(),
      floatingActionButton: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 150), // Limiter la hauteur
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MessagingFloatingButton(
              backgroundColor: AppTheme.colors.secondary,
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'dashboard_fab',
              onPressed: _showAddMissionDialog,
              backgroundColor: AppTheme.colors.secondary,
              foregroundColor: Colors.white,
              elevation: 1,
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKpiRow(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTasksSection(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // KPI (calculés depuis les missions chargées)
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildKpiRow() {
    final int toAssign =
        _missions.where((m) => m['progress_status'] == 'à_assigner').length;
    final int inProgress =
        _missions.where((m) => m['progress_status'] == 'en_cours').length;
    final int done =
        _missions.where((m) => m['progress_status'] == 'fait').length;

    // Échéances sous 7 jours (missions non terminées)
    final now = DateTime.now();
    final int dueSoon = _missions.where((m) {
      if (m['progress_status'] == 'fait') return false;
      final raw = m['end_date'] ?? m['due_date'];
      if (raw == null) return false;
      final due = DateTime.tryParse(raw.toString());
      if (due == null) return false;
      return due.difference(now).inDays <= 7;
    }).length;

    return Row(
      children: [
        _buildKpiCard(
          label: 'En cours',
          value: '$inProgress',
          icon: Icons.play_circle_outline,
          color: AppTheme.colors.statusInProgress,
          onTap: () => _toggleStatusFilter('en_cours'),
        ),
        const SizedBox(width: 12),
        _buildKpiCard(
          label: 'À assigner',
          value: '$toAssign',
          icon: Icons.assignment_ind_outlined,
          color: AppTheme.colors.statusPending,
          onTap: () => _toggleStatusFilter('à_assigner'),
        ),
        const SizedBox(width: 12),
        _buildKpiCard(
          label: 'Terminées',
          value: '$done',
          icon: Icons.check_circle_outline,
          color: AppTheme.colors.statusCompleted,
          onTap: () => _toggleStatusFilter('fait'),
        ),
        const SizedBox(width: 12),
        _buildKpiCard(
          label: 'Échéance sous 7 jours',
          value: '$dueSoon',
          icon: Icons.schedule_outlined,
          color: dueSoon > 0
              ? AppTheme.colors.warning
              : AppTheme.colors.textSecondary,
        ),
      ],
    );
  }

  /// Un clic filtre la table, un second clic sur le même KPI annule le filtre.
  void _toggleStatusFilter(String status) {
    setState(() {
      _statusFilter = _statusFilter == status ? null : status;
    });
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: Material(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radius.medium),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
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
                Expanded(
                  child: Column(
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TABLE DES MISSIONS (remplace l'ancien kanban drag & drop)
  // ══════════════════════════════════════════════════════════════════════

  static const _statusOptions = ['à_assigner', 'en_cours', 'fait'];

  Color _statusColor(String status) {
    switch (status) {
      case 'en_cours':
        return AppTheme.colors.statusInProgress;
      case 'fait':
        return AppTheme.colors.statusCompleted;
      default:
        // à_assigner : en attente
        return AppTheme.colors.statusPending;
    }
  }

  List<Map<String, dynamic>> get _visibleMissions {
    var list = _statusFilter == null
        ? List<Map<String, dynamic>>.from(_missions)
        : _missions
            .where((m) => (m['progress_status'] ?? 'à_assigner') == _statusFilter)
            .toList();
    list.sort((a, b) {
      int cmp;
      switch (_sortColumnIndex) {
        case 1:
          cmp = (a['progress_status'] ?? '')
              .toString()
              .compareTo((b['progress_status'] ?? '').toString());
          break;
        case 2:
          cmp = (a['end_date'] ?? a['due_date'] ?? '')
              .toString()
              .compareTo((b['end_date'] ?? b['due_date'] ?? '').toString());
          break;
        default:
          cmp = (a['title'] ?? '')
              .toString()
              .toLowerCase()
              .compareTo((b['title'] ?? '').toString().toLowerCase());
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  Widget _buildTasksSection() {
    final missions = _visibleMissions;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête : titre + filtres + ajout
            Row(
              children: [
                const Text(
                  'Missions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2530),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${missions.length}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const Spacer(),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Toutes'),
                      selected: _statusFilter == null,
                      onSelected: (_) => setState(() => _statusFilter = null),
                    ),
                    ..._statusOptions.map((s) => ChoiceChip(
                          label: Text(_getStatusDisplayName(s)),
                          selected: _statusFilter == s,
                          selectedColor: _statusColor(s).withOpacity(0.15),
                          onSelected: (_) => setState(() => _statusFilter = s),
                        )),
                  ],
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _showAddMissionDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle mission'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (missions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        _statusFilter == null
                            ? 'Aucune mission pour le moment'
                            : 'Aucune mission « ${_getStatusDisplayName(_statusFilter!)} »',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: DataTable(
                  sortColumnIndex: _sortColumnIndex,
                  sortAscending: _sortAscending,
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2530),
                    fontSize: 13,
                  ),
                  columns: [
                    DataColumn(
                      label: const Text('Mission'),
                      onSort: (i, asc) => setState(() {
                        _sortColumnIndex = i;
                        _sortAscending = asc;
                      }),
                    ),
                    DataColumn(
                      label: const Text('Statut'),
                      onSort: (i, asc) => setState(() {
                        _sortColumnIndex = i;
                        _sortAscending = asc;
                      }),
                    ),
                    DataColumn(
                      label: const Text('Échéance'),
                      onSort: (i, asc) => setState(() {
                        _sortColumnIndex = i;
                        _sortAscending = asc;
                      }),
                    ),
                    const DataColumn(label: Text('')),
                  ],
                  rows: missions.map(_buildMissionRow).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Échéance colorée : rouge si dépassée, orange si sous 7 jours
  /// (uniquement pour les missions non terminées).
  Widget _buildDueDateLabel(DateTime? dueDate, String status) {
    if (dueDate == null) {
      return Text('—',
          style: TextStyle(fontSize: 13, color: AppTheme.colors.textSecondary));
    }

    final bool isDone = status == 'fait';
    final int daysLeft = dueDate.difference(DateTime.now()).inDays;

    Color color = AppTheme.colors.textSecondary;
    IconData? icon;
    if (!isDone && daysLeft < 0) {
      color = AppTheme.colors.error;
      icon = Icons.warning_amber_outlined;
    } else if (!isDone && daysLeft <= 7) {
      color = AppTheme.colors.warning;
      icon = Icons.schedule_outlined;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          DateFormat('dd/MM/yyyy').format(dueDate),
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: icon != null ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  DataRow _buildMissionRow(Map<String, dynamic> mission) {
    final title = mission['title']?.toString() ?? 'Sans titre';
    final description = mission['description']?.toString() ?? '';
    final status = mission['progress_status']?.toString() ?? 'à_assigner';
    final rawDate = mission['end_date'] ?? mission['due_date'];
    final dueDate = rawDate != null ? DateTime.tryParse(rawDate.toString()) : null;

    return DataRow(
      cells: [
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (description.isNotEmpty)
                  Text(description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          onTap: () => Navigator.pushNamed(context, '/mission_detail',
              arguments: mission['id']?.toString()),
        ),
        // Statut modifiable directement depuis la table
        DataCell(
          PopupMenuButton<String>(
            tooltip: 'Changer le statut',
            onSelected: (value) => _updateMissionStatus(mission, value),
            itemBuilder: (context) => _statusOptions
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: _statusColor(s)),
                          const SizedBox(width: 8),
                          Text(_getStatusDisplayName(s)),
                        ],
                      ),
                    ))
                .toList(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 10, color: _statusColor(status)),
                  const SizedBox(width: 6),
                  Text(
                    _getStatusDisplayName(status),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _statusColor(status),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.expand_more, size: 14, color: _statusColor(status)),
                ],
              ),
            ),
          ),
        ),
        DataCell(_buildDueDateLabel(dueDate, status)),
        DataCell(
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            tooltip: 'Voir la mission',
            onPressed: () => Navigator.pushNamed(context, '/mission_detail',
                arguments: mission['id']?.toString()),
          ),
        ),
      ],
    );
  }
}

// ✅ Mini-planning corrigé pour éviter l'overflow
class CalendarMiniWidget extends StatefulWidget {
  final bool showText;
  const CalendarMiniWidget({super.key, required this.showText});

  @override
  CalendarMiniWidgetState createState() => CalendarMiniWidgetState();
}

class CalendarMiniWidgetState extends State<CalendarMiniWidget> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final List<String> months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    maxWidth: 36,
                  ),
                  icon: const Icon(Icons.calendar_month, color: Color(0xFF1A2530), size: 20),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CalendarPage()),
                    );
                  },
                ),
                if (widget.showText)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Text(
                    "Planning",
                    style: TextStyle(
                        fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2530),
                      ),
                    ),
                  ),
              ],
            ),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    value: months[(selectedMonth - 1).clamp(0, 11)],
                    onChanged: (String? newValue) {
                      if (newValue != null && mounted) {
                        setState(() {
                          selectedMonth = months.indexOf(newValue) + 1;
                        });
                      }
                    },
                    dropdownColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                    items: months.map((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Flexible(
          fit: FlexFit.loose,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: index % 7 == 0 ? Colors.grey.shade200 : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Center(
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class TimesheetDialog extends StatefulWidget {
  final DateTime selectedDate;

  const TimesheetDialog({
    Key? key,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<TimesheetDialog> createState() => _TimesheetDialogState();
}

class _TimesheetDialogState extends State<TimesheetDialog> {
  TimeOfDay startTime = TimeOfDay.now();
  TimeOfDay endTime = TimeOfDay.now();
  String? selectedProject;
  String? selectedTask;
  final descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: SupabaseService.client
          .from('projects')
          .select()
          .order('name'),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return AlertDialog(
            content: Center(
              child: Text('Erreur: ${snapshot.error}'),
            ),
          );
        }

        final projects = List<Map<String, dynamic>>.from(snapshot.data ?? []);

        return AlertDialog(
          title: Text('Saisie des heures - ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Mission',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedProject,
                  items: projects.map((project) => DropdownMenuItem<String>(
                    value: project['id'].toString(),
                    child: Text(project['name'] as String),
                  )).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedProject = value;
                      selectedTask = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                if (selectedProject?.isNotEmpty == true)
                  FutureBuilder<List<dynamic>>(
                    future: SupabaseService.client
                        .from('missions')
                        .select()
                        .eq('project_id', selectedProject!)
                        .order('title'),
                    builder: (context, AsyncSnapshot<List<dynamic>> taskSnapshot) {
                      final missions = List<Map<String, dynamic>>.from(taskSnapshot.data ?? []);
                      
                      return DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Mission',
                          border: OutlineInputBorder(),
                        ),
                        value: selectedTask,
                        items: missions.map((mission) => DropdownMenuItem<String>(
                          value: mission['id'].toString(),
                          child: Text(mission['title'] as String),
                        )).toList(),
                        onChanged: (String? value) {
                          setState(() => selectedTask = value);
                        },
                      );
                    },
                  ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: startTime,
                          );
                          if (picked != null) {
                            setState(() => startTime = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Début',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(startTime.format(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final TimeOfDay? picked = await showTimePicker(
                            context: context,
                            initialTime: endTime,
                          );
                          if (picked != null) {
                            setState(() => endTime = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Fin',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(endTime.format(context)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Description de l\'activité',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedProject != null && selectedTask != null) {
                  final startDateTime = DateTime(
                    widget.selectedDate.year,
                    widget.selectedDate.month,
                    widget.selectedDate.day,
                    startTime.hour,
                    startTime.minute,
                  );
                  final endDateTime = DateTime(
                    widget.selectedDate.year,
                    widget.selectedDate.month,
                    widget.selectedDate.day,
                    endTime.hour,
                    endTime.minute,
                  );
                  
                  if (endDateTime.isBefore(startDateTime)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('L\'heure de fin doit être après l\'heure de début'),
                      ),
                    );
                    return;
                  }

                  final hours = endDateTime.difference(startDateTime).inMinutes / 60.0;
                  
                  if (hours <= 0 || hours > 24) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Le nombre d\'heures doit être entre 0 et 24'),
                      ),
                    );
                    return;
                  }

                  try {
                    // Gérer l'ID de mission de manière flexible
                    dynamic missionIdValue = selectedTask!;
                    try {
                      missionIdValue = int.parse(selectedTask!);
                    } catch (e) {
                      // Si la conversion échoue, c'est probablement un UUID
                      debugPrint('Task ID est probablement un UUID: $selectedTask');
                    }

                    await SupabaseService.client
                        .from('timesheet_entries')
                        .insert({
                      'user_id': SupabaseService.currentUser!.id,
                      'mission_id': missionIdValue, // Utiliser la valeur appropriée
                      'date': widget.selectedDate.toIso8601String(),
                      'hours': hours,
                      'description': descriptionController.text,
                      'status': 'pending', // Ajouter le status requis
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Heures enregistrées avec succès')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3E5C76),
              ),
              child: const Text(
                'Enregistrer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}