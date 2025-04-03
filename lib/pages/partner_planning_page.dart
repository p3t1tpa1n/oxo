import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

class PartnerPlanningPage extends StatefulWidget {
  const PartnerPlanningPage({super.key});

  @override
  State<PartnerPlanningPage> createState() => _PartnerPlanningPageState();
}

class _PartnerPlanningPageState extends State<PartnerPlanningPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('tasks')
          .select('''
            *,
            projects (
              name,
              color
            )
          ''')
          .eq('assigned_to', user.id)
          .order('due_date');

      final events = <DateTime, List<Map<String, dynamic>>>{};
      for (var task in response) {
        final date = DateTime.parse(task['due_date']).toLocal();
        final dateKey = DateTime(date.year, date.month, date.day);
        events.putIfAbsent(dateKey, () => []).add(task);
      }
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des événements: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  Future<void> _requestExtension(Map<String, dynamic> task) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Demander une extension'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tâche: ${task['title']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Raison de l\'extension',
                  hintText: 'Expliquez pourquoi vous avez besoin de plus de temps',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez expliquer la raison de l\'extension';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  await Supabase.instance.client.from('extension_requests').insert({
                    'task_id': task['id'],
                    'reason': controller.text,
                    'status': 'pending',
                  });

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Demande d\'extension envoyée'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erreur lors de l\'envoi de la demande: $e'),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Planning'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEvents,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2025, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  eventLoader: _getEventsForDay,
                  calendarStyle: const CalendarStyle(
                    markersMaxCount: 3,
                    markerSize: 8,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: _selectedDay == null
                      ? const Center(
                          child: Text('Sélectionnez une date pour voir les tâches'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _getEventsForDay(_selectedDay!).length,
                          itemBuilder: (context, index) {
                            final task = _getEventsForDay(_selectedDay!)[index];
                            final project = task['projects'] as Map<String, dynamic>;
                            final dueDate = DateTime.parse(task['due_date']).toLocal();
                            final isOverdue = dueDate.isBefore(DateTime.now()) &&
                                task['status'] != 'done';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ListTile(
                                leading: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(project['color'])),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                title: Text(task['title']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(project['name']),
                                    if (isOverdue)
                                      Text(
                                        'En retard',
                                        style: TextStyle(
                                          color: Colors.red[700],
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.schedule),
                                      onPressed: () => _requestExtension(task),
                                      tooltip: 'Demander une extension',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.check_circle_outline),
                                      onPressed: () async {
                                        try {
                                          await Supabase.instance.client
                                              .from('tasks')
                                              .update({'status': 'done'})
                                              .eq('id', task['id']);

                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Tâche marquée comme terminée'),
                                              ),
                                            );
                                            _loadEvents();
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    'Erreur: $e'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      tooltip: 'Marquer comme terminé',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
} 