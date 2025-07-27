import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../widgets/calendar_widget.dart';
import 'dart:async';
import '../../widgets/messaging_button.dart';

class PartnerDashboardPage extends StatefulWidget {
  const PartnerDashboardPage({super.key});

  @override
  State<PartnerDashboardPage> createState() => _PartnerDashboardPageState();
}

class _PartnerDashboardPageState extends State<PartnerDashboardPage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _tasks = [];
  Map<String, dynamic> _statistics = {
    'completion_rate': 0.0,
    'total_tasks': 0,
    'completed_tasks': 0,
    'urgent_tasks': 0,
  };
  bool _isLoading = true;
  String? _error;
  
  // Variables pour le chronomètre
  final Map<String, Stopwatch> _stopwatches = {};
  final Map<String, Timer> _timers = {};
  final Map<String, Duration> _elapsedTimes = {};

  // Variables pour le timesheet
  Map<String, double> _taskHours = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // Arrêter tous les chronomètres
    _timers.forEach((_, timer) => timer.cancel());
    super.dispose();
  }

  // Méthode pour formater la durée
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  // Méthode pour démarrer le chronomètre
  void _startStopwatch(String taskId) {
    if (!_stopwatches.containsKey(taskId)) {
      _stopwatches[taskId] = Stopwatch();
      _elapsedTimes[taskId] = Duration.zero;
    }
    
    _stopwatches[taskId]!.start();
    _timers[taskId] = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _elapsedTimes[taskId] = _stopwatches[taskId]!.elapsed;
        });
      }
    });
  }

  // Méthode pour mettre en pause le chronomètre
  void _pauseStopwatch(String taskId) {
    _stopwatches[taskId]?.stop();
    _timers[taskId]?.cancel();
    _timers.remove(taskId);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les données nécessaires
      await _loadUserProfile();
      await _loadTasks();
      await _loadStatistics();
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

  Future<void> _loadUserProfile() async {
    // Implementation of _loadUserProfile method
  }

  Future<void> _loadTasks() async {
    if (!mounted || SupabaseService.currentUser == null) {
      debugPrint('_loadTasks: Non monté ou utilisateur non connecté');
      debugPrint('mounted: $mounted');
      debugPrint('currentUser: ${SupabaseService.currentUser}');
      return;
    }

    setState(() {
      _isLoading = true;
    });
    
    try {
      debugPrint('_loadTasks: Début du chargement des tâches');
      debugPrint('ID utilisateur: ${SupabaseService.currentUser!.id}');
      
      // Requête simplifiée sans les JOINs problématiques
      final response = await SupabaseService.client
          .from('tasks')
          .select('*')
          .or('user_id.eq.${SupabaseService.currentUser!.id},partner_id.eq.${SupabaseService.currentUser!.id},assigned_to.eq.${SupabaseService.currentUser!.id}')
          .order('created_at', ascending: false);

      debugPrint('_loadTasks: Réponse reçue');
      debugPrint('Nombre de tâches: ${response.length}');
      debugPrint('Contenu de la réponse: $response');
      
      if (!mounted) return;

      // Enrichir les données avec les informations de projet si nécessaire
      for (var task in response) {
        if (task['project_id'] != null) {
          try {
            final projectResponse = await SupabaseService.client
                .from('projects')
                .select('id, name, description, status')
                .eq('id', task['project_id'])
                .single();
            task['projects'] = projectResponse;
          } catch (e) {
            debugPrint('Erreur lors du chargement du projet ${task['project_id']}: $e');
            task['projects'] = null;
          }
        }
      }

      // Charger les heures de timesheet pour chaque tâche
      await _loadTimesheetHours();

      setState(() {
        _tasks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      debugPrint('_loadTasks: État mis à jour avec ${_tasks.length} tâches');
    } catch (e, stackTrace) {
      debugPrint('_loadTasks: Erreur lors du chargement des tâches');
      debugPrint('Erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
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

  Future<void> _loadTimesheetHours() async {
    try {
      final timesheetResponse = await SupabaseService.client
          .from('timesheet_entries')
          .select('task_id, hours')
          .eq('user_id', SupabaseService.currentUser!.id);

      final Map<String, double> taskHours = {};
      for (var entry in timesheetResponse) {
        final taskId = entry['task_id'].toString();
        final hours = (entry['hours'] ?? 0.0).toDouble();
        taskHours[taskId] = (taskHours[taskId] ?? 0.0) + hours;
      }

      if (mounted) {
        setState(() {
          _taskHours = taskHours;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des heures timesheet: $e');
    }
  }

  double _calculateTotalHours(dynamic taskId) {
    return _taskHours[taskId.toString()] ?? 0.0;
  }

  Future<void> _loadStatistics() async {
    if (!mounted || SupabaseService.currentUser == null) {
      debugPrint('_loadStatistics: Non monté ou utilisateur non connecté');
      debugPrint('mounted: $mounted');
      debugPrint('currentUser: ${SupabaseService.currentUser}');
      return;
    }
    
    try {
      debugPrint('_loadStatistics: Début du chargement des statistiques');
      debugPrint('ID utilisateur: ${SupabaseService.currentUser!.id}');
      
      final completedTasks = _tasks.where((task) => task['status'] == 'done').length;
      final inProgressTasks = _tasks.where((task) => task['status'] == 'in_progress').length;
      final totalTasks = _tasks.length;

      debugPrint('_loadStatistics: Calcul des statistiques');
      debugPrint('Tâches terminées: $completedTasks');
      debugPrint('Tâches en cours: $inProgressTasks');
      debugPrint('Total des tâches: $totalTasks');

      // Calcul correct du taux d'achèvement : 100% si toutes les tâches sont terminées
      double completionRate = 0.0;
      if (totalTasks > 0) {
        completionRate = (completedTasks / totalTasks) * 100;
      }

      setState(() {
        _statistics = {
          'completion_rate': completionRate,
          'total_tasks': totalTasks,
          'completed_tasks': completedTasks,
          'urgent_tasks': _tasks.where((task) => task['priority'] == 'urgent').length,
        };
        debugPrint('_loadStatistics: État mis à jour avec taux d\'achèvement: ${completionRate.toStringAsFixed(1)}%');
      });
    } catch (e, stackTrace) {
      debugPrint('_loadStatistics: Erreur lors du chargement des statistiques');
      debugPrint('Erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Menu latéral simplifié
          NavigationRail(
            extended: true,
            minWidth: 200,
            minExtendedWidth: 200,
            backgroundColor: const Color(0xFF1E3D54),
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              if (index == 1) {
                // Rediriger vers la messagerie universelle
                Navigator.pushNamed(context, '/messaging');
              } else {
                setState(() {
                  _selectedIndex = index;
                });
              }
            },
            labelType: NavigationRailLabelType.none,
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, size: 30, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Partenaire',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.dashboard, color: Colors.white),
                label: Text('Dashboard', style: TextStyle(color: Colors.white)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.chat, color: Colors.white),
                label: Text('Discussion', style: TextStyle(color: Colors.white)),
              ),
            ],
            trailing: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
              child: InkWell(
                onTap: () async {
                  // Afficher une boîte de dialogue de confirmation
                  final bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Confirmation'),
                        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text(
                              'Déconnexion',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  
                  // Si l'utilisateur a confirmé, procéder à la déconnexion
                  if (confirm == true && mounted) {
                    await SupabaseService.signOut();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.white70,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Déconnexion',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Contenu principal
          Expanded(
            child: Material(
              color: Colors.grey[100],
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildDashboardPage(),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const MessagingFloatingButton(),
          const SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _showCreateTaskDialog,
            backgroundColor: const Color(0xFF1E3D54),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardPage() {
    debugPrint('_buildDashboardPage: Construction du dashboard');
    debugPrint('Nombre total de tâches: ${_tasks.length}');
    debugPrint('Tâches en cours: ${_tasks.where((t) => t['status'] == 'in_progress').length}');
    debugPrint('Tâches terminées: ${_tasks.where((t) => t['status'] == 'done').length}');
    debugPrint('Tâches urgentes: ${_tasks.where((t) => t['priority'] == 'urgent' && t['status'] != 'done').length}');
    debugPrint('Contenu de _tasks: $_tasks');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bonjour ${SupabaseService.currentUser?.email?.split('@').first ?? 'Partenaire'}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Statistiques
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tâches en cours',
                  '${_tasks.where((t) => t['status'] == 'in_progress').length}',
                  Colors.blue,
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Tâches terminées',
                  '${_tasks.where((t) => t['status'] == 'done').length}',
                  Colors.green,
                  Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Taux d\'achèvement',
                  '${(_statistics['completion_rate'] ?? 0).toStringAsFixed(1)}%',
                  Colors.orange,
                  Icons.pie_chart_outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Tâches urgentes
          if (_tasks.any((t) => t['priority'] == 'urgent' && t['status'] != 'done')) ...[
            const Text(
              'Tâches urgentes',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tasks.where((t) => t['priority'] == 'urgent' && t['status'] != 'done').length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = _tasks.where((t) => t['priority'] == 'urgent' && t['status'] != 'done').toList()[index];
                return _buildTaskCardFromData(task);
              },
            ),
            const SizedBox(height: 32),
          ],
          // Tâches en cours
          const Text(
            'Tâches en cours',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tasks.where((t) => t['status'] == 'in_progress').length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = _tasks.where((t) => t['status'] == 'in_progress').toList()[index];
              return _buildTaskCardFromData(task);
            },
          ),
          const SizedBox(height: 32),
          // Tâches terminées
          const Text(
            'Tâches terminées',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tasks.where((t) => t['status'] == 'done').length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final task = _tasks.where((t) => t['status'] == 'done').toList()[index];
              return _buildTaskCardFromData(task);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCardFromData(Map<String, dynamic> task) {
    final bool isUrgent = task['priority'] == 'urgent';
    final String status = task['status'] ?? 'todo';
    final project = task['projects'];
    final String taskId = task['id'].toString();
    final bool isInProgress = status == 'in_progress';
    final bool isDone = status == 'done';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUrgent ? Colors.red.withAlpha(77) : Colors.grey.withAlpha(77),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (project != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        project['name'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task['description'] ?? '',
            style: TextStyle(
              color: Colors.grey[800],
              height: 1.5,
            ),
          ),
          if (task['due_date'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Échéance : ${DateFormat('dd/MM/yyyy').format(DateTime.parse(task['due_date']))}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          if (isInProgress) ...[
            Row(
              children: [
                Icon(
                  Icons.timer,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Temps écoulé : ${_formatDuration(_elapsedTimes[taskId] ?? Duration.zero)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (!isDone) ...[
                if (isInProgress) ...[
                  if (_stopwatches[taskId]?.isRunning ?? false) ...[
                    ElevatedButton.icon(
                      onPressed: () => _pauseStopwatch(taskId),
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () => _startStopwatch(taskId),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Reprendre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => _startTask(taskId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3D54),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Commencer'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (isInProgress) ...[
                  OutlinedButton(
                    onPressed: () {
                      _pauseStopwatch(taskId);
                      _completeTask(taskId);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Marquer comme terminé'),
                  ),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'todo':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'done':
        return 'Terminé';
      case 'in_progress':
        return 'En cours';
      case 'todo':
        return 'À faire';
      default:
        return status;
    }
  }

  Future<void> _startTask(String taskId) async {
    if (!mounted) return;
    
    try {
      await SupabaseService.client
          .from('tasks')
          .update({
            'status': 'in_progress',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskId);
      
      // Démarrer le chronomètre
      _startStopwatch(taskId);
      
      await _loadTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tâche démarrée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors du démarrage de la tâche: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du démarrage de la tâche: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completeTask(String taskId) async {
    if (!mounted) return;
    
    try {
      final duration = _elapsedTimes[taskId] ?? Duration.zero;
      final hours = duration.inMinutes / 60.0;

      // Utiliser taskId directement - peut être UUID ou int
      dynamic taskIdValue = taskId;
      // Essayer de convertir en int si c'est un nombre, sinon garder comme String
      try {
        taskIdValue = int.parse(taskId);
      } catch (e) {
        // Si la conversion échoue, c'est probablement un UUID, on garde le String
        debugPrint('taskId est probablement un UUID: $taskId');
      }

      // Créer une entrée timesheet
      await SupabaseService.client
          .from('timesheet_entries')
          .insert({
            'task_id': taskIdValue, // Utiliser la valeur appropriée (int ou String)
            'user_id': SupabaseService.currentUser!.id,
            'hours': hours,
            'date': DateTime.now().toIso8601String(),
            'description': 'Tâche terminée',
            'status': 'pending',
          });

      // Mettre à jour le statut de la tâche
      await SupabaseService.client
          .from('tasks')
          .update({
            'status': 'done',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', taskIdValue); // Utiliser la valeur appropriée
      
      // Arrêter et réinitialiser le chronomètre
      _stopwatches[taskId]?.stop();
      _stopwatches[taskId]?.reset();
      _timers[taskId]?.cancel();
      _timers.remove(taskId);
      _elapsedTimes[taskId] = Duration.zero;
      
      await Future.wait([
        _loadTasks(),
        _loadStatistics(),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tâche terminée et temps enregistré'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la complétion de la tâche: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la complétion de la tâche: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createTask(String title, String description, String projectId, DateTime? dueDate) async {
    if (!mounted) return;
    
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Ne pas convertir projectId - l'utiliser directement comme String (UUID)
      // La base de données déterminera le bon type

      await SupabaseService.createTaskForCompany(
        projectId: projectId,
        title: title,
        description: description,
        partnerId: currentUser.id, // Le partenaire connecté
        assignedTo: currentUser.id,
        dueDate: dueDate,
      );
      
      await _loadTasks();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tâche créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la création de la tâche: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création de la tâche: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCreateTaskDialog() async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime? selectedDate;
    String? selectedProjectId;
    List<Map<String, dynamic>> projects = [];

    try {
      final response = await SupabaseService.client
          .from('projects')
          .select()
          .order('name');
      projects = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors du chargement des projets: $e');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle tâche'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Titre',
                  hintText: 'Entrez le titre de la tâche',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Entrez la description de la tâche',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedProjectId,
                decoration: const InputDecoration(
                  labelText: 'Projet',
                ),
                items: projects.map((project) {
                  return DropdownMenuItem(
                    value: project['id'].toString(),
                    child: Text(project['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedProjectId = value;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Date d\'échéance'),
                subtitle: Text(
                  selectedDate != null 
                      ? DateFormat('dd/MM/yyyy').format(selectedDate!)
                      : 'Aucune date sélectionnée',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    selectedDate = date;
                    (context as Element).markNeedsBuild();
                  }
                },
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
            onPressed: () {
              if (titleController.text.isEmpty || selectedProjectId == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Veuillez remplir tous les champs obligatoires')),
                );
                return;
              }
              _createTask(
                titleController.text,
                descriptionController.text,
                selectedProjectId!,
                selectedDate,
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3D54),
            ),
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }
} 