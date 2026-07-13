import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
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

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('S\'assigner cette mission'),
        content: Text(
          'Voulez-vous vous assigner la mission "${_project!['title'] ?? _project!['name']}" ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Confirmer')),
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
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Succès'),
            content: const Text('La mission vous a été assignée avec succès !'),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
            ],
          ),
        );

        // Recharger les données
        await _loadProjectDetails();
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'assignation: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Impossible de s\'assigner la mission: $e'),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('OK')),
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
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.colors.textPrimary),
        titleTextStyle: AppTheme.typography.h4.copyWith(color: AppTheme.colors.textPrimary),
        title: Text(_project?['name'] ?? 'Détails du projet'),
        leading: IconButton(
          icon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left, size: 18),
              Text('Retour', style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.primary)),
            ],
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_horiz, color: AppTheme.colors.primary),
            onPressed: _showProjectActions,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2)))
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
          Icon(Icons.warning_amber_rounded, size: 64, color: AppTheme.colors.error),
          const SizedBox(height: 16),
          Text('Erreur', style: AppTheme.typography.h3),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _error!,
              style: AppTheme.typography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
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
          Icon(Icons.folder_open, size: 64, color: AppTheme.colors.textSecondary),
          const SizedBox(height: 16),
          Text('Projet non trouvé', style: AppTheme.typography.h3),
          const SizedBox(height: 8),
          Text(
            'Ce projet n\'existe pas ou vous n\'y avez pas accès.',
            style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectHeader() {
    final status = _project!['status'] ?? 'actif';
    final progressStatus = _project!['progress_status'] ?? 'à_assigner';
    final statusColor = _getStatusColor(status);
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
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.colors.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withOpacity(0.05),
            AppTheme.colors.surface,
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
                  style: AppTheme.typography.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Icon(Icons.folder, color: statusColor, size: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: AppTheme.typography.h1),
          const SizedBox(height: 8),
          if (_project!['description'] != null && _project!['description'].toString().isNotEmpty)
            Text(
              _project!['description'],
              style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.business, color: AppTheme.colors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                clientName,
                style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Afficher l'assignation ou le bouton d'auto-assignation
          if (hasAssignee) ...[
            Row(
              children: [
                Icon(Icons.person, color: AppTheme.colors.success, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Assigné à: $assigneeName',
                  style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.success),
                ),
              ],
            ),
          ] else if (_isMissionUnassigned && _isAssociate) ...[
            const SizedBox(height: 8),
            _buildAssignToMyselfButton(),
          ] else if (_isMissionUnassigned) ...[
            Row(
              children: [
                Icon(Icons.person_off, color: AppTheme.colors.warning, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Non assignée',
                  style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.warning),
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.colors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: _isAssigning ? null : _assignToMyself,
      child: _isAssigning
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'M\'assigner cette mission',
                  style: AppTheme.typography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'actif':
        return AppTheme.colors.success;
      case 'pending':
      case 'en_attente':
        return AppTheme.colors.warning;
      case 'completed':
      case 'terminé':
        return AppTheme.colors.primary;
      default:
        return AppTheme.colors.textSecondary;
    }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text('Statistiques', style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary)),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.colors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.list, color: AppTheme.colors.primary, size: 18),
                ),
                title: Text('Tâches', style: AppTheme.typography.bodyMedium),
                subtitle: Text('$completedTasks/$totalTasks terminées', style: AppTheme.typography.bodySmall),
                trailing: Text('$progressPercentage%', style: AppTheme.typography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              ),
              // Progression temporelle
              if (endDate != null)
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: (timeProgressDetails['isOverdue'] ? AppTheme.colors.error : AppTheme.colors.success).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.access_time,
                      color: timeProgressDetails['isOverdue'] ? AppTheme.colors.error : AppTheme.colors.success,
                      size: 18,
                    ),
                  ),
                  title: Text('Progression temporelle', style: AppTheme.typography.bodyMedium),
                  subtitle: Text(
                    '${timeProgressDetails['daysElapsed']}/${timeProgressDetails['totalDays']} jours - ${timeProgressDetails['status']}',
                    style: AppTheme.typography.bodySmall,
                  ),
                  trailing: Text(
                    '${timeProgressDetails['percentage']}%',
                    style: AppTheme.typography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: timeProgressDetails['isOverdue'] ? AppTheme.colors.error : null,
                    ),
                  ),
                ),
              if (_project!['estimated_days'] != null)
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.colors.warning.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.timer, color: AppTheme.colors.warning, size: 18),
                  ),
                  title: Text('Durée estimée', style: AppTheme.typography.bodyMedium),
                  subtitle: Text('${_project!['estimated_days']} jours', style: AppTheme.typography.bodySmall),
                ),
              if (_project!['end_date'] != null)
                ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.colors.success.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.calendar_today, color: AppTheme.colors.success, size: 18),
                  ),
                  title: Text('Date de fin', style: AppTheme.typography.bodyMedium),
                  subtitle: Text(_project!['end_date'], style: AppTheme.typography.bodySmall),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTasksList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text('Tâches (${_tasks.length})', style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary)),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: _tasks.isEmpty
                ? [
                    ListTile(
                      leading: Icon(Icons.list, color: AppTheme.colors.textSecondary),
                      title: Text(
                        'Aucune tâche',
                        style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary),
                      ),
                      subtitle: Text('Aucune tâche n\'est associée à ce projet.', style: AppTheme.typography.bodySmall),
                    ),
                  ]
                : _tasks.map((task) => _buildTaskTile(task)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTaskTile(Map<String, dynamic> task) {
    final status = task['status'] ?? 'todo';
    final statusColor = _getStatusColor(status);
    final priority = task['priority'] ?? 'medium';
    final priorityColor = _getPriorityColor(priority);

    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          status == 'done' || status == 'completed' ? Icons.check : Icons.circle_outlined,
          color: statusColor,
          size: 18,
        ),
      ),
      title: Text(task['title'] ?? 'Tâche sans titre', style: AppTheme.typography.bodyMedium),
      subtitle: task['description'] != null
          ? Text(task['description'], style: AppTheme.typography.bodySmall)
          : null,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: priorityColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          priority,
          style: AppTheme.typography.bodySmall.copyWith(
            color: priorityColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
        return AppTheme.colors.error;
      case 'medium':
        return AppTheme.colors.warning;
      case 'low':
        return AppTheme.colors.success;
      default:
        return AppTheme.colors.textSecondary;
    }
  }

  /// Vérifie si l'utilisateur peut modifier le projet (admin ou associé uniquement)
  bool get _canEditProject {
    return _userRole == UserRole.admin || _userRole == UserRole.associe;
  }

  void _showProjectActions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_canEditProject) ...[
            ListTile(
              title: const Text('Modifier le projet'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showEditProjectDialog();
              },
            ),
            ListTile(
              title: const Text('Ajouter une tâche'),
              onTap: () {
                Navigator.of(ctx).pop();
                _showAddTaskDialog();
              },
            ),
          ],
          ListTile(
            title: const Text('Voir les documents'),
            onTap: () {
              Navigator.of(ctx).pop();
              _showDocumentsDialog();
            },
          ),
          if (_userRole == UserRole.partenaire || _userRole == UserRole.client)
            ListTile(
              title: const Text('Contacter l\'équipe'),
              onTap: () {
                Navigator.of(ctx).pop();
                Navigator.of(context, rootNavigator: true).pushNamed('/messaging');
              },
            ),
          ListTile(
            title: Text('Annuler', style: TextStyle(color: AppTheme.colors.textSecondary)),
            onTap: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  void _showEditProjectDialog() {
    final titleController = TextEditingController(text: _project!['title'] ?? _project!['name'] ?? '');
    final descriptionController = TextEditingController(text: _project!['description'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: AppTheme.colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Annuler'),
                    ),
                    const Text('Modifier le projet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    TextButton(
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
                      child: const Text('Enregistrer'),
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
                      Text('Titre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.colors.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Titre du projet',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.colors.textSecondary)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Description du projet',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.all(14),
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
    );
  }

  void _showAddTaskDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String priority = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: AppTheme.colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Annuler'),
                      ),
                      const Text('Nouvelle tâche', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      TextButton(
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
                        child: const Text('Créer'),
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
                        Text('Titre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.colors.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Titre de la tâche',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.colors.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descriptionController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Description (optionnel)',
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Priorité', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.colors.textSecondary)),
                        const SizedBox(height: 12),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'low', label: Text('Basse')),
                            ButtonSegment(value: 'medium', label: Text('Moyenne')),
                            ButtonSegment(value: 'high', label: Text('Haute')),
                          ],
                          selected: {priority},
                          onSelectionChanged: (value) {
                            setDialogState(() => priority = value.first);
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
    );
  }

  void _showDocumentsDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Documents'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text('Aucun document n\'est attaché à ce projet pour le moment.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Succès'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('OK')),
        ],
      ),
    );
  }
}
