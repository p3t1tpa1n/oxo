import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';

class IOSMobileMissionManagementPage extends StatefulWidget {
  const IOSMobileMissionManagementPage({Key? key}) : super(key: key);

  @override
  State<IOSMobileMissionManagementPage> createState() => _IOSMobileMissionManagementPageState();
}

class _IOSMobileMissionManagementPageState extends State<IOSMobileMissionManagementPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _missions = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadMissions(),
        _loadUnreadCount(),
      ]);
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMissions() async {
    try {
      final missions = await SupabaseService.getCompanyMissions();
      if (mounted) {
        setState(() => _missions = missions);
      }
    } catch (e) {
      debugPrint('Erreur chargement missions: $e');
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

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Gestion Missions",
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
            onPressed: _loadData,
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
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMissionsTab(),
                      _buildNotificationTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return Material(
      color: Colors.transparent,
      child: Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.systemGray6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: IOSTheme.primaryBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: IOSTheme.labelSecondary,
        labelStyle: IOSTheme.body.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: IOSTheme.body,
        tabs: const [
          Tab(text: 'Missions'),
          Tab(text: 'Notifications'),
        ],
        ),
      ),
    );
  }

  Widget _buildMissionsTab() {
    return Column(
      children: [
        _buildMissionsStats(),
        Expanded(child: _buildMissionsList()),
      ],
    );
  }

  Widget _buildMissionsStats() {
    final pendingCount = _missions.where((m) => m['status'] == 'pending').length;
    final acceptedCount = _missions.where((m) => m['status'] == 'accepted').length;
    final inProgressCount = _missions.where((m) => m['status'] == 'in_progress').length;
    final completedCount = _missions.where((m) => m['status'] == 'completed').length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IOSTheme.systemGray5, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vue d\'ensemble',
            style: IOSTheme.title3.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'En attente',
                  value: '$pendingCount',
                  color: IOSTheme.warningColor,
                  icon: CupertinoIcons.clock,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Acceptées',
                  value: '$acceptedCount',
                  color: IOSTheme.successColor,
                  icon: CupertinoIcons.checkmark_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'En cours',
                  value: '$inProgressCount',
                  color: IOSTheme.primaryBlue,
                  icon: CupertinoIcons.play_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Terminées',
                  value: '$completedCount',
                  color: IOSTheme.successColor,
                  icon: CupertinoIcons.checkmark_circle_fill,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: IOSTheme.title2.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            title,
            style: IOSTheme.caption1.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionsList() {
    if (_missions.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.briefcase,
        title: 'Aucune mission',
        subtitle: 'Aucune mission n\'a encore été assignée.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _missions.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildMissionCard(_missions[index]),
        );
      },
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final status = mission['status'] ?? 'pending';
    final priority = mission['priority'] ?? 'medium';

    return Container(
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IOSTheme.systemGray5, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                        mission['mission_name'] ?? 'Mission sans nom',
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
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Partenaire assigné
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
                        'Assigné à: ${mission['assigned_to_first_name'] ?? ''} ${mission['assigned_to_last_name'] ?? ''}',
                        style: IOSTheme.body,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Message
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
                
                // Réponse du partenaire
                if (mission['partner_response'] != null && mission['partner_response'].toString().isNotEmpty) ...[
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
                          'Réponse du partenaire:',
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
                  const SizedBox(height: 12),
                ],
                
                // Dates
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTab() {
    return Column(
      children: [
        _buildQuickActions(),
        Expanded(child: _buildNotificationForm()),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IOSTheme.systemGray5, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: IOSTheme.title3.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: IOSPrimaryButton(
                  text: 'Assigner Mission',
                  onPressed: _showAssignMissionDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: IOSSecondaryButton(
                  text: 'Notifier Tous',
                  onPressed: _showNotifyAllDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Envoyer une notification',
            style: IOSTheme.title3.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildNotificationFormFields(),
        ],
      ),
    );
  }

  Widget _buildNotificationFormFields() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    String selectedProjectId = '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: IOSTheme.systemGray5, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            'Titre de la notification',
            style: IOSTheme.footnote.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          IOSTextField(
            controller: titleController,
            placeholder: 'Ex: Nouvelle mission disponible',
          ),
          const SizedBox(height: 16),
          
          // Projet
          Text(
            'Projet concerné',
            style: IOSTheme.footnote.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: IOSTheme.systemGray4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => _showProjectPicker((projectId) {
                setState(() => selectedProjectId = projectId);
              }),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      selectedProjectId.isNotEmpty 
                          ? _missions.firstWhere((m) => m['id'].toString() == selectedProjectId)['title'] ?? 'Mission'
                          : 'Sélectionner une mission',
                      style: IOSTheme.body,
                    ),
                  ),
                  const Icon(CupertinoIcons.chevron_down, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Message
          Text(
            'Message',
            style: IOSTheme.footnote.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          IOSTextField(
            controller: messageController,
            placeholder: 'Décrivez la mission et les instructions...',
          ),
          const SizedBox(height: 24),
          
          // Bouton d'envoi
          SizedBox(
            width: double.infinity,
            child: IOSPrimaryButton(
              text: 'Envoyer la notification',
              onPressed: () => _sendNotification(
                titleController.text.trim(),
                messageController.text.trim(),
                selectedProjectId,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
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

  void _showAssignMissionDialog() {
    // TODO: Implémenter le dialogue d'assignation de mission
    _showSnackBar('Fonctionnalité d\'assignation en cours de développement');
  }

  void _showNotifyAllDialog() {
    // TODO: Implémenter le dialogue de notification rapide
    _showSnackBar('Fonctionnalité de notification rapide en cours de développement');
  }

  void _showProjectPicker(Function(String) onSelected) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoPicker(
            itemExtent: 32,
            onSelectedItemChanged: (index) => onSelected(_missions[index]['id'].toString()),
            children: _missions.map((mission) => Text(mission['title'] ?? 'Mission sans nom')).toList(),
          ),
        ),
      ),
    );
  }

  Future<void> _sendNotification(String title, String message, String projectId) async {
    if (title.isEmpty || message.isEmpty || projectId.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs');
      return;
    }

    try {
      final success = await SupabaseService.notifyAllPartnersMissionAvailable(
        projectId: projectId,
        title: title,
        message: message,
      );
      
      if (success) {
        _showSnackBar('Notification envoyée à tous les partenaires', isSuccess: true);
        _loadUnreadCount();
      } else {
        _showSnackBar('Erreur lors de l\'envoi de la notification');
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
