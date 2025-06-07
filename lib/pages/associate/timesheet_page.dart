import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../models/user_role.dart';
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
  bool _isLoading = true;
  
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
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        _loadPartners(),
        _loadTimesheetEntries(),
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
      final response = await SupabaseService.client
          .from('profiles')
          .select('user_id, user_email, first_name, last_name, user_role')
          .eq('user_role', 'partenaire');

      setState(() {
        _partners = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des partenaires: $e');
      // Si la requête échoue, essayer avec la vue ou auth.users directement
      try {
        final response = await SupabaseService.client
            .from('auth.users')
            .select('id, email')
            .limit(50); // Limiter pour éviter trop de données

        setState(() {
          _partners = response.map((user) => {
            'user_id': user['id'],
            'user_email': user['email'],
            'first_name': '',
            'last_name': '',
            'user_role': 'partenaire'
          }).toList();
        });
      } catch (e2) {
        debugPrint('Erreur fallback lors du chargement des partenaires: $e2');
      }
    }
  }

  Future<void> _loadTimesheetEntries() async {
    try {
      // Utiliser la vue créée dans le script SQL
      final response = await SupabaseService.client
          .from('timesheet_entries_with_user')
          .select('*')
          .order('date', ascending: false);

      setState(() {
        _timesheetEntries = List<Map<String, dynamic>>.from(response);
        _filteredEntries = _timesheetEntries;
      });
      
      _applyFiltersAndSort();
    } catch (e) {
      debugPrint('Erreur lors du chargement avec la vue, essai avec requête manuelle: $e');
      
      // Fallback : requête manuelle sans JOIN complexe
      try {
        final response = await SupabaseService.client
            .from('timesheet_entries')
            .select('*')
            .order('date', ascending: false);

        // Enrichir manuellement avec les données utilisateur
        for (var entry in response) {
          try {
            final userResponse = await SupabaseService.client
                .from('auth.users')
                .select('email')
                .eq('id', entry['user_id'])
                .single();
            entry['user_email'] = userResponse['email'];
          } catch (userError) {
            entry['user_email'] = 'Utilisateur inconnu';
          }

          // Essayer de charger les données de tâche
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
            entry['task'] = {'title': 'Tâche inconnue', 'project': {'name': 'Projet inconnu'}};
          }
        }

        setState(() {
          _timesheetEntries = List<Map<String, dynamic>>.from(response);
          _filteredEntries = _timesheetEntries;
        });
        
        _applyFiltersAndSort();
      } catch (e2) {
        debugPrint('Erreur lors du chargement des entrées timesheet (fallback): $e2');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors du chargement des données: $e2'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    return Scaffold(
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
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildTimesheetContent(),
                ),
              ],
            ),
          ),
        ],
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
} 