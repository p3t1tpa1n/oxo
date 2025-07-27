import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../models/user_role.dart';
import '../../services/supabase_service.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _filteredProjects = [];
  List<Map<String, dynamic>> _partners = [];
  Map<String, List<Map<String, dynamic>>> _tasksByProject = {};
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'name';
  String _filterStatus = 'all';
  bool _sortAscending = true;
  
  // Variables pour la vue détaillée
  Map<String, dynamic>? _selectedProject;
  String _currentView = 'grid'; // 'grid' ou 'detail'
  String _taskFilter = 'all'; // 'all', 'todo', 'in_progress', 'done'

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
      // Charger projets, partenaires et tâches en parallèle
      final results = await Future.wait([
        _loadProjects(),
        _loadPartners(),
        _loadAllTasks(),
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

  Future<List<Map<String, dynamic>>> _loadProjects() async {
    final response = await SupabaseService.client
        .from('projects')
        .select('*')
        .order('created_at', ascending: false);

    _projects = List<Map<String, dynamic>>.from(response);
    return _projects;
  }

  Future<List<Map<String, dynamic>>> _loadPartners() async {
    _partners = await SupabaseService.getPartners();
    return _partners;
  }

  Future<void> _loadAllTasks() async {
    final tasks = await SupabaseService.getCompanyTasks();
    
    // Organiser les tâches par projet
    final tasksByProject = <String, List<Map<String, dynamic>>>{};
    for (final task in tasks) {
      final projectId = task['project_id']?.toString() ?? 'no_project';
      tasksByProject.putIfAbsent(projectId, () => []).add(task);
    }
    
    _tasksByProject = tasksByProject;
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = _projects;

    // Appliquer le filtre de recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((project) {
        final name = (project['name'] ?? '').toString().toLowerCase();
        final description = (project['description'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }

    // Appliquer le filtre de statut
    if (_filterStatus != 'all') {
      filtered = filtered.where((project) => project['status'] == _filterStatus).toList();
    }

    // Appliquer le tri
    filtered.sort((a, b) {
      dynamic valueA, valueB;
      
      switch (_sortBy) {
        case 'name':
          valueA = (a['name'] ?? '').toString().toLowerCase();
          valueB = (b['name'] ?? '').toString().toLowerCase();
          break;
        case 'created_at':
          valueA = DateTime.tryParse(a['created_at'] ?? '') ?? DateTime.now();
          valueB = DateTime.tryParse(b['created_at'] ?? '') ?? DateTime.now();
          break;
        case 'status':
          valueA = (a['status'] ?? '').toString();
          valueB = (b['status'] ?? '').toString();
          break;
        case 'tasks':
          valueA = _tasksByProject[a['id'].toString()]?.length ?? 0;
          valueB = _tasksByProject[b['id'].toString()]?.length ?? 0;
          break;
        default:
          valueA = a[_sortBy] ?? '';
          valueB = b[_sortBy] ?? '';
      }

      if (_sortAscending) {
        return valueA.compareTo(valueB);
      } else {
        return valueB.compareTo(valueA);
      }
    });

    setState(() {
      _filteredProjects = filtered;
    });
  }

  void _showProjectDetails(Map<String, dynamic> project) {
    setState(() {
      _selectedProject = project;
      _currentView = 'detail';
    });
  }

  void _backToGrid() {
    setState(() {
      _selectedProject = null;
      _currentView = 'grid';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          SideMenu(
            userRole: SupabaseService.currentUserRole,
            selectedRoute: '/projects',
          ),
          Expanded(
            child: Column(
              children: [
                TopBar(
                  title: _currentView == 'detail' 
                      ? 'Projet: ${_selectedProject?['name'] ?? ''}'
                      : 'Gestion des Projets',
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _currentView == 'detail'
                          ? _buildProjectDetailView()
                          : _buildProjectsGridView(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_currentView == 'detail' && _selectedProject != null) {
      return FloatingActionButton.extended(
        onPressed: () => _showCreateTaskDialog(_selectedProject!),
        backgroundColor: const Color(0xFF1784af),
        icon: const Icon(Icons.add_task, color: Colors.white),
        label: const Text('Nouvelle Tâche', style: TextStyle(color: Colors.white)),
      );
    } else if (_currentView == 'grid') {
      return FloatingActionButton.extended(
        onPressed: _showCreateProjectDialog,
        backgroundColor: const Color(0xFF1784af),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nouveau Projet', style: TextStyle(color: Colors.white)),
      );
    }
    return null;
  }

  // ============= VUE GRILLE DES PROJETS =============

  Widget _buildProjectsGridView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildProjectFilters(),
          const SizedBox(height: 24),
          Expanded(
            child: _filteredProjects.isEmpty
                ? _buildEmptyProjectsState()
                : _buildProjectsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Rechercher un projet',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _applyFiltersAndSort();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _filterStatus,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tous')),
                      DropdownMenuItem(value: 'active', child: Text('Actif')),
                      DropdownMenuItem(value: 'paused', child: Text('En pause')),
                      DropdownMenuItem(value: 'completed', child: Text('Terminé')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                      });
                      _applyFiltersAndSort();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: const InputDecoration(
                      labelText: 'Trier par',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'name', child: Text('Nom')),
                      DropdownMenuItem(value: 'created_at', child: Text('Date')),
                      DropdownMenuItem(value: 'status', child: Text('Statut')),
                      DropdownMenuItem(value: 'tasks', child: Text('Nb. tâches')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _sortBy = value!;
                      });
                      _applyFiltersAndSort();
                    },
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                    });
                    _applyFiltersAndSort();
                  },
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: const Color(0xFF1784af),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  '${_filteredProjects.length} projet(s) trouvé(s)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProjectsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun projet trouvé',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Créez votre premier projet pour commencer.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _showCreateProjectDialog,
            icon: const Icon(Icons.add),
            label: const Text('Créer un projet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1784af),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth < 600) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1200) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 3;
        }
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.5,
          ),
          itemCount: _filteredProjects.length,
          itemBuilder: (context, index) {
            final project = _filteredProjects[index];
            return _buildProjectCard(project);
          },
        );
      },
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final status = project['status'] ?? 'active';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final taskCount = _tasksByProject[project['id'].toString()]?.length ?? 0;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProjectDetails(project),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project['name'] ?? 'Projet sans nom',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3D54),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleProjectAction(project, value),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                      const PopupMenuItem(value: 'tasks', child: Text('Voir les tâches')),
                      const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Text(
                  project['description'] ?? 'Aucune description',
                  style: TextStyle(
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    project['created_at'] != null
                        ? DateFormat('dd/MM/yyyy').format(DateTime.parse(project['created_at']))
                        : 'Date inconnue',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: taskCount > 0 ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.task_alt, size: 12, color: taskCount > 0 ? Colors.blue : Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '$taskCount tâche(s)',
                          style: TextStyle(
                            fontSize: 12,
                            color: taskCount > 0 ? Colors.blue : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  // ============= VUE DÉTAIL DU PROJET =============

  Widget _buildProjectDetailView() {
    if (_selectedProject == null) return const SizedBox();
    
    final projectId = _selectedProject!['id'].toString();
    final tasks = _tasksByProject[projectId] ?? [];
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildProjectDetailHeader(),
          const SizedBox(height: 24),
          _buildTaskFilters(),
          const SizedBox(height: 24),
          Expanded(
            child: tasks.isEmpty
                ? _buildEmptyTasksState()
                : _buildTasksBoard(tasks),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetailHeader() {
    final project = _selectedProject!;
    final status = project['status'] ?? 'active';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final projectId = project['id'].toString();
    final tasks = _tasksByProject[projectId] ?? [];
    final todoTasks = tasks.where((t) => t['status'] == 'todo').length;
    final inProgressTasks = tasks.where((t) => t['status'] == 'in_progress').length;
    final doneTasks = tasks.where((t) => t['status'] == 'done').length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _backToGrid,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Retour aux projets',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['name'] ?? 'Projet sans nom',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3D54),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (project['description'] != null)
                        Text(
                          project['description'],
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleProjectAction(project, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier le projet')),
                    const PopupMenuItem(value: 'delete', child: Text('Supprimer le projet')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildTaskStatCard('À faire', todoTasks, Colors.orange),
                const SizedBox(width: 16),
                _buildTaskStatCard('En cours', inProgressTasks, Colors.blue),
                const SizedBox(width: 16),
                _buildTaskStatCard('Terminées', doneTasks, Colors.green),
                const SizedBox(width: 16),
                _buildTaskStatCard('Total', tasks.length, Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 28,
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
      ),
    );
  }

  Widget _buildTaskFilters() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              'Tâches',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3D54),
              ),
            ),
            const Spacer(),
            _buildTaskFilterChip('Toutes', 'all'),
            const SizedBox(width: 8),
            _buildTaskFilterChip('À faire', 'todo'),
            const SizedBox(width: 8),
            _buildTaskFilterChip('En cours', 'in_progress'),
            const SizedBox(width: 8),
            _buildTaskFilterChip('Terminées', 'done'),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskFilterChip(String label, String value) {
    final isSelected = _taskFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _taskFilter = value;
        });
      },
      backgroundColor: Colors.grey[100],
      selectedColor: const Color(0xFF1784af).withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1784af) : Colors.grey[700],
      ),
    );
  }

  Widget _buildEmptyTasksState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune tâche dans ce projet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Créez votre première tâche pour commencer.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => _showCreateTaskDialog(_selectedProject!),
            icon: const Icon(Icons.add_task),
            label: const Text('Créer une tâche'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1784af),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksBoard(List<Map<String, dynamic>> allTasks) {
    // Filtrer les tâches selon le filtre sélectionné
    List<Map<String, dynamic>> filteredTasks = allTasks;
    if (_taskFilter != 'all') {
      filteredTasks = allTasks.where((task) => task['status'] == _taskFilter).toList();
    }

    // Grouper les tâches par statut pour l'affichage en colonnes
    final todoTasks = filteredTasks.where((t) => t['status'] == 'todo').toList();
    final inProgressTasks = filteredTasks.where((t) => t['status'] == 'in_progress').toList();
    final doneTasks = filteredTasks.where((t) => t['status'] == 'done').toList();

    if (_taskFilter == 'all') {
      // Vue Kanban avec colonnes
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildTaskColumn('À faire', todoTasks, Colors.orange)),
          const SizedBox(width: 16),
          Expanded(child: _buildTaskColumn('En cours', inProgressTasks, Colors.blue)),
          const SizedBox(width: 16),
          Expanded(child: _buildTaskColumn('Terminées', doneTasks, Colors.green)),
        ],
      );
    } else {
      // Vue liste pour un statut spécifique
      return _buildTasksList(filteredTasks);
    }
  }

  Widget _buildTaskColumn(String title, List<Map<String, dynamic>> tasks, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${tasks.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTaskCard(tasks[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksList(List<Map<String, dynamic>> tasks) {
    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildTaskCard(tasks[index]),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final priority = task['priority'] ?? 'medium';
    final priorityColor = _getPriorityColor(priority);
    final dueDate = task['due_date'] != null ? DateTime.parse(task['due_date']) : null;
    final isOverdue = dueDate != null && dueDate.isBefore(DateTime.now());

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task['title'] ?? 'Tâche sans titre',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3D54),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleTaskAction(task, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    const PopupMenuItem(value: 'assign', child: Text('Assigner')),
                    const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ],
            ),
            if (task['description'] != null && task['description'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                task['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPriorityChip(priority, priorityColor),
                const SizedBox(width: 8),
                if (dueDate != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: isOverdue ? Colors.red : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM').format(dueDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: isOverdue ? Colors.red : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                if (task['assigned_to'] != null)
                  _buildAssigneeAvatar(task),
              ],
            ),
            const SizedBox(height: 12),
            _buildTaskStatusButtons(task),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _getPriorityLabel(priority),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildAssigneeAvatar(Map<String, dynamic> task) {
    // Essayer différentes clés pour récupérer l'email de l'assigné
    String assigneeEmail = 'Assigné';
    
    if (task['assigned_user'] != null && task['assigned_user']['email'] != null) {
      assigneeEmail = task['assigned_user']['email'];
    } else if (task['assigned_to'] != null) {
      // Chercher le partenaire par ID
      final partner = _partners.firstWhere(
        (p) => p['user_id'] == task['assigned_to'],
        orElse: () => {},
      );
      if (partner.isNotEmpty && partner['email'] != null) {
        assigneeEmail = partner['email'];
      }
    }

    return Tooltip(
      message: assigneeEmail,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: const Color(0xFF1784af),
        child: Text(
          assigneeEmail.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTaskStatusButtons(Map<String, dynamic> task) {
    final status = task['status'];
    
    return Row(
      children: [
        if (status != 'todo')
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _updateTaskStatus(task, 'todo'),
              icon: const Icon(Icons.replay, size: 16),
              label: const Text('À faire'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          ),
        if (status != 'todo' && status != 'in_progress') const SizedBox(width: 8),
        if (status != 'in_progress')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateTaskStatus(task, 'in_progress'),
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('En cours'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        if (status != 'in_progress' && status != 'done') const SizedBox(width: 8),
        if (status != 'done')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _updateTaskStatus(task, 'done'),
              icon: const Icon(Icons.check, size: 16),
              label: const Text('Terminer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
      ],
    );
  }

  // ============= ACTIONS ET DIALOGUES =============

  void _handleProjectAction(Map<String, dynamic> project, String action) {
    switch (action) {
      case 'edit':
        _showEditProjectDialog(project);
        break;
      case 'tasks':
        _showProjectDetails(project);
        break;
      case 'delete':
        _deleteProject(project);
        break;
    }
  }

  void _handleTaskAction(Map<String, dynamic> task, String action) {
    switch (action) {
      case 'edit':
        _showEditTaskDialog(task);
        break;
      case 'assign':
        _showAssignTaskDialog(task);
        break;
      case 'delete':
        _deleteTask(task);
        break;
    }
  }

  Future<void> _updateTaskStatus(Map<String, dynamic> task, String newStatus) async {
    try {
      await SupabaseService.client
          .from('tasks')
          .update({'status': newStatus})
          .eq('id', task['id']);

      await _loadAllTasks();
      setState(() {});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour vers: ${_getStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
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

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final estimatedDaysController = TextEditingController();
    final dailyRateController = TextEditingController();
    DateTime? endDate;
    Map<String, dynamic>? selectedClient;
    List<Map<String, dynamic>> clients = [];
    bool isLoadingClients = true;

    // Charger les clients au démarrage
    Future<void> loadClients() async {
      try {
        final clientsList = await SupabaseService.getCompanyClients();
        clients = clientsList;
        isLoadingClients = false;
      } catch (e) {
        isLoadingClients = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des clients: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // Charger les clients au premier rendu
          if (isLoadingClients) {
            loadClients().then((_) {
              if (context.mounted) {
                setDialogState(() {});
              }
            });
          }

          return AlertDialog(
            title: const Text('Nouveau Projet'),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du projet
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du projet *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.folder),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sélection du client
                    if (isLoadingClients)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 12),
                              Text('Chargement des clients...'),
                            ],
                          ),
                        ),
                      )
                    else if (clients.isEmpty)
                      Card(
                        color: Colors.orange.shade50,
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.warning, color: Colors.orange),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Aucun client disponible. Veuillez d\'abord créer un client.',
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      DropdownButtonFormField<Map<String, dynamic>>(
                        value: selectedClient,
                        decoration: const InputDecoration(
                          labelText: 'Client assigné *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        hint: const Text('Sélectionner un client'),
                        items: clients.map((client) {
                          return DropdownMenuItem(
                            value: client,
                            child: Text(
                              client['full_name'] ?? client['email'] ?? 'Client',
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedClient = value;
                          });
                        },
                      ),
                    const SizedBox(height: 16),

                    // Date de fin
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        );
                        if (date != null) {
                          setDialogState(() {
                            endDate = date;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date de fin souhaitée',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          endDate != null 
                              ? DateFormat('dd/MM/yyyy').format(endDate!)
                              : 'Sélectionner une date',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Estimation optionnelle
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: estimatedDaysController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Jours estimés',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.schedule),
                              suffixText: 'jours',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: dailyRateController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Tarif journalier',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.euro),
                              suffixText: '€/jour',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: clients.isEmpty ? null : () async {
                  if (nameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Le nom du projet est requis')),
                    );
                    return;
                  }

                  if (selectedClient == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez sélectionner un client')),
                    );
                    return;
                  }

                  try {
                    final estimatedDays = double.tryParse(estimatedDaysController.text);
                    final dailyRate = double.tryParse(dailyRateController.text);

                    final projectId = await SupabaseService.createProjectWithClient(
                      name: nameController.text,
                      description: descriptionController.text.isNotEmpty 
                          ? descriptionController.text 
                          : null,
                      clientId: selectedClient!['user_id'],
                      estimatedDays: estimatedDays,
                      dailyRate: dailyRate,
                      endDate: endDate,
                    );

                    Navigator.of(context).pop();
                    await _loadData();
                    
                    if (mounted && projectId != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Projet "${nameController.text}" créé avec succès pour ${selectedClient!['full_name']}'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      throw Exception('Échec de la création du projet');
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
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1784af),
                ),
                child: const Text('Créer', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditProjectDialog(Map<String, dynamic> project) {
    final nameController = TextEditingController(text: project['name']);
    final descriptionController = TextEditingController(text: project['description'] ?? '');
    DateTime? startDate = project['start_date'] != null ? DateTime.parse(project['start_date']) : null;
    DateTime? endDate = project['end_date'] != null ? DateTime.parse(project['end_date']) : null;
    String selectedStatus = project['status'] ?? 'active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier le Projet'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du projet *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Actif')),
                      DropdownMenuItem(value: 'paused', child: Text('En pause')),
                      DropdownMenuItem(value: 'completed', child: Text('Terminé')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedStatus = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                startDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date de début',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              startDate != null 
                                  ? DateFormat('dd/MM/yyyy').format(startDate!)
                                  : 'Sélectionner',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? startDate ?? DateTime.now(),
                              firstDate: startDate ?? DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                endDate = date;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Date de fin',
                              border: OutlineInputBorder(),
                            ),
                            child: Text(
                              endDate != null 
                                  ? DateFormat('dd/MM/yyyy').format(endDate!)
                                  : 'Sélectionner',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Le nom du projet est requis')),
                  );
                  return;
                }

                try {
                  await SupabaseService.client
                      .from('projects')
                      .update({
                        'name': nameController.text,
                        'description': descriptionController.text,
                        'status': selectedStatus,
                        'start_date': startDate?.toIso8601String(),
                        'end_date': endDate?.toIso8601String(),
                        'updated_at': DateTime.now().toIso8601String(),
                      })
                      .eq('id', project['id']);

                  Navigator.of(context).pop();
                  await _loadData();
                  
                  // Mettre à jour le projet sélectionné si c'est celui qu'on modifie
                  if (_selectedProject != null && _selectedProject!['id'] == project['id']) {
                    _selectedProject = _projects.firstWhere((p) => p['id'] == project['id']);
                  }
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Projet modifié avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1784af),
              ),
              child: const Text('Modifier', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTaskDialog(Map<String, dynamic> project) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedPriority = 'medium';
    String? selectedPartnerId;
    DateTime? selectedDueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Nouvelle tâche - ${project['name']}'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la tâche *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priorité',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Basse')),
                      DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                      DropdownMenuItem(value: 'high', child: Text('Haute')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPriority = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPartnerId,
                    decoration: const InputDecoration(
                      labelText: 'Assigner à un partenaire',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Non assigné'),
                      ),
                      ..._partners.map((partner) => DropdownMenuItem(
                        value: partner['user_id'],
                        child: Text('${partner['first_name']} ${partner['last_name']} (${partner['email']})'),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPartnerId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedDueDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            selectedDueDate != null
                                ? 'Échéance: ${DateFormat('dd/MM/yyyy').format(selectedDueDate!)}'
                                : 'Définir une échéance',
                          ),
                        ),
                      ),
                      if (selectedDueDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedDueDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ],
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

                try {
                  if (selectedPartnerId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez sélectionner un partenaire')),
                    );
                    return;
                  }

                  await SupabaseService.createTaskForCompany(
                    projectId: project['id'].toString(),
                    title: titleController.text,
                    description: descriptionController.text.isNotEmpty 
                        ? descriptionController.text 
                        : null,
                    priority: selectedPriority,
                    partnerId: selectedPartnerId!,
                    assignedTo: selectedPartnerId,
                    dueDate: selectedDueDate,
                  );

                  Navigator.pop(context);
                  await _loadAllTasks();
                  setState(() {});
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tâche créée avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1784af),
                foregroundColor: Colors.white,
              ),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTaskDialog(Map<String, dynamic> task) {
    final titleController = TextEditingController(text: task['title']);
    final descriptionController = TextEditingController(text: task['description'] ?? '');
    String selectedPriority = task['priority'] ?? 'medium';
    String? selectedPartnerId = task['assigned_to'];
    DateTime? selectedDueDate = task['due_date'] != null ? DateTime.parse(task['due_date']) : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier la tâche'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la tâche *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPriority,
                    decoration: const InputDecoration(
                      labelText: 'Priorité',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Basse')),
                      DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                      DropdownMenuItem(value: 'high', child: Text('Haute')),
                      DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPriority = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPartnerId,
                    decoration: const InputDecoration(
                      labelText: 'Assigner à un partenaire',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Non assigné'),
                      ),
                      ..._partners.map((partner) => DropdownMenuItem(
                        value: partner['user_id'],
                        child: Text('${partner['first_name']} ${partner['last_name']} (${partner['email']})'),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedPartnerId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDueDate ?? DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                selectedDueDate = date;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            selectedDueDate != null
                                ? 'Échéance: ${DateFormat('dd/MM/yyyy').format(selectedDueDate!)}'
                                : 'Définir une échéance',
                          ),
                        ),
                      ),
                      if (selectedDueDate != null) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            setDialogState(() {
                              selectedDueDate = null;
                            });
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ],
                    ],
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

                try {
                  await SupabaseService.client
                      .from('tasks')
                      .update({
                        'title': titleController.text,
                        'description': descriptionController.text.isNotEmpty 
                            ? descriptionController.text 
                            : null,
                        'priority': selectedPriority,
                        'assigned_to': selectedPartnerId,
                        'due_date': selectedDueDate?.toIso8601String(),
                        'updated_by': SupabaseService.currentUser!.id,
                      })
                      .eq('id', task['id']);

                  Navigator.pop(context);
                  await _loadAllTasks();
                  setState(() {});
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tâche modifiée avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1784af),
                foregroundColor: Colors.white,
              ),
              child: const Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignTaskDialog(Map<String, dynamic> task) {
    String? selectedPartnerId = task['assigned_to'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assigner la tâche "${task['title']}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPartnerId,
                decoration: const InputDecoration(
                  labelText: 'Assigner à un partenaire',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Non assigné'),
                  ),
                  ..._partners.map((partner) => DropdownMenuItem(
                    value: partner['user_id'],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${partner['first_name']} ${partner['last_name']}'),
                        Text(
                          partner['email'],
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedPartnerId = value;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await SupabaseService.client
                      .from('tasks')
                      .update({
                        'assigned_to': selectedPartnerId,
                        'updated_by': SupabaseService.currentUser!.id,
                      })
                      .eq('id', task['id']);

                  Navigator.pop(context);
                  await _loadAllTasks();
                  setState(() {});
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(selectedPartnerId != null 
                            ? 'Tâche assignée avec succès'
                            : 'Assignation supprimée'),
                        backgroundColor: Colors.green,
                      ),
                    );
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1784af),
                foregroundColor: Colors.white,
              ),
              child: const Text('Assigner'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProject(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le projet'),
        content: Text('Êtes-vous sûr de vouloir supprimer le projet "${project['name']}" ?\n\nToutes les tâches associées seront également supprimées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await SupabaseService.client
                    .from('projects')
                    .delete()
                    .eq('id', project['id']);
                
                Navigator.of(context).pop();
                
                // Si on est en vue détail de ce projet, retourner à la grille
                if (_selectedProject != null && _selectedProject!['id'] == project['id']) {
                  _backToGrid();
                }
                
                await _loadData();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Projet supprimé avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                Navigator.of(context).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteTask(Map<String, dynamic> task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la tâche'),
        content: Text('Êtes-vous sûr de vouloir supprimer la tâche "${task['title']}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await SupabaseService.client
                    .from('tasks')
                    .delete()
                    .eq('id', task['id']);

                Navigator.pop(context);
                await _loadAllTasks();
                setState(() {});
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Tâche supprimée avec succès'),
                      backgroundColor: Colors.green,
                    ),
                  );
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============= UTILITAIRES =============

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Actif';
      case 'paused':
        return 'En pause';
      case 'completed':
        return 'Terminé';
      case 'todo':
        return 'À faire';
      case 'in_progress':
        return 'En cours';
      case 'done':
        return 'Terminée';
      default:
        return status;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'urgent':
        return 'URGENT';
      case 'high':
        return 'Haute';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Basse';
      default:
        return priority;
    }
  }
} 