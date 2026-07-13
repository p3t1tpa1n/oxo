import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';

class ProposedMissionsPage extends StatefulWidget {
  const ProposedMissionsPage({super.key});

  @override
  State<ProposedMissionsPage> createState() => _ProposedMissionsPageState();
}

class _ProposedMissionsPageState extends State<ProposedMissionsPage> {
  List<Map<String, dynamic>> _proposedMissions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProposedMissions();
  }

  Future<void> _loadProposedMissions() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final missions = await SupabaseService.getProposedMissionsForPartner(currentUser.id);
      
      if (mounted) {
        setState(() {
          _proposedMissions = missions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des missions proposées: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptMission(String missionId, String missionTitle) async {
    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accepter la mission'),
        content: Text('Voulez-vous accepter la mission "$missionTitle" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D5B),
            ),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final success = await SupabaseService.acceptMission(missionId);
      if (success) {
        await _loadProposedMissions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mission acceptée avec succès'),
              backgroundColor: const Color(0xFF2E7D5B),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'acceptation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectMission(String missionId, String missionTitle) async {
    if (!mounted) return;

    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser la mission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voulez-vous refuser la mission "$missionTitle" ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnel)',
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
              backgroundColor: Colors.red,
            ),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final reason = reasonController.text.trim();
      final success = await SupabaseService.rejectMission(
        missionId,
        responseMessage: reason.isNotEmpty ? reason : null,
      );
      
      if (success) {
        await _loadProposedMissions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mission refusée'),
              backgroundColor: const Color(0xFFB07B2E),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du refus: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildMissionsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsList() {
    if (_proposedMissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune mission proposée',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Les missions qui vous sont proposées apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProposedMissions,
      child: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _proposedMissions.length,
        itemBuilder: (context, index) {
          final mission = _proposedMissions[index];
          return _buildMissionCard(mission);
        },
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final startDate = mission['start_date'] != null
        ? DateTime.parse(mission['start_date'])
        : null;
    final endDate = mission['end_date'] != null
        ? DateTime.parse(mission['end_date'])
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              children: [
                Expanded(
                  child: Text(
                    mission['title'] ?? 'Mission sans titre',
                    style: AppTheme.typography.h4,
                  ),
                ),
                _buildPriorityBadge(mission['priority']),
              ],
            ),
            const SizedBox(height: 12),

            // Description
            if (mission['description'] != null) ...[
              Text(
                mission['description'],
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppTheme.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Informations
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (startDate != null)
                  _buildInfoChip(
                    Icons.calendar_today,
                    'Début: ${DateFormat('dd/MM/yyyy').format(startDate)}',
                  ),
                if (endDate != null)
                  _buildInfoChip(
                    Icons.event,
                    'Fin: ${DateFormat('dd/MM/yyyy').format(endDate)}',
                  ),
                if (mission['budget'] != null)
                  _buildInfoChip(
                    Icons.euro,
                    'Budget: ${mission['budget']}€',
                  ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Boutons d'action
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _rejectMission(mission['id'], mission['title'] ?? ''),
                  icon: Icon(Icons.close, size: 18, color: AppTheme.colors.error),
                  label: Text(
                    'Refuser',
                    style: TextStyle(color: AppTheme.colors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: AppTheme.colors.error.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _acceptMission(mission['id'], mission['title'] ?? ''),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.colors.success,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String? priority) {
    Color color;
    String label;

    switch (priority) {
      case 'high':
      case 'urgent':
        color = AppTheme.colors.error;
        label = 'Urgent';
        break;
      case 'medium':
        color = AppTheme.colors.warning;
        label = 'Normal';
        break;
      case 'low':
        color = AppTheme.colors.secondary;
        label = 'Faible';
        break;
      default:
        color = AppTheme.colors.statusCancelled;
        label = priority ?? 'Non défini';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.colors.borderLight, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.colors.textSecondary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
