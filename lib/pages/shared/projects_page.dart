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

class _ProjectsPageState extends State<ProjectsPage> {
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _filteredProjects = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'name'; // name, created_at, status
  String _filterStatus = 'all'; // all, active, completed, paused
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await SupabaseService.client
          .from('projects')
          .select('''
            *,
            tasks:tasks(count)
          ''')
          .order('created_at', ascending: false);

      setState(() {
        _projects = List<Map<String, dynamic>>.from(response);
        _filteredProjects = _projects;
        _isLoading = false;
      });
      
      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Erreur lors du chargement des projets: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des projets: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    String selectedStatus = 'active';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouveau Projet'),
          content: SingleChildScrollView(
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
                            initialDate: DateTime.now(),
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
                            initialDate: startDate ?? DateTime.now(),
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
                  await SupabaseService.client.from('projects').insert({
                    'name': nameController.text,
                    'description': descriptionController.text,
                    'status': selectedStatus,
                    'start_date': startDate?.toIso8601String(),
                    'end_date': endDate?.toIso8601String(),
                    'created_at': DateTime.now().toIso8601String(),
                    'updated_at': DateTime.now().toIso8601String(),
                  });

                  Navigator.of(context).pop();
                  _loadProjects();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Projet créé avec succès'),
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
              child: const Text('Créer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            userRole: SupabaseService.currentUserRole,
            selectedRoute: '/projects',
          ),
          Expanded(
            child: Column(
              children: [
                const TopBar(title: 'Gestion des Projets'),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildProjectsContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateProjectDialog,
        backgroundColor: const Color(0xFF1784af),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProjectsContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Filtres et recherche
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Interface responsive pour les filtres
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isNarrow = constraints.maxWidth < 1000;
                      
                      if (isNarrow) {
                        return Column(
                          children: [
                            // Recherche en pleine largeur
                            TextField(
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
                            const SizedBox(height: 12),
                            // Filtres sur deux lignes
                            Row(
                              children: [
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
                                      DropdownMenuItem(value: 'paused', child: Text('Pause')),
                                      DropdownMenuItem(value: 'completed', child: Text('Fini')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _filterStatus = value!;
                                      });
                                      _applyFiltersAndSort();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _sortBy,
                                    decoration: const InputDecoration(
                                      labelText: 'Tri',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'name', child: Text('Nom')),
                                      DropdownMenuItem(value: 'created_at', child: Text('Date')),
                                      DropdownMenuItem(value: 'status', child: Text('Statut')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _sortBy = value!;
                                      });
                                      _applyFiltersAndSort();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                    size: 20,
                                  ),
                                  tooltip: _sortAscending ? 'Croissant' : 'Décroissant',
                                ),
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Row(
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
                                  DropdownMenuItem(value: 'created_at', child: Text('Date de création')),
                                  DropdownMenuItem(value: 'status', child: Text('Statut')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _sortBy = value!;
                                  });
                                  _applyFiltersAndSort();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
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
                              tooltip: _sortAscending ? 'Tri croissant' : 'Tri décroissant',
                            ),
                          ],
                        );
                      }
                    },
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
          ),
          const SizedBox(height: 24),
          // Liste des projets - responsive grid
          Expanded(
            child: _filteredProjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun projet trouvé',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Créez votre premier projet ou modifiez vos filtres',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      // Grid responsive
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
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final status = project['status'] ?? 'active';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  onSelected: (value) {
                    if (value == 'edit') {
                      // TODO: Implémenter l'édition
                    } else if (value == 'delete') {
                      _deleteProject(project);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Modifier'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer'),
                    ),
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
                Icon(Icons.task_alt, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  '${project['tasks']?.length ?? 0} tâche(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

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
      default:
        return status;
    }
  }

  void _deleteProject(Map<String, dynamic> project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le projet "${project['name']}" ?'),
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
                _loadProjects();
                
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
                      content: Text('Erreur lors de la suppression: $e'),
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
} 