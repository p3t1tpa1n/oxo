import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class PartnerMissionsPage extends StatefulWidget {
  const PartnerMissionsPage({super.key});

  @override
  State<PartnerMissionsPage> createState() => _PartnerMissionsPageState();
}

class _PartnerMissionsPageState extends State<PartnerMissionsPage> {
  List<Map<String, dynamic>> _missions = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    try {
      final response = await SupabaseService.client
          .from('tasks')
          .select('''
            *,
            projects (
              name,
              description,
              priority,
              status
            )
          ''')
          .eq('assigned_to', SupabaseService.currentUser!.id)
          .order('due_date', ascending: true);
      
      setState(() {
        _missions = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des missions: $e');
    }
  }

  List<Map<String, dynamic>> _getFilteredMissions() {
    switch (_selectedFilter) {
      case 'urgent':
        return _missions.where((m) => m['priority'] == 'urgent').toList();
      case 'in_progress':
        return _missions.where((m) => m['status'] == 'in_progress').toList();
      case 'todo':
        return _missions.where((m) => m['status'] == 'todo').toList();
      case 'done':
        return _missions.where((m) => m['status'] == 'done').toList();
      default:
        return _missions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mes Missions',
          style: TextStyle(
            color: Color(0xFF122b35),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF122b35)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _getFilteredMissions().length,
              itemBuilder: (context, index) {
                final mission = _getFilteredMissions()[index];
                return _buildMissionCard(mission);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildFilterChip('Toutes', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Urgentes', 'urgent'),
          const SizedBox(width: 8),
          _buildFilterChip('En cours', 'in_progress'),
          const SizedBox(width: 8),
          _buildFilterChip('À faire', 'todo'),
          const SizedBox(width: 8),
          _buildFilterChip('Terminées', 'done'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF1784af).withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1784af) : Colors.grey[600],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? const Color(0xFF1784af) : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final project = mission['projects'];
    final priority = mission['priority'] ?? 'normal';
    final status = mission['status'];
    final dueDate = DateTime.parse(mission['due_date']);
    final isUrgent = priority == 'urgent';
    final isDone = status == 'done';

    Color statusColor;
    String statusText;
    switch (status) {
      case 'todo':
        statusColor = const Color(0xFF1784af);
        statusText = 'À faire';
        break;
      case 'in_progress':
        statusColor = const Color(0xFFFF9800);
        statusText = 'En cours';
        break;
      case 'done':
        statusColor = const Color(0xFF4CAF50);
        statusText = 'Terminée';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Non défini';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUrgent ? const Color(0xFFFF5252).withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF122b35),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1784af),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5252).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: Color(0xFFFF5252),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Urgent',
                          style: TextStyle(
                            color: Color(0xFFFF5252),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              mission['description'],
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  'Échéance : ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            if (!isDone) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (status == 'todo')
                    TextButton.icon(
                      onPressed: () => _updateMissionStatus(mission, 'in_progress'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Commencer'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF1784af),
                      ),
                    ),
                  if (status == 'in_progress') ...[
                    TextButton.icon(
                      onPressed: () => _requestExtension(mission),
                      icon: const Icon(Icons.schedule),
                      label: const Text('Demander une extension'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFFF9800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _updateMissionStatus(mission, 'done'),
                      icon: const Icon(Icons.check),
                      label: const Text('Terminer'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _updateMissionStatus(Map<String, dynamic> mission, String newStatus) async {
    try {
      await SupabaseService.client
          .from('tasks')
          .update({'status': newStatus})
          .eq('id', mission['id']);
      
      await _loadMissions();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'done'
                ? 'Mission terminée avec succès'
                : 'Statut de la mission mis à jour'
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _requestExtension(Map<String, dynamic> mission) async {
    final DateTime? newDate = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(mission['due_date']).add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (newDate != null && mounted) {
      final TextEditingController reasonController = TextEditingController();
      
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Demande d\'extension'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nouvelle date d\'échéance : ${DateFormat('dd/MM/yyyy').format(newDate)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motif de la demande',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1784af),
              ),
              child: const Text(
                'Envoyer la demande',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        try {
          // Enregistrer la demande d'extension
          await SupabaseService.client
              .from('extension_requests')
              .insert({
                'task_id': mission['id'],
                'current_due_date': mission['due_date'],
                'requested_due_date': newDate.toIso8601String(),
                'reason': reasonController.text,
                'status': 'pending',
                'requested_by': SupabaseService.currentUser!.id,
                'requested_at': DateTime.now().toIso8601String(),
              });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Demande d\'extension envoyée avec succès'),
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erreur: ${e.toString()}')),
            );
          }
        }
      }
      
      reasonController.dispose();
    }
  }
} 