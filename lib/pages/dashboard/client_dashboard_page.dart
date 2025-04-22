import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_role.dart';
import '../../services/supabase_service.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';

class ClientDashboardPage extends StatefulWidget {
  const ClientDashboardPage({super.key});

  @override
  State<ClientDashboardPage> createState() => _ClientDashboardPageState();
}

class _ClientDashboardPageState extends State<ClientDashboardPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _projects = [];
  List<Map<String, dynamic>> _tasks = [];
  Map<String, dynamic>? _clientInfo;
  String _clientId = '';

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
      // Récupérer l'ID du client associé à cet utilisateur
      final user = SupabaseService.currentUser;
      if (user != null) {
        final clientMapping = await SupabaseService.getClientMapping(user.id);
        if (clientMapping != null && clientMapping.isNotEmpty) {
          _clientId = clientMapping['client_id'];
          
          // Charger les informations du client
          final clientInfo = await SupabaseService.getClientById(_clientId);
          if (clientInfo != null) {
            setState(() {
              _clientInfo = clientInfo;
            });
          }
          
          // Charger les projets du client
          final projects = await SupabaseService.getClientProjects(_clientId);
          
          // Charger les tâches associées aux projets du client
          final tasks = await SupabaseService.getClientTasks(_clientId);
          
          setState(() {
            _projects = projects;
            _tasks = tasks;
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 1000,
            minHeight: 800,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(child: TopBar(title: 'Espace Client')),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (screenWidth > 700) 
                      SideMenu(
                        userRole: UserRole.client,
                        selectedRoute: '/client',
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildDashboardContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildProjectsSection(),
          const SizedBox(height: 24),
          _buildTasksSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final clientName = _clientInfo?['name'] ?? 'Client';
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF1E3D54),
                  child: Text(
                    clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue, $clientName',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3D54),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tableau de bord - ${DateFormat('d MMMM yyyy', 'fr_FR').format(DateTime.now())}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Résumé de votre activité',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3D54),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildActivityCard(
                  '${_projects.length}',
                  'Projets actifs',
                  Icons.business_center,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildActivityCard(
                  '${_tasks.where((task) => task['status'] == 'in_progress').length}',
                  'Tâches en cours',
                  Icons.pending_actions,
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildActivityCard(
                  '${_tasks.where((task) => task['status'] == 'completed').length}',
                  'Tâches terminées',
                  Icons.task_alt,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vos projets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3D54),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigation vers la page des projets détaillée
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Voir tous les projets'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3D54),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_projects.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Aucun projet en cours',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _projects.length > 3 ? 3 : _projects.length,
                itemBuilder: (context, index) {
                  final project = _projects[index];
                  final startDate = project['start_date'] != null
                      ? DateTime.parse(project['start_date'])
                      : null;
                  final endDate = project['end_date'] != null
                      ? DateTime.parse(project['end_date'])
                      : null;
                  
                  // Calculer le pourcentage d'avancement
                  int totalTasks = _tasks.where((task) => task['project_id'] == project['id']).length;
                  int completedTasks = _tasks.where((task) => 
                      task['project_id'] == project['id'] && task['status'] == 'completed').length;
                  
                  double progress = totalTasks > 0 ? completedTasks / totalTasks : 0;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
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
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3D54),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(project['status']).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _getStatusColor(project['status']).withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                _formatStatus(project['status']),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(project['status']),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (project['description'] != null && project['description'].toString().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              project['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            if (startDate != null && endDate != null) ...[
                              Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Icon(Icons.assignment, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '$completedTasks/$totalTasks tâches',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Avancement: ${(progress * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getProgressColor(progress),
                                    ),
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Color(0xFF1E3D54)),
                              onPressed: () {
                                // Ouvrir le détail du projet
                              },
                              tooltip: 'Voir le détail',
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection() {
    // Afficher uniquement les tâches en cours ou terminées récemment
    final recentTasks = _tasks.where((task) {
      return task['status'] == 'in_progress' || task['status'] == 'completed';
    }).toList();
    
    // Trier par statut et date de création
    recentTasks.sort((a, b) {
      if (a['status'] == 'in_progress' && b['status'] != 'in_progress') {
        return -1;
      } else if (a['status'] != 'in_progress' && b['status'] == 'in_progress') {
        return 1;
      } else {
        final aDate = DateTime.parse(a['created_at']);
        final bDate = DateTime.parse(b['created_at']);
        return bDate.compareTo(aDate); // Plus récent en premier
      }
    });
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tâches récentes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3D54),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigation vers la page des tâches détaillée
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('Voir toutes les tâches'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3D54),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (recentTasks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Aucune tâche récente',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentTasks.length > 5 ? 5 : recentTasks.length,
                itemBuilder: (context, index) {
                  final task = recentTasks[index];
                  final dueDate = task['due_date'] != null
                      ? DateTime.parse(task['due_date'])
                      : null;
                  
                  final projectName = _projects
                      .firstWhere((project) => project['id'] == task['project_id'], 
                          orElse: () => {'name': 'Projet inconnu'})['name'];
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getTaskStatusColor(task['status']),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                task['title'] ?? 'Tâche sans titre',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3D54),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Projet: $projectName',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (dueDate != null) ...[
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Échéance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                DateFormat('dd/MM/yyyy').format(dueDate),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isOverdue(dueDate, task['status']) 
                                      ? Colors.red 
                                      : Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTaskStatusColor(task['status']).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatTaskStatus(task['status']),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getTaskStatusColor(task['status']),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'actif':
        return Colors.green;
      case 'inactif':
        return Colors.grey;
      case 'terminé':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'actif':
        return 'Actif';
      case 'inactif':
        return 'Inactif';
      case 'terminé':
        return 'Terminé';
      default:
        return status != null 
          ? status[0].toUpperCase() + status.substring(1)
          : 'Inconnu';
    }
  }

  Color _getProgressColor(double progress) {
    if (progress < 0.3) {
      return Colors.red;
    } else if (progress < 0.7) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  Color _getTaskStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTaskStatus(String? status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'in_progress':
        return 'En cours';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status != null 
          ? status[0].toUpperCase() + status.substring(1)
          : 'Inconnu';
    }
  }

  bool _isOverdue(DateTime dueDate, String? status) {
    return status != 'completed' && status != 'cancelled' && dueDate.isBefore(DateTime.now());
  }
} 