import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';

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
  String? _error;

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

      // Charger les détails du projet
      final projects = await SupabaseService.getCompanyProjects();
      debugPrint('Recherche projet ID: ${widget.projectId}');
      debugPrint('Projets disponibles: ${projects.map((p) => 'ID: ${p['id']}, Name: ${p['name']}').toList()}');
      
      _project = projects.firstWhere(
        (p) => p['id'].toString() == widget.projectId,
        orElse: () {
          debugPrint('Projet non trouvé avec ID: ${widget.projectId}');
          return <String, dynamic>{};
        },
      );
      
      if (_project!.isNotEmpty) {
        debugPrint('Projet trouvé: ${_project!['name']}');
      }

      // Charger les tâches du projet
      final allTasks = await SupabaseService.getCompanyTasks();
      _tasks = allTasks.where((task) => 
        task['project_id']?.toString() == widget.projectId
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
    final statusColor = IOSTheme.getStatusColor(status);
    final clientName = _project!['client_name'] ?? _project!['company_name'] ?? 'Aucun client';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: IOSTheme.cardDecoration.copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            statusColor.withValues(alpha: 0.05),
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
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
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
            _project!['name'] ?? 'Projet sans titre',
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
              const Icon(CupertinoIcons.person, color: IOSTheme.primaryBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                clientName,
                style: IOSTheme.footnote.copyWith(color: IOSTheme.primaryBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectStats() {
    final totalTasks = _tasks.length;
    final completedTasks = _tasks.where((t) => t['status'] == 'done' || t['status'] == 'completed').length;
    final progressPercentage = totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;
    
    return IOSListSection(
      title: "Statistiques",
      children: [
        IOSListTile(
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: IOSTheme.primaryBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(CupertinoIcons.list_bullet, color: IOSTheme.primaryBlue, size: 18),
          ),
          title: const Text('Tâches', style: IOSTheme.body),
          subtitle: Text('$completedTasks/$totalTasks terminées', style: IOSTheme.footnote),
          trailing: Text('$progressPercentage%', style: IOSTheme.body.copyWith(fontWeight: FontWeight.w600)),
        ),
        if (_project!['estimated_days'] != null)
          IOSListTile(
            leading: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: IOSTheme.warningColor.withValues(alpha: 0.15),
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
                color: IOSTheme.successColor.withValues(alpha: 0.15),
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
          color: statusColor.withValues(alpha: 0.15),
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
          color: priorityColor.withValues(alpha: 0.15),
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

  void _showProjectActions() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(_project!['name'] ?? 'Actions du projet'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Modifier le projet'),
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter l'édition
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Ajouter une tâche'),
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter l'ajout de tâche
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Voir les documents'),
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter la vue des documents
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Annuler'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
} 