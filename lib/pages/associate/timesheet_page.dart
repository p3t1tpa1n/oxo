import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../services/supabase_service.dart';

class TimesheetPage extends StatefulWidget {
  const TimesheetPage({super.key});

  @override
  State<TimesheetPage> createState() => _TimesheetPageState();
}

class _TimesheetPageState extends State<TimesheetPage> {
  List<Map<String, dynamic>> _timesheetEntries = [];
  List<Map<String, dynamic>> _filteredEntries = [];
  List<Map<String, dynamic>> _partners = [];
  List<Map<String, dynamic>> _availabilities = [];
  bool _isLoading = true;
  DateTime _selectedAvailabilityDate = DateTime.now();
  bool _twoWeeksView = false; // Vue 2 prochaines semaines
  List<Map<String, dynamic>> _topAvailablePartners = [];
  bool _loadingAvailablePartners = false;
  
  // Filtres
  String _selectedPartnerId = 'all';
  String _selectedStatus = 'all';
  DateTime? _startDate;
  DateTime? _endDate;
  String _sortBy = 'date'; // date, hours, partner
  bool _sortAscending = false; // Plus récent en premier par défaut

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadTopAvailablePartners();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadPartners(),
        _loadTimesheetEntries(),
        _loadAvailabilities(),
      ]);
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadPartners() async {
    try {
      // Utiliser la fonction get_users qui existe déjà
      final partners = await SupabaseService.getPartners();
      
      setState(() {
        _partners = partners.map((partner) => {
          'user_id': partner['user_id'],
          'user_email': partner['email'] ?? 'Utilisateur inconnu', // Utiliser 'email' directement
          'first_name': partner['first_name'],
          'last_name': partner['last_name'],
          'user_role': partner['role']
        }).toList();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des partenaires: $e');
      setState(() {
        _partners = [];
      });
    }
  }

  Future<void> _loadTimesheetEntries() async {
    try {
      // Charger les entrées de timesheet directement
      final response = await SupabaseService.client
          .from('timesheet_entries')
          .select('*')
          .order('date', ascending: false);

      // Charger tous les utilisateurs une seule fois
      final allUsers = await SupabaseService.client.rpc('get_users');
      final usersMap = <String, Map<String, dynamic>>{};
      for (var user in allUsers) {
        usersMap[user['user_id']] = user;
      }

      // Enrichir les entrées avec les données utilisateur et tâche
      for (var entry in response) {
        // Ajouter les données utilisateur
        final user = usersMap[entry['user_id']];
        entry['user_email'] = user?['email'] ?? 'Utilisateur inconnu';
        entry['user_first_name'] = user?['first_name'] ?? '';
        entry['user_last_name'] = user?['last_name'] ?? '';

        // Charger les données de tâche si nécessaire
        try {
          if (entry['task_id'] != null) {
            final taskResponse = await SupabaseService.client
                .from('tasks')
                .select('title, project_id')
                .eq('id', entry['task_id'])
                .single();
            
            entry['task'] = {'title': taskResponse['title']};
            
            // Charger le projet si possible
            if (taskResponse['project_id'] != null) {
              final projectResponse = await SupabaseService.client
                  .from('projects')
                  .select('name')
                  .eq('id', taskResponse['project_id'])
                  .single();
              entry['task']['project'] = {'name': projectResponse['name']};
            }
          }
        } catch (taskError) {
          debugPrint('Erreur lors du chargement de la tâche: $taskError');
          entry['task'] = {'title': 'Tâche inconnue', 'project': {'name': 'Projet inconnu'}};
        }
      }

      setState(() {
        _timesheetEntries = List<Map<String, dynamic>>.from(response);
        _filteredEntries = _timesheetEntries;
      });
      
      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Erreur lors du chargement des entrées timesheet: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _timesheetEntries = [];
          _filteredEntries = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> filtered = _timesheetEntries;

    // Filtre par partenaire
    if (_selectedPartnerId != 'all') {
      filtered = filtered.where((entry) => entry['user_id'] == _selectedPartnerId).toList();
    }

    // Filtre par statut
    if (_selectedStatus != 'all') {
      filtered = filtered.where((entry) => entry['status'] == _selectedStatus).toList();
    }

    // Filtre par date
    if (_startDate != null) {
      filtered = filtered.where((entry) {
        final entryDate = DateTime.tryParse(entry['date'] ?? '');
        return entryDate != null && entryDate.isAfter(_startDate!.subtract(const Duration(days: 1)));
      }).toList();
    }

    if (_endDate != null) {
      filtered = filtered.where((entry) {
        final entryDate = DateTime.tryParse(entry['date'] ?? '');
        return entryDate != null && entryDate.isBefore(_endDate!.add(const Duration(days: 1)));
      }).toList();
    }

    // Tri
    filtered.sort((a, b) {
      dynamic valueA, valueB;
      
      switch (_sortBy) {
        case 'date':
          valueA = DateTime.tryParse(a['date'] ?? '') ?? DateTime.now();
          valueB = DateTime.tryParse(b['date'] ?? '') ?? DateTime.now();
          break;
        case 'hours':
          valueA = (a['hours'] ?? 0.0).toDouble();
          valueB = (b['hours'] ?? 0.0).toDouble();
          break;
        case 'partner':
          // Utiliser user_email pour le tri par partenaire
          valueA = (a['user_email'] ?? '').toString().toLowerCase();
          valueB = (b['user_email'] ?? '').toString().toLowerCase();
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
      _filteredEntries = filtered;
    });
  }

  double _getTotalHours() {
    return _filteredEntries.fold(0.0, (sum, entry) => sum + (entry['hours'] ?? 0.0).toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Row(
          children: [
            SideMenu(
              userRole: SupabaseService.currentUserRole,
              selectedRoute: '/timesheet',
            ),
            Expanded(
              child: Column(
                children: [
                  const TopBar(title: 'Timesheet des Partenaires'),
                  const TabBar(
                    labelColor: Color(0xFF1784af),
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Color(0xFF1784af),
                    tabs: [
                      Tab(
                        icon: Icon(Icons.schedule),
                        text: 'Timesheet',
                      ),
                      Tab(
                        icon: Icon(Icons.calendar_today),
                        text: 'Disponibilités',
                      ),
                    ],
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : TabBarView(
                            children: [
                              _buildTimesheetContent(),
                              _buildAvailabilityContent(),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimesheetContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Statistiques globales
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Entrées',
                      '${_filteredEntries.length}',
                      Icons.assignment,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Total Heures',
                      '${_getTotalHours().toStringAsFixed(1)}h',
                      Icons.timer,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Partenaires Actifs',
                      '${_filteredEntries.map((e) => e['user_id']).toSet().length}',
                      Icons.people,
                      Colors.orange,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Moyenne/Entrée',
                      _filteredEntries.isNotEmpty 
                          ? '${(_getTotalHours() / _filteredEntries.length).toStringAsFixed(1)}h'
                          : '0h',
                      Icons.analytics,
                      Colors.purple,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Filtres
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Première ligne de filtres - responsive
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isNarrow = constraints.maxWidth < 1000;
                      
                      if (isNarrow) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedPartnerId,
                                    decoration: const InputDecoration(
                                      labelText: 'Partenaire',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: [
                                      const DropdownMenuItem(value: 'all', child: Text('Tous')),
                                      ..._partners.map((partner) => DropdownMenuItem(
                                        value: partner['user_id'],
                                        child: Text(
                                          _getPartnerDisplayName(partner),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPartnerId = value!;
                                      });
                                      _applyFiltersAndSort();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedStatus,
                                    decoration: const InputDecoration(
                                      labelText: 'Statut',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'all', child: Text('Tous')),
                                      DropdownMenuItem(value: 'pending', child: Text('Attente')),
                                      DropdownMenuItem(value: 'approved', child: Text('Approuvé')),
                                      DropdownMenuItem(value: 'rejected', child: Text('Rejeté')),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedStatus = value!;
                                      });
                                      _applyFiltersAndSort();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _sortBy,
                                    decoration: const InputDecoration(
                                      labelText: 'Tri',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'date', child: Text('Date')),
                                      DropdownMenuItem(value: 'hours', child: Text('Heures')),
                                      DropdownMenuItem(value: 'partner', child: Text('Partenaire')),
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
                              child: DropdownButtonFormField<String>(
                                value: _selectedPartnerId,
                                decoration: const InputDecoration(
                                  labelText: 'Partenaire',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  const DropdownMenuItem(value: 'all', child: Text('Tous les partenaires')),
                                  ..._partners.map((partner) => DropdownMenuItem(
                                    value: partner['user_id'],
                                    child: Text(_getPartnerDisplayName(partner)),
                                  )),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPartnerId = value!;
                                  });
                                  _applyFiltersAndSort();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Statut',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'all', child: Text('Tous les statuts')),
                                  DropdownMenuItem(value: 'pending', child: Text('En attente')),
                                  DropdownMenuItem(value: 'approved', child: Text('Approuvé')),
                                  DropdownMenuItem(value: 'rejected', child: Text('Rejeté')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value!;
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
                                  DropdownMenuItem(value: 'date', child: Text('Date')),
                                  DropdownMenuItem(value: 'hours', child: Text('Heures')),
                                  DropdownMenuItem(value: 'partner', child: Text('Partenaire')),
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
                  // Deuxième ligne - Filtres de date responsive
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isNarrow = constraints.maxWidth < 800;
                      
                      if (isNarrow) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _startDate = date;
                                        });
                                        _applyFiltersAndSort();
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Début',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_today, size: 20),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: Text(
                                        _startDate != null 
                                            ? DateFormat('dd/MM').format(_startDate!)
                                            : 'Début',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _endDate ?? DateTime.now(),
                                        firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                                        lastDate: DateTime.now(),
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _endDate = date;
                                        });
                                        _applyFiltersAndSort();
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Fin',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_today, size: 20),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      child: Text(
                                        _endDate != null 
                                            ? DateFormat('dd/MM').format(_endDate!)
                                            : 'Fin',
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedPartnerId = 'all';
                                    _selectedStatus = 'all';
                                    _startDate = null;
                                    _endDate = null;
                                    _sortBy = 'date';
                                    _sortAscending = false;
                                  });
                                  _applyFiltersAndSort();
                                },
                                child: const Text('Réinitialiser'),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _startDate = date;
                                    });
                                    _applyFiltersAndSort();
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date de début',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  child: Text(
                                    _startDate != null 
                                        ? DateFormat('dd/MM/yyyy').format(_startDate!)
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
                                    initialDate: _endDate ?? DateTime.now(),
                                    firstDate: _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
                                    lastDate: DateTime.now(),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _endDate = date;
                                    });
                                    _applyFiltersAndSort();
                                  }
                                },
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date de fin',
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  child: Text(
                                    _endDate != null 
                                        ? DateFormat('dd/MM/yyyy').format(_endDate!)
                                        : 'Sélectionner',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _selectedPartnerId = 'all';
                                  _selectedStatus = 'all';
                                  _startDate = null;
                                  _endDate = null;
                                  _sortBy = 'date';
                                  _sortAscending = false;
                                });
                                _applyFiltersAndSort();
                              },
                              child: const Text('Réinitialiser'),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Liste des entrées
          Expanded(
            child: _filteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune entrée timesheet trouvée',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Modifiez vos filtres ou attendez que les partenaires saisissent leurs heures',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredEntries.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredEntries[index];
                      return _buildTimesheetEntryCard(entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTimesheetEntryCard(Map<String, dynamic> entry) {
    final status = entry['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final hours = (entry['hours'] ?? 0.0).toDouble();
    final date = DateTime.tryParse(entry['date'] ?? '') ?? DateTime.now();
    final userEmail = entry['user_email'] ?? 'Utilisateur inconnu';
    final taskTitle = entry['task']?['title'] ?? 'Tâche inconnue';
    final projectName = entry['task']?['project']?['name'] ?? 'Projet inconnu';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: statusColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userEmail,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3D54),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$projectName - $taskTitle',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
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
                    const SizedBox(width: 12),
                    Text(
                      '${hours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1784af),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (entry['description']?.isNotEmpty ?? false) ...[
              Text(
                entry['description'],
                style: TextStyle(
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(DateTime.parse(entry['created_at'] ?? DateTime.now().toIso8601String())),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                if (status == 'pending') ...[
                  const Spacer(),
                  TextButton(
                    onPressed: () => _updateEntryStatus(entry['id'], 'approved'),
                    child: const Text('Approuver', style: TextStyle(color: Colors.green)),
                  ),
                  TextButton(
                    onPressed: () => _updateEntryStatus(entry['id'], 'rejected'),
                    child: const Text('Rejeter', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      case 'pending':
        return 'En attente';
      default:
        return status;
    }
  }

  Future<void> _updateEntryStatus(dynamic entryId, String newStatus) async {
    try {
      await SupabaseService.client
          .from('timesheet_entries')
          .update({'status': newStatus})
          .eq('id', entryId);

      _loadTimesheetEntries();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour: ${_getStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPartnerDisplayName(Map<String, dynamic> partner) {
    // Prioriser nom prénom si disponible
    final firstName = partner['first_name'];
    final lastName = partner['last_name'];
    
    if (firstName != null && lastName != null && firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    
    // Sinon utiliser l'email (partie avant @)
    final email = partner['user_email'];
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    
    // Fallback
    return 'Partenaire';
  }

  // ==========================================
  // GESTION DES DISPONIBILITÉS DES PARTENAIRES
  // ==========================================

  Future<void> _loadAvailabilities() async {
    try {
      debugPrint('Chargement des disponibilités des partenaires...');
      
      DateTime startDate;
      DateTime endDate;
      if (_twoWeeksView) {
        final now = DateTime.now();
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 13));
      } else {
        startDate = DateTime(_selectedAvailabilityDate.year, _selectedAvailabilityDate.month, 1);
        endDate = DateTime(_selectedAvailabilityDate.year, _selectedAvailabilityDate.month + 1, 0);
      }
      
      debugPrint('Période demandée: ${startDate.toIso8601String().split('T')[0]} - ${endDate.toIso8601String().split('T')[0]}');
      
      final availabilities = await SupabaseService.getPartnerAvailabilityForPeriod(
        startDate: startDate,
        endDate: endDate,
      );
      
      debugPrint('${availabilities.length} disponibilités chargées');
      
      setState(() {
        _availabilities = availabilities;
      });
      
      debugPrint('State mis à jour avec ${_availabilities.length} disponibilités');
    } catch (e) {
      debugPrint('Erreur lors du chargement des disponibilités: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des disponibilités: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadTopAvailablePartners() async {
    setState(() => _loadingAvailablePartners = true);
    try {
      final partners = await SupabaseService.getPartnersAvailableAtLeast(periodDays: 14, minAvailableDays: 7);
      if (mounted) setState(() => _topAvailablePartners = partners);
    } catch (e) {
      debugPrint('Erreur chargement partenaires >=7/14: $e');
      if (mounted) setState(() => _topAvailablePartners = []);
    } finally {
      if (mounted) setState(() => _loadingAvailablePartners = false);
    }
  }

  Widget _buildAvailabilityContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildAvailabilityHeader(),
          const SizedBox(height: 16),
          _buildAvailabilityFilters(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildAvailabilityList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF1784af),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Disponibilités des Partenaires',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1784af),
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _loadAvailabilities,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1784af),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Consultez les disponibilités de vos partenaires pour planifier efficacement vos projets.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityFilters() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Sélecteur de mois
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mois de consultation',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedAvailabilityDate = DateTime(
                                _selectedAvailabilityDate.year,
                                _selectedAvailabilityDate.month - 1,
                              );
                            });
                            _loadAvailabilities();
                          },
                          icon: const Icon(Icons.chevron_left),
                          iconSize: 20,
                        ),
                        Expanded(
                          child: Text(
                            DateFormat('MMMM yyyy', 'fr_FR').format(_selectedAvailabilityDate),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _selectedAvailabilityDate = DateTime(
                                _selectedAvailabilityDate.year,
                                _selectedAvailabilityDate.month + 1,
                              );
                            });
                            _loadAvailabilities();
                          },
                          icon: const Icon(Icons.chevron_right),
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Toggle 2 prochaines semaines
            ElevatedButton.icon(
              onPressed: () async {
                setState(() {
                  _twoWeeksView = !_twoWeeksView;
                });
                await _loadAvailabilities();
              },
              icon: const Icon(Icons.view_week),
              label: Text(_twoWeeksView ? 'Vue mois' : '2 prochaines semaines'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _twoWeeksView ? const Color(0xFF1784af) : Colors.blueGrey,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            // Bouton partenaires disponibles >= 7 jours / 14
            ElevatedButton.icon(
              onPressed: _loadingAvailablePartners
                  ? null
                  : () async {
                      if (_topAvailablePartners.isEmpty) {
                        await _loadTopAvailablePartners();
                      }
                      _showTopAvailablePartnersDialog();
                    },
              icon: const Icon(Icons.filter_alt),
              label: Text(_loadingAvailablePartners ? 'Chargement...' : 'Dispo ≥ 7/14'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            // Bouton pour voir aujourd'hui
            ElevatedButton.icon(
              onPressed: () async {
                final partners = await SupabaseService.getAvailablePartnersForDate(DateTime.now());
                _showAvailablePartnersDialog(DateTime.now(), partners);
              },
              icon: const Icon(Icons.today),
              label: const Text('Disponibles aujourd\'hui'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityList() {
    if (_availabilities.isEmpty) {
      return _buildEmptyAvailabilityState();
    }

    // Grouper les disponibilités par date
    final Map<String, List<Map<String, dynamic>>> groupedAvailabilities = {};
    for (var availability in _availabilities) {
      final date = availability['date'];
      if (groupedAvailabilities[date] == null) {
        groupedAvailabilities[date] = [];
      }
      groupedAvailabilities[date]!.add(availability);
    }

    final sortedDates = groupedAvailabilities.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayAvailabilities = groupedAvailabilities[date]!;
        final parsedDate = DateTime.parse(date);
        
        return _buildDayAvailabilityCard(parsedDate, dayAvailabilities);
      },
    );
  }

  Widget _buildDayAvailabilityCard(DateTime date, List<Map<String, dynamic>> dayAvailabilities) {
    final availablePartners = dayAvailabilities.where((a) => a['is_available'] == true).toList();
    final unavailablePartners = dayAvailabilities.where((a) => a['is_available'] == false).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getDateColor(date),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    DateFormat('EEEE d MMMM', 'fr_FR').format(date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '${availablePartners.length} disponible(s) • ${unavailablePartners.length} indisponible(s)',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (availablePartners.isNotEmpty) ...[
              const Text(
                '✅ Partenaires disponibles',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: availablePartners.map((partner) => _buildPartnerChip(partner, true)).toList(),
              ),
            ],
            if (unavailablePartners.isNotEmpty) ...[
              if (availablePartners.isNotEmpty) const SizedBox(height: 12),
              const Text(
                '❌ Partenaires indisponibles',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: unavailablePartners.map((partner) => _buildPartnerChip(partner, false)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerChip(Map<String, dynamic> partner, bool isAvailable) {
    final name = partner['partner_name'] ?? 'Partenaire inconnu';
    final type = partner['availability_type'];
    final startTime = partner['start_time'];
    final endTime = partner['end_time'];
    
    String subtitle = '';
    if (isAvailable && type == 'partial_day' && startTime != null && endTime != null) {
      subtitle = ' ($startTime - $endTime)';
    }

    return Chip(
      avatar: CircleAvatar(
        backgroundColor: isAvailable ? Colors.green : Colors.red,
        child: Text(
          name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      label: Text('$name$subtitle'),
      backgroundColor: isAvailable ? Colors.green.shade50 : Colors.red.shade50,
      side: BorderSide(
        color: isAvailable ? Colors.green.shade200 : Colors.red.shade200,
      ),
      onDeleted: partner['notes'] != null ? () {
        _showPartnerAvailabilityDetails(partner);
      } : null,
      deleteIcon: partner['notes'] != null ? const Icon(Icons.info_outline, size: 16) : null,
    );
  }

  Widget _buildEmptyAvailabilityState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune disponibilité trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les partenaires n\'ont pas encore défini leurs disponibilités\npour ce mois.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadAvailabilities,
            icon: const Icon(Icons.refresh),
            label: const Text('Actualiser'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1784af),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDateColor(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate.isAtSameMomentAs(today)) {
      return const Color(0xFF1784af); // Aujourd'hui
    } else if (targetDate.isBefore(today)) {
      return Colors.grey; // Passé
    } else {
      return Colors.blue; // Futur
    }
  }

  void _showAvailablePartnersDialog(DateTime date, List<Map<String, dynamic>> partners) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Partenaires disponibles le ${DateFormat('dd/MM/yyyy').format(date)}'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: partners.isEmpty
              ? const Center(
                  child: Text('Aucun partenaire disponible ce jour'),
                )
              : ListView.builder(
                  itemCount: partners.length,
                  itemBuilder: (context, index) {
                    final partner = partners[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          (partner['partner_name'] ?? '')
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(partner['partner_name'] ?? 'Partenaire inconnu'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(partner['partner_email'] ?? ''),
                          if (partner['start_time'] != null && partner['end_time'] != null)
                            Text('Horaires: ${partner['start_time']} - ${partner['end_time']}'),
                        ],
                      ),
                      trailing: partner['availability_type'] == 'partial_day'
                          ? const Chip(
                              label: Text('Partiel'),
                              backgroundColor: Colors.orange,
                            )
                          : const Chip(
                              label: Text('Complet'),
                              backgroundColor: Colors.green,
                            ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showTopAvailablePartnersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partenaires disponibles ≥ 7 jours sur 14'),
        content: SizedBox(
          width: double.maxFinite,
          height: 360,
          child: _topAvailablePartners.isEmpty
              ? const Center(child: Text('Aucun partenaire ne satisfait ce critère.'))
              : ListView.builder(
                  itemCount: _topAvailablePartners.length,
                  itemBuilder: (context, index) {
                    final p = _topAvailablePartners[index];
                    final name = (p['partner_name'] ?? '').toString();
                    final email = (p['partner_email'] ?? '').toString();
                    final available = (p['available_days'] ?? 0) as int;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Text(
                          name
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      title: Text(name.isNotEmpty ? name : 'Partenaire'),
                      subtitle: Text(email),
                      trailing: Chip(
                        label: Text('$available/14 j'),
                        backgroundColor: Colors.green.shade50,
                        side: BorderSide(color: Colors.green.shade200),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showPartnerAvailabilityDetails(Map<String, dynamic> partner) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Détails - ${partner['partner_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('📧 Email: ${partner['partner_email'] ?? 'Non spécifié'}'),
            const SizedBox(height: 8),
            Text('📋 Statut: ${partner['is_available'] == true ? "Disponible" : "Indisponible"}'),
            const SizedBox(height: 8),
            Text('📌 Type: ${_getAvailabilityTypeLabel(partner['availability_type'])}'),
            if (partner['start_time'] != null || partner['end_time'] != null) ...[
              const SizedBox(height: 8),
              Text('⏰ Horaires: ${partner['start_time'] ?? "Non défini"} - ${partner['end_time'] ?? "Non défini"}'),
            ],
            if (partner['notes'] != null && partner['notes'].toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('📝 Notes: ${partner['notes']}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  String _getAvailabilityTypeLabel(String? type) {
    switch (type) {
      case 'full_day':
        return 'Journée complète';
      case 'partial_day':
        return 'Journée partielle';
      case 'unavailable':
        return 'Indisponible';
      default:
        return 'Non défini';
    }
  }
} 