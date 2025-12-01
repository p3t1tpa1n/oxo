import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';
import '../../utils/progress_utils.dart';
import '../../models/user_role.dart';

class IOSProjectDetailPage extends StatefulWidget {
  final String projectId;
  
  const IOSProjectDetailPage({
    super.key,
    required this.projectId,
  });

  @override
  State<IOSProjectDetailPage> createState() => _IOSProjectDetailPageState();
}

class _IOSProjectDetailPageState extends State<IOSProjectDetailPage> {
  Map<String, dynamic>? _project;
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  bool _isAssigning = false;
  String? _error;
  UserRole? _userRole;

  @override
  void initState() {
    super.initState();
    _loadProjectDetails();
  }

  Future<void> _loadProjectDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Charger le rôle de l'utilisateur
      _userRole = SupabaseService.currentUserRole;

      // Charger les détails de la mission
      final missions = await SupabaseService.getCompanyMissions();
      debugPrint('Recherche mission ID: ${widget.projectId}');
      debugPrint('Missions disponibles: ${missions.map((m) => 'ID: ${m['id']}, Title: ${m['title']}').toList()}');
      
      _project = missions.firstWhere(
        (m) => m['id'].toString() == widget.projectId,
        orElse: () {
          debugPrint('Projet non trouvé avec ID: ${widget.projectId}');
          return <String, dynamic>{};
        },
      );
      
      if (_project!.isNotEmpty) {
        debugPrint('Projet trouvé: ${_project!['name'] ?? _project!['title']}');
        debugPrint('Assigned to: ${_project!['assigned_to']}');
        debugPrint('Partner ID: ${_project!['partner_id']}');
      }

      // Charger les tâches du projet
      final allTasks = await SupabaseService.getCompanyMissions();
      _tasks = allTasks.where((task) => 
        task['mission_id']?.toString() == widget.projectId
      ).toList();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Erreur lors du chargement: $e';
      });
    }
  }

  /// Vérifie si la mission n'est assignée à personne
  bool get _isMissionUnassigned {
    if (_project == null) return false;
    final assignedTo = _project!['assigned_to'];
    final partnerId = _project!['partner_id'];
    return (assignedTo == null || assignedTo.toString().isEmpty) &&
           (partnerId == null || partnerId.toString().isEmpty);
  }

  /// Vérifie si l'utilisateur est un associé
  bool get _isAssociate {
    return _userRole == UserRole.associe;
  }

  /// S'auto-assigner la mission
  Future<void> _assignToMyself() async {
    if (_project == null) return;

    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('S\'assigner cette mission'),
        content: Text(
          'Voulez-vous vous assigner la mission "${_project!['title'] ?? _project!['name']}" ?',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Confirmer'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isAssigning = true);

    try {
      final currentUserId = SupabaseService.currentUser?.id;
      if (currentUserId == null) throw Exception('Utilisateur non connecté');

      // Mettre à jour la mission avec assigned_to = currentUserId
      await SupabaseService.client
          .from('missions')
          .update({
            'assigned_to': currentUserId,
            'progress_status': 'en_cours',
            'status': 'in_progress',
          })
          .eq('id', widget.projectId);

      if (mounted) {
        // Afficher un message de succès
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Succès'),
            content: const Text('La mission vous a été assignée avec succès !'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );

        // Recharger les données
        await _loadProjectDetails();
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'assignation: $e');
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erreur'),
            content: Text('Impossible de s\'assigner la mission: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: _project?['name'] ?? 'Détails du projet',
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.chevron_left, size: 18),
              const SizedBox(width: 4),
              Text(
                'Retour',
                style: IOSTheme.body.copyWith(color: IOSTheme.primaryBlue),
              ),
            ],
          ),
        ),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showProjectActions,
            child: const Icon(CupertinoIcons.ellipsis, color: IOSTheme.primaryBlue),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _error != null
              ? _buildErrorState()
              : _project == null || _project!.isEmpty
                  ? _buildNotFoundState()
                  : RefreshIndicator(
                      onRefresh: _loadProjectDetails,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildProjectHeader(),
                            const SizedBox(height: 24),
                            _buildProjectStats(),
                            const SizedBox(height: 24),
                            _buildTasksList(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_triangle,
            size: 64,
            color: IOSTheme.systemRed,
          ),
          const SizedBox(height: 16),
          Text('Erreur', style: IOSTheme.title2),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error!,
              style: IOSTheme.body,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(
            onPressed: _loadProjectDetails,
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.folder,
            size: 64,
            color: IOSTheme.systemGray,
          ),
          const SizedBox(height: 16),
          Text('Projet non trouvé', style: IOSTheme.title2),
          const SizedBox(height: 8),
          Text(
            'Ce projet n\'existe pas ou vous n\'y avez pas accès.',
            style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    final status = _project!['status'] ?? 'actif';
    final progressStatus = _project!['progress_status'] ?? 'à_assigner';
    final statusColor = IOSTheme.getStatusColor(status);
    final clientName = _project!['client_name'] ?? _project!['company_name'] ?? 'Aucun client';
    final title = _project!['title'] ?? _project!['name'] ?? 'Projet sans titre';
    
    // Informations sur l'assignation
    final assignedToFirstName = _project!['assigned_to_first_name'];
    final assignedToLastName = _project!['assigned_to_last_name'];
    final hasAssignee = assignedToFirstName != null || assignedToLastName != null;
    final assigneeName = hasAssignee 
        ? '${assignedToFirstName ?? ''} ${assignedToLastName ?? ''}'.trim()
        : null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: IOSTheme.cardDecoration.copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.05),
            IOSTheme.systemBackground,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getProgressStatusLabel(progressStatus).toUpperCase(),
                  style: IOSTheme.footnote.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(
                CupertinoIcons.folder_fill,
                color: statusColor,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: IOSTheme.largeTitle,
          ),
          const SizedBox(height: 8),
          if (_project!['description'] != null && _project!['description'].toString().isNotEmpty)
            Text(
              _project!['description'],
              style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(CupertinoIcons.building_2_fill, color: IOSTheme.primaryBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                clientName,
                style: IOSTheme.footnote.copyWith(color: IOSTheme.primaryBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Afficher l'assignation ou le bouton d'auto-assignation
          if (hasAssignee) ...[
            Row(
              children: [
                const Icon(CupertinoIcons.person_fill, color: IOSTheme.successColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Assigné à: $assigneeName',
                  style: IOSTheme.footnote.copyWith(color: IOSTheme.successColor),
                ),
              ],
            ),
          ] else if (_isMissionUnassigned && _isAssociate) ...[
            const SizedBox(height: 8),
            _buildAssignToMyselfButton(),
          ] else if (_isMissionUnassigned) ...[
            Row(
              children: [
                const Icon(CupertinoIcons.person_badge_minus, color: IOSTheme.warningColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Non assignée',
                  style: IOSTheme.footnote.copyWith(color: IOSTheme.warningColor),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Bouton pour s'auto-assigner la mission
  Widget _buildAssignToMyselfButton() {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: IOSTheme.primaryBlue,
      borderRadius: BorderRadius.circular(12),
      onPressed: _isAssigning ? null : _assignToMyself,
      child: _isAssigning
          ? const CupertinoActivityIndicator(color: CupertinoColors.white)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.person_add, color: CupertinoColors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'M\'assigner cette mission',
                  style: IOSTheme.body.copyWith(
                    color: CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  String _getProgressStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'à_assigner':
        return 'À assigner';
      case 'en_cours':
      case 'in_progress':
        return 'En cours';
      case 'fait':
      case 'done':
      case 'completed':
        return 'Terminé';
      case 'pending':
        return 'En attente';
      default:
        return status;
    }
  }

  Widget _buildProjectStats() {
    final totalTasks = _tasks.length;
    final completedTasks = _tasks.where((t) => t['status'] == 'done' || t['status'] == 'completed').length;
    final progressPercentage = totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;
    
    // Calculer la progression temporelle
    final startDate = _project!['start_date'] != null ? DateTime.parse(_project!['start_date']) : null;
    final endDate = _project!['end_date'] != null ? DateTime.parse(_project!['end_date']) : null;
    final createdAt = _project!['created_at'] != null ? DateTime.parse(_project!['created_at']) : null;
    
    final timeProgressDetails = ProgressUtils.calculateTimeProgressDetails(
      startDate: startDate,
      endDate: endDate,
      createdAt: createdAt,
    );
    
    return IOSListSection(
      title: "Statistiques",
      children: [
        IOSListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: IOSTheme.primaryBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.list_bullet, color: IOSTheme.primaryBlue, size: 18),
          ),
          title: const Text('Tâches', style: IOSTheme.body),
          subtitle: Text('$completedTasks/$totalTasks terminées', style: IOSTheme.footnote),
          trailing: Text('$progressPercentage%', style: IOSTheme.body.copyWith(fontWeight: FontWeight.w600)),
        ),
        // Progression temporelle
        if (endDate != null)
          IOSListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: (timeProgressDetails['isOverdue'] ? IOSTheme.errorColor : IOSTheme.successColor).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                CupertinoIcons.clock, 
                color: timeProgressDetails['isOverdue'] ? IOSTheme.errorColor : IOSTheme.successColor, 
                size: 18
              ),
            ),
            title: const Text('Progression temporelle', style: IOSTheme.body),
            subtitle: Text(
              '${timeProgressDetails['daysElapsed']}/${timeProgressDetails['totalDays']} jours - ${timeProgressDetails['status']}', 
              style: IOSTheme.footnote
            ),
            trailing: Text(
              '${timeProgressDetails['percentage']}%', 
              style: IOSTheme.body.copyWith(
                fontWeight: FontWeight.w600,
                color: timeProgressDetails['isOverdue'] ? IOSTheme.errorColor : null,
              )
            ),
          ),
        if (_project!['estimated_days'] != null)
          IOSListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: IOSTheme.warningColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CupertinoIcons.time, color: IOSTheme.warningColor, size: 18),
            ),
            title: const Text('Durée estimée', style: IOSTheme.body),
            subtitle: Text('${_project!['estimated_days']} jours', style: IOSTheme.footnote),
          ),
        if (_project!['end_date'] != null)
          IOSListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: IOSTheme.successColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CupertinoIcons.calendar, color: IOSTheme.successColor, size: 18),
            ),
            title: const Text('Date de fin', style: IOSTheme.body),
            subtitle: Text(_project!['end_date'], style: IOSTheme.footnote),
          ),
      ],
    );
  }

  Widget _buildTasksList() {
    return IOSListSection(
      title: "Tâches (${ _tasks.length})",
      children: _tasks.isEmpty
          ? [
              IOSListTile(
                leading: const Icon(CupertinoIcons.list_bullet, color: IOSTheme.systemGray),
                title: Text(
                  'Aucune tâche',
                  style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
                ),
                subtitle: const Text('Aucune tâche n\'est associée à ce projet.', style: IOSTheme.footnote),
              ),
            ]
          : _tasks.map((task) => _buildTaskTile(task)).toList(),
    );
  }

  Widget _buildTaskTile(Map<String, dynamic> task) {
    final status = task['status'] ?? 'todo';
    final statusColor = IOSTheme.getStatusColor(status);
    final priority = task['priority'] ?? 'medium';
    final priorityColor = IOSTheme.getPriorityColor(priority);

    return IOSListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          status == 'done' || status == 'completed' 
              ? CupertinoIcons.checkmark 
              : CupertinoIcons.circle,
          color: statusColor,
          size: 18,
        ),
      ),
      title: Text(
        task['title'] ?? 'Tâche sans titre',
        style: IOSTheme.body,
      ),
      subtitle: task['description'] != null 
          ? Text(task['description'], style: IOSTheme.footnote)
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: priorityColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          priority,
          style: IOSTheme.footnote.copyWith(
            color: priorityColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  /// Vérifie si l'utilisateur peut modifier le projet (admin ou associé uniquement)
  bool get _canEditProject {
    return _userRole == UserRole.admin || _userRole == UserRole.associe;
  }

  void _showProjectActions() {
    // Définir les actions disponibles selon le rôle
    final List<CupertinoActionSheetAction> actions = [];
    
    // Modifier le projet (admin/associé uniquement)
    if (_canEditProject) {
      actions.add(
        CupertinoActionSheetAction(
          child: const Text('Modifier le projet'),
          onPressed: () {
            Navigator.of(context).pop();
            _showEditProjectDialog();
          },
        ),
      );
      actions.add(
        CupertinoActionSheetAction(
          child: const Text('Ajouter une tâche'),
          onPressed: () {
            Navigator.of(context).pop();
            _showAddTaskDialog();
          },
        ),
      );
    }
    
    // Voir les documents (accessible à tous)
    actions.add(
      CupertinoActionSheetAction(
        child: const Text('Voir les documents'),
        onPressed: () {
          Navigator.of(context).pop();
          _showDocumentsDialog();
        },
      ),
    );
    
    // Contacter l'équipe (partenaires et clients)
    if (_userRole == UserRole.partenaire || _userRole == UserRole.client) {
      actions.add(
        CupertinoActionSheetAction(
          child: const Text('Contacter l\'équipe'),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context, rootNavigator: true).pushNamed('/messaging');
          },
        ),
      );
    }

    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(_project!['title'] ?? _project!['name'] ?? 'Actions du projet'),
        actions: actions,
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _showEditProjectDialog() {
    final titleController = TextEditingController(text: _project!['title'] ?? _project!['name'] ?? '');
    final descriptionController = TextEditingController(text: _project!['description'] ?? '');
    
    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Annuler'),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                      const Text('Modifier le projet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: const Text('Enregistrer'),
                        onPressed: () async {
                          try {
                            await SupabaseService.client
                                .from('missions')
                                .update({
                                  'title': titleController.text,
                                  'description': descriptionController.text,
                                })
                                .eq('id', widget.projectId);
                            Navigator.pop(dialogContext);
                            _loadProjectDetails();
                            _showSuccessMessage('Projet modifié avec succès');
                          } catch (e) {
                            _showErrorMessage('Erreur lors de la modification: $e');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Titre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.secondaryLabel)),
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: titleController,
                          placeholder: 'Titre du projet',
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.secondaryLabel)),
                        const SizedBox(height: 8),
                        CupertinoTextField(
                          controller: descriptionController,
                          placeholder: 'Description du projet',
                          maxLines: 4,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String priority = 'medium';

    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text('Annuler'),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                        const Text('Nouvelle tâche', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text('Créer'),
                          onPressed: () async {
                            if (titleController.text.isEmpty) {
                              _showErrorMessage('Le titre est requis');
                              return;
                            }
                            try {
                              await SupabaseService.client
                                  .from('missions')
                                  .insert({
                                    'title': titleController.text,
                                    'description': descriptionController.text,
                                    'mission_id': widget.projectId,
                                    'priority': priority,
                                    'status': 'pending',
                                    'progress_status': 'à_assigner',
                                  });
                              Navigator.pop(dialogContext);
                              _loadProjectDetails();
                              _showSuccessMessage('Tâche créée avec succès');
                            } catch (e) {
                              _showErrorMessage('Erreur lors de la création: $e');
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Titre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.secondaryLabel)),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            controller: titleController,
                            placeholder: 'Titre de la tâche',
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.secondaryLabel)),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            controller: descriptionController,
                            placeholder: 'Description (optionnel)',
                            maxLines: 3,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text('Priorité', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: CupertinoColors.secondaryLabel)),
                          const SizedBox(height: 12),
                          CupertinoSlidingSegmentedControl<String>(
                            groupValue: priority,
                            children: const {
                              'low': Text('Basse'),
                              'medium': Text('Moyenne'),
                              'high': Text('Haute'),
                            },
                            onValueChanged: (value) {
                              if (value != null) {
                                setDialogState(() => priority = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentsDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Documents'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Aucun document n\'est attaché à ce projet pour le moment.'),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Succès'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
} 