// ============================================================================
// MOBILE CLIENT REQUESTS TAB - OXO TIME SHEETS
// Tab Demandes pour les Clients iOS
// Utilise STRICTEMENT AppTheme (pas IOSTheme)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../services/supabase_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/company_service.dart';

class MobileClientRequestsTab extends StatefulWidget {
  const MobileClientRequestsTab({Key? key}) : super(key: key);

  @override
  State<MobileClientRequestsTab> createState() => _MobileClientRequestsTabState();
}

class _MobileClientRequestsTabState extends State<MobileClientRequestsTab> {
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadNotificationsCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      debugPrint('Erreur chargement notifications: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final userCompany = await CompanyService.getUserCompany();
      if (userCompany == null) throw Exception('Entreprise non trouvée');

      final response = await SupabaseService.client
          .from('client_requests')
          .select()
          .eq('client_id', userCompany['company_id'])
          .order('created_at', ascending: false);

      setState(() {
        _requests = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement demandes: $e');
      setState(() {
        _requests = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.colors.primary,
                            strokeWidth: 2,
                          ),
                        )
                      : _requests.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              color: AppTheme.colors.primary,
                              child: ListView.builder(
                                padding: EdgeInsets.all(AppTheme.spacing.md),
                                itemCount: _requests.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: AppTheme.spacing.sm),
                                    child: _buildRequestCard(_requests[index]),
                                  );
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
          // FAB pour nouvelle demande
          Positioned(
            right: AppTheme.spacing.md,
            bottom: AppTheme.spacing.md + 20,
            child: IconButton(
              padding: EdgeInsets.zero,
              onPressed: _showNewRequestDialog,
              icon: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.colors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.colors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(AppIcons.add, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.sm,
      ),
      color: AppTheme.colors.surface,
      child: Row(
        children: [
          Text(
            'Mes Demandes',
            style: AppTheme.typography.h1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.colors.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/messaging');
            },
            icon: Stack(
              children: [
                Icon(AppIcons.notifications, color: AppTheme.colors.textPrimary, size: 24),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: AppTheme.colors.error, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/profile');
            },
            icon: Icon(AppIcons.settings, color: AppTheme.colors.textPrimary, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: AppTheme.colors.textSecondary),
          SizedBox(height: AppTheme.spacing.md),
          Text(
            'Aucune demande',
            style: AppTheme.typography.h3.copyWith(color: AppTheme.colors.textSecondary, decoration: TextDecoration.none),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Text(
            'Créez une nouvelle demande\npour contacter l\'équipe',
            style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary, decoration: TextDecoration.none),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spacing.lg),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.colors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius.medium)),
            ),
            onPressed: _showNewRequestDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: Text(
              'Nouvelle demande',
              style: AppTheme.typography.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final type = request['request_type'] ?? 'general';

    String dateStr = '';
    try {
      final date = request['created_at'];
      if (date != null) {
        dateStr = DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(date));
      }
    } catch (e) {
      debugPrint('Erreur format date: $e');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showRequestDetails(request),
          borderRadius: BorderRadius.circular(AppTheme.radius.medium),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacing.sm),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radius.small),
                      ),
                      child: Icon(_getTypeIcon(type), color: _getTypeColor(type), size: 20),
                    ),
                    SizedBox(width: AppTheme.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['title'] ?? 'Demande',
                            style: AppTheme.typography.h4.copyWith(fontWeight: FontWeight.bold, color: AppTheme.colors.textPrimary, decoration: TextDecoration.none),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _getTypeLabel(type),
                            style: AppTheme.typography.caption.copyWith(color: AppTheme.colors.textSecondary, decoration: TextDecoration.none),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.sm, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radius.small),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTheme.typography.caption.copyWith(color: statusColor, fontWeight: FontWeight.w600, decoration: TextDecoration.none),
                      ),
                    ),
                  ],
                ),
                if (request['description'] != null) ...[
                  SizedBox(height: AppTheme.spacing.sm),
                  Text(
                    request['description'],
                    style: AppTheme.typography.bodySmall.copyWith(color: AppTheme.colors.textSecondary, decoration: TextDecoration.none),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: AppTheme.spacing.sm),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppTheme.colors.textSecondary),
                    SizedBox(width: 4),
                    Text(dateStr, style: AppTheme.typography.caption.copyWith(color: AppTheme.colors.textSecondary, decoration: TextDecoration.none)),
                    const Spacer(),
                    Icon(Icons.chevron_right, size: 16, color: AppTheme.colors.textSecondary),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return AppTheme.colors.success;
      case 'in_progress':
      case 'processing':
        return AppTheme.colors.info;
      case 'pending':
        return AppTheme.colors.warning;
      case 'rejected':
        return AppTheme.colors.error;
      default:
        return AppTheme.colors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'done':
        return 'Terminée';
      case 'in_progress':
      case 'processing':
        return 'En cours';
      case 'pending':
        return 'En attente';
      case 'rejected':
        return 'Refusée';
      default:
        return status;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'support':
        return AppTheme.colors.info;
      case 'quote':
        return AppTheme.colors.success;
      case 'modification':
        return AppTheme.colors.warning;
      case 'question':
        return AppTheme.colors.primary;
      default:
        return AppTheme.colors.textSecondary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'support':
        return Icons.build;
      case 'quote':
        return Icons.description;
      case 'modification':
        return Icons.edit;
      case 'question':
        return Icons.help_outline;
      default:
        return Icons.article;
    }
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'support':
        return 'Support technique';
      case 'quote':
        return 'Demande de devis';
      case 'modification':
        return 'Demande de modification';
      case 'question':
        return 'Question';
      default:
        return 'Demande générale';
    }
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        child: SafeArea(
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey[300]!, borderRadius: BorderRadius.circular(2)),
              ),
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        request['title'] ?? 'Demande',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text(statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.colors.textSecondary)),
                      const SizedBox(height: 8),
                      Text(request['description'] ?? 'Aucune description', style: const TextStyle(fontSize: 15)),
                      const SizedBox(height: 20),
                      Text('Type de demande', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.colors.textSecondary)),
                      const SizedBox(height: 8),
                      Text(_getTypeLabel(request['request_type'] ?? 'general'), style: const TextStyle(fontSize: 15)),
                      if (request['created_at'] != null) ...[
                        const SizedBox(height: 20),
                        Text('Date de création', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.colors.textSecondary)),
                        const SizedBox(height: 8),
                        Text(DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(request['created_at'])), style: const TextStyle(fontSize: 15)),
                      ],
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.colors.inputBackground,
                  border: Border(top: BorderSide(color: AppTheme.colors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.colors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _navigateToMessages(request);
                        },
                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                        label: const Text('Envoyer un message', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppTheme.colors.textPrimary, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.colors.inputBackground,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
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

  void _navigateToMessages(Map<String, dynamic> request) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      '/messaging',
      arguments: {
        'requestId': request['id'],
        'requestTitle': request['title'],
      },
    );
  }

  void _showNewRequestDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          child: SafeArea(
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300]!, borderRadius: BorderRadius.circular(2)),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: Text('Annuler', style: TextStyle(color: AppTheme.colors.textSecondary, fontSize: 16)),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                      const Text('Nouvelle demande', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                      TextButton(
                        child: Text('Envoyer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.colors.primary)),
                        onPressed: () async {
                          if (titleController.text.isEmpty) return;
                          try {
                            final userCompany = await CompanyService.getUserCompany();
                            if (userCompany == null) return;

                            await SupabaseService.client.from('client_requests').insert({
                              'client_id': userCompany['company_id'],
                              'title': titleController.text,
                              'description': descriptionController.text,
                              'request_type': selectedType,
                              'status': 'pending',
                            });

                            Navigator.pop(dialogContext);
                            _loadData();
                          } catch (e) {
                            debugPrint('Erreur création demande: $e');
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type de demande', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.colors.textSecondary)),
                        const SizedBox(height: 8),
                        // Replace CupertinoSlidingSegmentedControl with a Row of toggle buttons
                        Row(
                          children: [
                            _buildTypeButton('general', 'Général', selectedType, (v) => setDialogState(() => selectedType = v)),
                            const SizedBox(width: 6),
                            _buildTypeButton('support', 'Support', selectedType, (v) => setDialogState(() => selectedType = v)),
                            const SizedBox(width: 6),
                            _buildTypeButton('quote', 'Devis', selectedType, (v) => setDialogState(() => selectedType = v)),
                            const SizedBox(width: 6),
                            _buildTypeButton('question', 'Question', selectedType, (v) => setDialogState(() => selectedType = v)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text('Titre', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.colors.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: titleController,
                          decoration: InputDecoration(
                            hintText: 'Titre de votre demande',
                            filled: true,
                            fillColor: AppTheme.colors.inputBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text('Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.colors.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: descriptionController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Décrivez votre demande en détail...',
                            filled: true,
                            fillColor: AppTheme.colors.inputBackground,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String value, String label, String current, Function(String) onSelect) {
    final isSelected = current == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.colors.primary : AppTheme.colors.inputBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
