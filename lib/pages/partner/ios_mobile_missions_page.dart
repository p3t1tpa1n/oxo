import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';

class IOSMobileMissionsPage extends StatefulWidget {
  const IOSMobileMissionsPage({Key? key}) : super(key: key);

  @override
  State<IOSMobileMissionsPage> createState() => _IOSMobileMissionsPageState();
}

class _IOSMobileMissionsPageState extends State<IOSMobileMissionsPage> {
  List<Map<String, dynamic>> _missions = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';
  int _unreadCount = 0;

  final List<String> _filters = [
    'all',
    'pending',
    'accepted',
    'in_progress',
    'completed',
    'rejected',
  ];

  final Map<String, String> _filterLabels = {
    'all': 'Toutes',
    'pending': 'En attente',
    'accepted': 'Acceptées',
    'in_progress': 'En cours',
    'completed': 'Terminées',
    'rejected': 'Refusées',
  };

  @override
  void initState() {
    super.initState();
    _loadMissions();
    _loadUnreadCount();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    
    try {
      final missions = await SupabaseService.getMyMissions();
      if (mounted) {
        setState(() {
          _missions = missions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement missions: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await SupabaseService.getUnreadNotificationsCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      debugPrint('Erreur chargement notifications: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredMissions {
    if (_selectedFilter == 'all') {
      return _missions;
    }
    return _missions.where((mission) => mission['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Mes Missions",
        actions: [
          if (_unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: IOSTheme.systemRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$_unreadCount',
                style: IOSTheme.caption1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _loadMissions,
            child: const Icon(
              CupertinoIcons.refresh,
              color: IOSTheme.primaryBlue,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : Column(
              children: [
                _buildFilterSection(),
                Expanded(child: _buildMissionsList()),
              ],
            ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: CupertinoSegmentedControl<String>(
        children: Map.fromEntries(
          _filters.map((filter) => MapEntry(
            filter,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                _filterLabels[filter]!,
                style: IOSTheme.caption1.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          )),
        ),
        onValueChanged: (String value) {
          setState(() => _selectedFilter = value);
        },
        groupValue: _selectedFilter,
        selectedColor: IOSTheme.primaryBlue,
        unselectedColor: IOSTheme.systemGray6,
        borderColor: IOSTheme.systemGray4,
      ),
    );
  }

  Widget _buildMissionsList() {
    final filteredMissions = _filteredMissions;
    
    if (filteredMissions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredMissions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMissionCard(filteredMissions[index]),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;

    switch (_selectedFilter) {
      case 'pending':
        title = 'Aucune mission en attente';
        subtitle = 'Vous n\'avez pas de mission en attente de réponse.';
        icon = CupertinoIcons.clock;
        break;
      case 'accepted':
        title = 'Aucune mission acceptée';
        subtitle = 'Vous n\'avez pas encore accepté de mission.';
        icon = CupertinoIcons.checkmark_circle;
        break;
      case 'in_progress':
        title = 'Aucune mission en cours';
        subtitle = 'Vous n\'avez pas de mission en cours d\'exécution.';
        icon = CupertinoIcons.play_circle;
        break;
      case 'completed':
        title = 'Aucune mission terminée';
        subtitle = 'Vous n\'avez pas encore terminé de mission.';
        icon = CupertinoIcons.checkmark_circle_fill;
        break;
      case 'rejected':
        title = 'Aucune mission refusée';
        subtitle = 'Vous n\'avez pas refusé de mission.';
        icon = CupertinoIcons.xmark_circle;
        break;
      default:
        title = 'Aucune mission';
        subtitle = 'Vous n\'avez pas encore reçu de mission.';
        icon = CupertinoIcons.briefcase;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: IOSTheme.systemGray3,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: IOSTheme.title2.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final status = mission['status'] ?? 'pending';
    final priority = mission['priority'] ?? 'medium';
    final deadline = mission['deadline'] != null 
        ? DateTime.parse(mission['deadline']) 
        : null;

    return Container(
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IOSTheme.systemGray5, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec statut et priorité
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mission['project_name'] ?? 'Projet sans nom',
                        style: IOSTheme.title3.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mission['task_title'] ?? 'Tâche sans titre',
                        style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(status),
                const SizedBox(width: 8),
                _buildPriorityBadge(priority),
              ],
            ),
          ),
          
          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message de l'associé
                if (mission['message'] != null && mission['message'].toString().isNotEmpty) ...[
                  Text(
                    'Message:',
                    style: IOSTheme.footnote.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mission['message'],
                    style: IOSTheme.body,
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Deadline
                if (deadline != null) ...[
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.calendar,
                        size: 16,
                        color: IOSTheme.systemGray,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Échéance: ${DateFormat('dd/MM/yyyy').format(deadline)}',
                        style: IOSTheme.footnote.copyWith(color: IOSTheme.labelSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Informations sur l'assignation
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.person,
                      size: 16,
                      color: IOSTheme.systemGray,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Assigné par: ${mission['assigned_by_first_name'] ?? ''} ${mission['assigned_by_last_name'] ?? ''}',
                        style: IOSTheme.footnote.copyWith(color: IOSTheme.labelSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.clock,
                      size: 16,
                      color: IOSTheme.systemGray,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Assigné le: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(mission['created_at']))}',
                      style: IOSTheme.footnote.copyWith(color: IOSTheme.labelSecondary),
                    ),
                  ],
                ),
                
                // Réponse du partenaire
                if (mission['partner_response'] != null && mission['partner_response'].toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: IOSTheme.systemGray6,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Votre réponse:',
                          style: IOSTheme.footnote.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mission['partner_response'],
                          style: IOSTheme.body,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Actions
          if (status == 'pending') _buildPendingActions(mission),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: IOSTheme.caption1.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final color = _getPriorityColor(priority);
    final label = _getPriorityLabel(priority);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: IOSTheme.caption1.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPendingActions(Map<String, dynamic> mission) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.systemGray6,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: IOSSecondaryButton(
              text: 'Refuser',
              onPressed: () => _showRejectDialog(mission),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: IOSPrimaryButton(
              text: 'Accepter',
              onPressed: () => _showAcceptDialog(mission),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(Map<String, dynamic> mission) {
    final TextEditingController messageController = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Accepter la mission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir accepter cette mission ?'),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: messageController,
              placeholder: 'Message optionnel...',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Accepter'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _acceptMission(mission['id'], messageController.text.trim());
            },
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> mission) {
    final TextEditingController messageController = TextEditingController();
    
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Refuser la mission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir refuser cette mission ?'),
            const SizedBox(height: 16),
            CupertinoTextField(
              controller: messageController,
              placeholder: 'Raison du refus (optionnel)...',
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Refuser'),
            onPressed: () async {
              Navigator.of(context).pop();
              await _rejectMission(mission['id'], messageController.text.trim());
            },
          ),
        ],
      ),
    );
  }

  Future<void> _acceptMission(String missionId, String message) async {
    try {
      final success = await SupabaseService.acceptMission(
        missionId,
        responseMessage: message.isNotEmpty ? message : null,
      );
      
      if (success) {
        _showSnackBar('Mission acceptée avec succès', isSuccess: true);
        _loadMissions();
        _loadUnreadCount();
      } else {
        _showSnackBar('Erreur lors de l\'acceptation de la mission');
      }
    } catch (e) {
      _showSnackBar('Erreur: $e');
    }
  }

  Future<void> _rejectMission(String missionId, String message) async {
    try {
      final success = await SupabaseService.rejectMission(
        missionId,
        responseMessage: message.isNotEmpty ? message : null,
      );
      
      if (success) {
        _showSnackBar('Mission refusée', isSuccess: true);
        _loadMissions();
        _loadUnreadCount();
      } else {
        _showSnackBar('Erreur lors du refus de la mission');
      }
    } catch (e) {
      _showSnackBar('Erreur: $e');
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? IOSTheme.successColor : IOSTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return IOSTheme.warningColor;
      case 'accepted': return IOSTheme.successColor;
      case 'in_progress': return IOSTheme.primaryBlue;
      case 'completed': return IOSTheme.successColor;
      case 'rejected': return IOSTheme.errorColor;
      default: return IOSTheme.systemGray;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'accepted': return 'Acceptée';
      case 'in_progress': return 'En cours';
      case 'completed': return 'Terminée';
      case 'rejected': return 'Refusée';
      default: return status;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'low': return IOSTheme.systemGreen;
      case 'medium': return IOSTheme.warningColor;
      case 'high': return IOSTheme.systemOrange;
      case 'urgent': return IOSTheme.errorColor;
      default: return IOSTheme.systemGray;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'low': return 'Basse';
      case 'medium': return 'Moyenne';
      case 'high': return 'Haute';
      case 'urgent': return 'Urgente';
      default: return priority;
    }
  }
}
