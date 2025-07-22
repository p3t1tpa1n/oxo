import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/user_role.dart';
import '../../services/supabase_service.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/messaging_button.dart';

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
  List<PlatformFile> _selectedFiles = [];

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
      // Récupérer les informations de l'entreprise du client
      final user = SupabaseService.currentUser;
      if (user != null) {
        // Utiliser les nouvelles méthodes d'entreprise
        final companyStats = await SupabaseService.getClientCompanyStats();
        final recentProjects = await SupabaseService.getClientRecentProjects();
        final activeTasks = await SupabaseService.getClientActiveTasks();
        final userCompany = await SupabaseService.getUserCompany();
        
        setState(() {
          _clientInfo = {
            'name': userCompany?['company_name'] ?? 'Entreprise',
            'id': userCompany?['company_id'],
          };
          _projects = recentProjects;
          _tasks = activeTasks;
        });
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
      floatingActionButton: const MessagingFloatingButton(),
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
                  '${_tasks.where((task) => task['status'] == 'in_progress' || task['status'] == 'todo').length}',
                  'Tâches en cours',
                  Icons.pending_actions,
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildActivityCard(
                  '${_tasks.where((task) => task['status'] == 'done' || task['status'] == 'completed').length}',
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
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        _showNewMissionDialog();
                      },
                      icon: const Icon(Icons.add_business),
                      label: const Text('Proposer un projet'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3D54),
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigation vers la page des projets détaillée
                      },
                      icon: const Icon(Icons.visibility),
                      label: const Text('Voir tous'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
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
                  
                  // Calculer le pourcentage d'avancement des tâches
                  int totalTasks = _tasks.where((task) => task['project_id'] == project['id']).length;
                  int completedTasks = _tasks.where((task) => 
                      task['project_id'] == project['id'] && 
                      (task['status'] == 'done' || task['status'] == 'completed')).length;
                  
                  double taskProgress = totalTasks > 0 ? completedTasks / totalTasks : 0;
                  
                  // Simuler les données de temps (en jours)
                  double estimatedDays = project['estimated_days']?.toDouble() ?? 20.0;
                  double workedDays = project['worked_days']?.toDouble() ?? (estimatedDays * taskProgress);
                  double timeProgress = estimatedDays > 0 ? (workedDays / estimatedDays).clamp(0.0, 1.0) : 0;
                  
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
                                  // Barre de progression des tâches
                                  Text(
                                    'Tâches: ${(taskProgress * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: taskProgress,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getProgressColor(taskProgress),
                                    ),
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  const SizedBox(height: 8),
                                  // Barre de progression du temps
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Temps: ${workedDays.toStringAsFixed(0)}j / ${estimatedDays.toStringAsFixed(0)}j',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${(timeProgress * 100).toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getTimeProgressColor(timeProgress, taskProgress),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: timeProgress,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getTimeProgressColor(timeProgress, taskProgress),
                                    ),
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              children: [
                                // Bouton pour voir le détail
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Color(0xFF1E3D54)),
                                  onPressed: () {
                                    // Ouvrir le détail du projet
                                  },
                                  tooltip: 'Voir le détail',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                ),
                                // Bouton spécifique pour demander plus de temps
                                IconButton(
                                  icon: const Icon(Icons.access_time, color: Colors.orange),
                                  onPressed: () => _showTimeExtensionDialog(project),
                                  tooltip: 'Demander plus de temps',
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ],
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

  // Nouvelle méthode pour la couleur de progression du temps
  Color _getTimeProgressColor(double timeProgress, double taskProgress) {
    // Si le temps dépasse mais les tâches ne sont pas terminées = rouge
    if (timeProgress >= 1.0 && taskProgress < 1.0) {
      return Colors.red;
    }
    // Si le temps est en avance par rapport aux tâches = vert
    if (timeProgress < taskProgress) {
      return Colors.green;
    }
    // Sinon utiliser la couleur normale basée sur le progrès
    return _getProgressColor(timeProgress);
  }



  // Dialog pour demander plus de temps
  void _showTimeExtensionDialog(Map<String, dynamic> project) {
    final TextEditingController reasonController = TextEditingController();
    final TextEditingController daysController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Demande d\'extension de temps'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Projet: ${project['name']}'),
              const SizedBox(height: 16),
              TextField(
                controller: daysController,
                decoration: const InputDecoration(
                  labelText: 'Jours supplémentaires demandés',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Justification',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                                 if (daysController.text.isEmpty || reasonController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                                 try {
                   final daysRequested = double.parse(daysController.text);
                   final success = await SupabaseService.submitTimeExtensionRequest(
                     projectId: project['id'].toString(),
                     daysRequested: daysRequested,
                     reason: reasonController.text,
                   );

                  Navigator.pop(context);
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Demande d\'extension envoyée avec succès'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Erreur lors de l\'envoi de la demande'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Envoyer la demande'),
            ),
          ],
        );
      },
    );
  }

  // Dialog pour proposer une nouvelle mission
  void _showNewMissionDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController budgetController = TextEditingController();
    final TextEditingController daysController = TextEditingController();
    final TextEditingController endDateController = TextEditingController();
    DateTime? selectedEndDate;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Proposer un nouveau projet'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titre du projet',
                        border: OutlineInputBorder(),
                      ),
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
                    TextField(
                      controller: budgetController,
                      decoration: const InputDecoration(
                        labelText: 'Budget estimé (€)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: daysController,
                      decoration: const InputDecoration(
                        labelText: 'Durée estimée (jours)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: endDateController,
                      decoration: const InputDecoration(
                        labelText: 'Date de fin souhaitée',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      readOnly: true,
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 30)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedEndDate = picked;
                            endDateController.text = '${picked.day}/${picked.month}/${picked.year}';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    // Section upload de documents
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Documents joints',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _pickFiles(setState);
                            },
                            icon: const Icon(Icons.attach_file),
                            label: const Text('Choisir des fichiers'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3D54),
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_selectedFiles.isNotEmpty) ...[
                            const Text(
                              'Fichiers sélectionnés:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            ...(_selectedFiles.map((file) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  const Icon(Icons.description, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      file.name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        _selectedFiles.remove(file);
                                      });
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            )).toList()),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _selectedFiles.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || descriptionController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Veuillez remplir le titre et la description'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                                         try {
                       double? estimatedBudget;
                       if (budgetController.text.isNotEmpty) {
                         estimatedBudget = double.parse(budgetController.text);
                       }

                       double? estimatedDays;
                       if (daysController.text.isNotEmpty) {
                         estimatedDays = double.parse(daysController.text);
                       }

                       // Upload des documents d'abord
                       List<Map<String, dynamic>>? documents;
                       if (_selectedFiles.isNotEmpty) {
                         print('🔄 Début upload de ${_selectedFiles.length} fichiers sélectionnés...');
                         documents = await SupabaseService.uploadDocuments(_selectedFiles);
                         print('📋 Documents uploadés: ${documents?.length ?? 0}');
                         if (documents != null && documents.isNotEmpty) {
                           print('✅ Fichiers uploadés avec succès');
                           for (var doc in documents) {
                             print('   - ${doc['file_name']} → ${doc['file_path']}');
                           }
                         } else {
                           print('❌ Aucun document n\'a été uploadé');
                         }
                       } else {
                         print('ℹ️ Aucun fichier sélectionné');
                       }

                       final proposalId = await SupabaseService.submitProjectProposal(
                         title: titleController.text,
                         description: descriptionController.text,
                         estimatedBudget: estimatedBudget,
                         estimatedDays: estimatedDays,
                         endDate: selectedEndDate,
                         documents: documents,
                       );

                       _selectedFiles.clear();
                       Navigator.pop(context);
                       
                       if (proposalId != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Proposition de projet envoyée avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Erreur lors de l\'envoi de la proposition'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } catch (e) {
                      _selectedFiles.clear();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3D54),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Envoyer la proposition'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Méthode pour sélectionner des fichiers
  Future<void> _pickFiles(Function setState) async {
    try {
      print('📁 Ouverture du sélecteur de fichiers...');
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        print('✅ ${result.files.length} fichier(s) sélectionné(s)');
        for (var file in result.files) {
          print('   📄 ${file.name} (${file.size} bytes)');
          print('       Path: ${file.path}');
          print('       Bytes: ${file.bytes?.length ?? 'null'}');
        }
        
        setState(() {
          _selectedFiles.addAll(result.files);
        });
        
        print('🗂️ Total fichiers sélectionnés: ${_selectedFiles.length}');
      } else {
        print('❌ Aucun fichier sélectionné');
      }
    } catch (e) {
      print('💥 Erreur sélection fichiers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection des fichiers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 