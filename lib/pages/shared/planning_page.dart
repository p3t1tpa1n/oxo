// lib/pages/shared/planning_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/calendar_widget.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  _PlanningPageState createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  DateTime selectedDate = DateTime.now();
  String planningType = 'Global';
  bool isCalendarExpanded = false;
  List<Map<String, dynamic>> events = [];
  List<Map<String, dynamic>> selectedDayEvents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    debugPrint('PlanningPage: initState appelé');
    // Attendre un peu avant de charger les données pour être sûr que le widget est monté
    Future.delayed(Duration.zero, () {
      if (mounted) {
        _loadEvents();
      }
    });
  }

  Future<void> _loadEvents() async {
    if (SupabaseService.currentUser == null) {
      debugPrint('PlanningPage: Erreur - Utilisateur non connecté');
      return;
    }

    if (!mounted) {
      debugPrint('PlanningPage: Widget non monté, chargement annulé');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final userId = SupabaseService.currentUser!.id;
      debugPrint('PlanningPage: Chargement des événements pour l\'utilisateur $userId');
      
      final response = await SupabaseService.client
          .from('tasks')
          .select('''
            *,
            projects:project_id (
              name,
              status
            )
          ''')
          .or('assigned_to.eq.$userId,partner_id.eq.$userId,user_id.eq.$userId');

      debugPrint('PlanningPage: Réponse reçue avec ${response.length} événements');
      
      if (mounted) {
        setState(() {
          events = List<Map<String, dynamic>>.from(response);
          _updateSelectedDayEvents(selectedDate);
          isLoading = false;
        });
        
        // Log détaillé des événements
        for (var event in events) {
          debugPrint('PlanningPage: Événement trouvé - Nom: ${event['name']}, Date: ${event['due_date']}, Statut: ${event['status']}');
        }
        
        debugPrint('PlanningPage: ${selectedDayEvents.length} événements pour le jour ${DateFormat('yyyy-MM-dd').format(selectedDate)}');
      }
    } catch (e, stackTrace) {
      debugPrint('PlanningPage: Erreur lors du chargement des événements: $e');
      debugPrint('PlanningPage: Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        
        // Afficher un message d'erreur à l'utilisateur
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onDaySelected(DateTime day) {
    debugPrint('PlanningPage: Jour sélectionné: ${DateFormat('yyyy-MM-dd').format(day)}');
    setState(() {
      selectedDate = day;
      _updateSelectedDayEvents(day);
    });
  }

  void _updateSelectedDayEvents(DateTime day) {
    debugPrint('PlanningPage: Mise à jour des événements pour le jour ${DateFormat('yyyy-MM-dd').format(day)}');
    
    selectedDayEvents = events.where((event) {
      if (event['due_date'] == null) {
        return false;
      }
      
      final dueDate = DateTime.parse(event['due_date']);
      final isSameDay = dueDate.year == day.year && 
             dueDate.month == day.month && 
             dueDate.day == day.day;
      
      return isSameDay;
    }).toList();
    
    debugPrint('PlanningPage: ${selectedDayEvents.length} événements pour le jour sélectionné');
  }

  void _toggleCalendarExpand() {
    setState(() {
      isCalendarExpanded = !isCalendarExpanded;
    });
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.grey;
      case 'in_progress':
        return Colors.blue;
      case 'done':
        return Colors.green;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat('MMMM yyyy', 'fr_FR').format(DateTime(selectedDate.year, selectedDate.month));
    final formattedSelectedDate = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(selectedDate);
    
    debugPrint('PlanningPage: Construction du widget, isLoading=$isLoading');
    
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Planning',
        showBackButton: true,
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            // Radio buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio<String>(
                    value: 'Global',
                    groupValue: planningType,
                    onChanged: (value) {
                      setState(() {
                        planningType = value ?? planningType;
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text('Global', style: TextStyle(color: Color(0xFF122b35), fontSize: 13)),
                  const SizedBox(width: 16),
                  Radio<String>(
                    value: 'Associé',
                    groupValue: planningType,
                    onChanged: (value) {
                      setState(() {
                        planningType = value ?? planningType;
                      });
                    },
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text('Associé', style: TextStyle(color: Color(0xFF122b35), fontSize: 13)),
                ],
              ),
            ),
            
            // Reste du contenu dans un ListView pour éviter les problèmes de débordement
            Expanded(
              child: ListView(
                children: [
                  // Calendrier avec hauteur fixée
                  Container(
                    height: MediaQuery.of(context).size.height * 0.35,
                    padding: const EdgeInsets.all(8.0),
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : CalendarWidget(
                            showTitle: true,
                            title: 'Calendrier',
                            onDaySelected: _onDaySelected,
                            isExpanded: isCalendarExpanded,
                            onExpandToggle: _toggleCalendarExpand,
                          ),
                  ),
                  
                  // Séparateur avec la date sélectionnée
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                    color: const Color(0xFF1E3D54).withOpacity(0.1),
                    child: Text(
                      'Tâches du ${formattedSelectedDate.substring(0, 1).toUpperCase() + formattedSelectedDate.substring(1)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E3D54),
                      ),
                    ),
                  ),
                  
                  // Liste des tâches - hauteur adaptative
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 100,
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: isLoading 
                        ? const Center(child: CircularProgressIndicator())
                        : selectedDayEvents.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Pour le moment aucune tâche ne vous a été affectée pour ce jour.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: selectedDayEvents.length,
                                separatorBuilder: (context, index) => const Divider(height: 1, indent: 16, endIndent: 16),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                itemBuilder: (context, index) {
                                  final event = selectedDayEvents[index];
                                  return ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    title: Text(
                                      event['name'] ?? 'Sans titre',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 2),
                                        Text(
                                          'Projet: ${event['projects'] != null ? event['projects']['name'] ?? 'Projet inconnu' : 'Projet inconnu'}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(event['status']).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                _getStatusText(event['status']),
                                                style: TextStyle(
                                                  color: _getStatusColor(event['status']),
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: _getPriorityColor(event['priority']).withOpacity(0.2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                _getPriorityText(event['priority']),
                                                style: TextStyle(
                                                  color: _getPriorityColor(event['priority']),
                                                  fontSize: 9,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    leading: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: _getStatusColor(event['status']).withOpacity(0.2),
                                      child: Icon(
                                        _getStatusIcon(event['status']),
                                        color: _getStatusColor(event['status']),
                                        size: 14,
                                      ),
                                    ),
                                    onTap: () {
                                      // TODO: Afficher les détails de la tâche
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implémenter l'ajout d'un événement
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fonctionnalité à venir')),
          );
        },
        backgroundColor: const Color(0xFF1E3D54),
        child: const Icon(Icons.add),
      ),
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'todo':
        return 'À faire';
      case 'in_progress':
        return 'En cours';
      case 'done':
        return 'Terminé';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Non défini';
    }
  }

  String _getPriorityText(String? priority) {
    switch (priority) {
      case 'high':
        return 'Haute';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Basse';
      default:
        return 'Non définie';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'todo':
        return Icons.hourglass_empty;
      case 'in_progress':
        return Icons.autorenew;
      case 'done':
        return Icons.check_circle;
      case 'urgent':
        return Icons.priority_high;
      default:
        return Icons.help_outline;
    }
  }
}