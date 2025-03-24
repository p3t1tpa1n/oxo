import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';  // Ajout de l'import pour Timer
import 'package:url_launcher/url_launcher.dart';
import '../services/supabase_service.dart';
import '../services/version_service.dart';
import '../widgets/top_bar.dart';
import '../widgets/calendar_widget.dart';

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
  Map<String, Stopwatch> _stopwatches = {};
  Map<String, Timer> _timers = {};
  Map<String, Duration> _elapsedTimes = {};

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
    _checkForUpdates();
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

  Future<void> _checkAuthAndLoadData() async {
    if (!mounted) return;

    debugPrint('Vérification de l\'état de connexion...');
    debugPrint('Session actuelle: ${SupabaseService.client.auth.currentSession}');
    debugPrint('Utilisateur actuel: ${SupabaseService.currentUser}');

    if (!SupabaseService.isAuthenticated) {
      debugPrint('Utilisateur non authentifié, redirection vers la page de connexion');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    await _initializeData();
  }

  Future<void> _initializeData() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      debugPrint('Début du chargement des données...');
      
      // Charger les données en parallèle
      await Future.wait([
        _loadTasks(),
        _loadStatistics(),
      ]);

      debugPrint('Données chargées avec succès');
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données: $e')),
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
      
      final response = await SupabaseService.client
          .from('tasks')
          .select('''
            *,
            projects!tasks_project_id_fkey (
              id,
              name,
              description,
              status
            ),
            assigned_profile:profiles!tasks_assigned_to_fkey (
              id,
              email,
              role
            ),
            partner_profile:profiles!tasks_partner_id_fkey (
              id,
              email,
              role
            )
          ''')
          .or('user_id.eq.${SupabaseService.currentUser!.id}')
          .order('created_at', ascending: false);

      debugPrint('_loadTasks: Réponse reçue');
      debugPrint('Nombre de tâches: ${response.length}');
      debugPrint('Contenu de la réponse: $response');
      
      if (!mounted) return;

      setState(() {
        _tasks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });

      debugPrint('_loadTasks: État mis à jour avec ${_tasks.length} tâches');
      debugPrint('Contenu de _tasks: $_tasks');
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
      
      final allTasks = await SupabaseService.client
          .from('tasks')
          .select()
          .or('assigned_to.eq.${SupabaseService.currentUser!.id},partner_id.eq.${SupabaseService.currentUser!.id}');

      debugPrint('_loadStatistics: Réponse reçue');
      debugPrint('Nombre total de tâches: ${allTasks.length}');
      debugPrint('Contenu de la réponse: $allTasks');

      if (!mounted) return;

      final completedTasks = allTasks.where((task) => task['status'] == 'done').length;
      final urgentTasks = allTasks.where((task) => task['priority'] == 'urgent').length;
      final totalTasks = allTasks.length;

      debugPrint('_loadStatistics: Calcul des statistiques');
      debugPrint('Tâches terminées: $completedTasks');
      debugPrint('Tâches urgentes: $urgentTasks');
      debugPrint('Total des tâches: $totalTasks');

      setState(() {
        _statistics = {
          'completion_rate': totalTasks > 0 ? (completedTasks / totalTasks) * 100 : 0.0,
          'total_tasks': totalTasks,
          'completed_tasks': completedTasks,
          'urgent_tasks': urgentTasks,
        };
        debugPrint('_loadStatistics: État mis à jour avec les nouvelles statistiques');
      });
    } catch (e, stackTrace) {
      debugPrint('_loadStatistics: Erreur lors du chargement des statistiques');
      debugPrint('Erreur: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
            onDestinationSelected: _onTabChanged,
            labelType: NavigationRailLabelType.none,
            leading: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                  // Bouton de test pour les mises à jour
                  const SizedBox(height: 16),
                  PopupMenuButton<String>(
                    onSelected: (String version) async {
                      VersionService.setMockVersion(version);
                      await _checkForUpdates();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test de mise à jour lancé'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: '1.0.0',
                        child: Text('Tester version égale (1.0.0)'),
                      ),
                      const PopupMenuItem<String>(
                        value: '2.0.0',
                        child: Text('Tester nouvelle version (2.0.0)'),
                      ),
                      const PopupMenuItem<String>(
                        value: '0.9.0',
                        child: Text('Tester ancienne version (0.9.0)'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'test',
                        child: Text('Lancer tous les tests'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bug_report, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Tester MàJ',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
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
                icon: Icon(Icons.assignment_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.assignment, color: Colors.white),
                label: Text('Mes Missions', style: TextStyle(color: Colors.white)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.calendar_today, color: Colors.white),
                label: Text('Planning', style: TextStyle(color: Colors.white)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.access_time_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.access_time, color: Colors.white),
                label: Text('Timesheet', style: TextStyle(color: Colors.white)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.chat_outlined, color: Colors.white70),
                selectedIcon: Icon(Icons.chat, color: Colors.white),
                label: Text('Discussion', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          // Contenu principal
          Expanded(
            child: Material(
              color: Colors.grey[100],
              child: Column(
                children: [
                  // Barre de notification
                  Material(
                    elevation: 1,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_none),
                          const SizedBox(width: 12),
                          Text(
                            'Nouvelles missions disponibles',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              // TODO: Voir toutes les notifications
                            },
                            child: const Text('Voir tout'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Contenu de la page
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Builder(
                            builder: (context) {
                              switch (_selectedIndex) {
                                case 0:
                                  return _buildDashboardPage();
                                case 1:
                                  return _buildMissionsPage();
                                case 2:
                                  return _buildPlanningPage();
                                case 3:
                                  return _buildTimesheetPage();
                                case 4:
                                  return _buildDiscussionPage();
                                default:
                                  return _buildDashboardPage();
                              }
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        backgroundColor: const Color(0xFF1E3D54),
        child: const Icon(Icons.add),
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

  Widget _buildMissionsPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statistiques
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Tâches en cours', '5', Colors.blue, Icons.trending_up),
                _buildStatCard('Tâches terminées', '12', Colors.green, Icons.check_circle_outline),
                _buildStatCard('Taux d\'achèvement', '75%', Colors.orange, Icons.pie_chart_outline),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Liste des tâches
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mes Missions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildTaskCard(
                          'Mission urgente',
                          'Description détaillée de la mission',
                          true,
                          'En cours',
                        ),
                        const SizedBox(height: 8),
                        _buildTaskCard(
                          'Mission normale',
                          'Description détaillée de la mission',
                          false,
                          'À faire',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String title, String description, bool isUrgent, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isUrgent ? Colors.red.withAlpha(77) : Colors.grey.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUrgent ? Colors.red.withAlpha(26) : Colors.grey.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    color: isUrgent ? Colors.red : Colors.grey[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3D54),
                ),
                child: const Text('Commencer'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {},
                child: const Text('Marquer comme terminé'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CalendarWidget(
              showTitle: true,
              title: 'Planning',
              isExpanded: false,
              onExpandToggle: null,
              isTimesheet: false,
              onDaySelected: (DateTime date) {
                debugPrint('Date sélectionnée : ${date.toString()}');
                // TODO: Afficher les tâches du jour sélectionné
              },
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tâches du jour',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildTaskCard(
                          'Réunion client',
                          'Présentation du projet',
                          true,
                          'Aujourd\'hui',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesheetPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Timesheet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Ouvrir le dialogue d'ajout d'heures
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Ajouter des heures'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3D54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
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
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Date'),
                              Text('Mission'),
                              Text('Heures'),
                              Text('Status'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      children: [
                        _buildTimesheetEntry(
                          date: '12/03/2024',
                          mission: 'Développement API',
                          hours: '4h',
                          status: 'Validé',
                        ),
                        const SizedBox(height: 8),
                        _buildTimesheetEntry(
                          date: '11/03/2024',
                          mission: 'Tests unitaires',
                          hours: '6h',
                          status: 'En attente',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesheetEntry({
    required String date,
    required String mission,
    required String hours,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withAlpha(77)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(date),
          Text(mission),
          Text(hours),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'Validé' 
                ? Colors.green.withAlpha(26)
                : Colors.orange.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: status == 'Validé' ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFF1E3D54),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                SizedBox(width: 16),
                Text(
                  'Discussion avec mon associé',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        _buildMessageBubble(
                          'Bonjour, j\'ai une question concernant la mission de développement API.',
                          isMe: true,
                        ),
                        _buildMessageBubble(
                          'Bien sûr, je vous écoute.',
                          isMe: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Votre message...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          color: const Color(0xFF1E3D54),
                          onPressed: () {
                            // TODO: Envoyer le message
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, {required bool isMe}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            const CircleAvatar(
              backgroundColor: Color(0xFF1E3D54),
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF1E3D54) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black,
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
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

      // Créer une entrée timesheet
      await SupabaseService.client
          .from('timesheet_entries')
          .insert({
            'task_id': taskId,
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
          .eq('id', taskId);
      
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

      final response = await SupabaseService.client
          .from('tasks')
          .insert({
            'title': title,
            'description': description,
            'project_id': projectId,
            'status': 'todo',
            'due_date': dueDate?.toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
            'user_id': currentUser.id,  // ID de l'utilisateur qui crée la tâche
            // partner_id et assigned_to seront gérés par le trigger
          })
          .select()
          .single();
      
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

  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await VersionService.checkForUpdates();
      if (updateInfo != null && mounted) {
        _showUpdateDialog(
          updateInfo['latest_version'],
          updateInfo['changelog'],
          updateInfo['download_url'],
          updateInfo['is_mandatory'],
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des mises à jour: $e');
    }
  }

  void _showUpdateDialog(String version, String? changelog, String downloadUrl, bool isMandatory) {
    showDialog(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (context) => AlertDialog(
        title: Text('Nouvelle version disponible (v$version)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMandatory 
                ? 'Une mise à jour obligatoire est disponible.'
                : 'Une nouvelle version de l\'application est disponible.',
            ),
            if (changelog != null) ...[
              const SizedBox(height: 16),
              const Text(
                'Nouveautés :',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(changelog),
            ],
          ],
        ),
        actions: [
          if (!isMandatory)
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Plus tard'),
            ),
          ElevatedButton(
            onPressed: () async {
              final url = Uri.parse(downloadUrl);
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
                if (isMandatory && mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                } else if (mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3D54),
            ),
            child: const Text('Mettre à jour'),
          ),
        ],
      ),
    );
  }
} 