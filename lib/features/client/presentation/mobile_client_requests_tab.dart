// ============================================================================
// MOBILE CLIENT REQUESTS TAB - OXO TIME SHEETS
// Tab Demandes pour les Clients iOS
// Utilise STRICTEMENT AppTheme (pas IOSTheme)
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/device_detector.dart';

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
      final count = await SupabaseService.getUnreadNotificationsCount();
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
      final userCompany = await SupabaseService.getUserCompany();
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
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.colors.background,
      child: DefaultTextStyle(
        style: TextStyle(
          decoration: TextDecoration.none,
          color: AppTheme.colors.textPrimary,
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: CupertinoActivityIndicator(
                              color: AppTheme.colors.primary,
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
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _showNewRequestDialog,
                child: Container(
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
                  child: Icon(
                    _getIconForPlatform(AppIcons.add, AppIcons.addIOS),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
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
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/messaging');
            },
            child: Stack(
              children: [
                Icon(
                  _getIconForPlatform(AppIcons.notifications, AppIcons.notificationsIOS),
                  color: AppTheme.colors.textPrimary,
                  size: 24,
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.colors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/profile');
            },
            child: Icon(
              _getIconForPlatform(AppIcons.settings, AppIcons.settingsIOS),
              color: AppTheme.colors.textPrimary,
              size: 24,
            ),
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
          Icon(
            CupertinoIcons.doc_text_search,
            size: 64,
            color: AppTheme.colors.textSecondary,
          ),
          SizedBox(height: AppTheme.spacing.md),
          Text(
            'Aucune demande',
            style: AppTheme.typography.h3.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Text(
            'Créez une nouvelle demande\npour contacter l\'équipe',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spacing.lg),
          CupertinoButton(
            color: AppTheme.colors.primary,
            borderRadius: BorderRadius.circular(AppTheme.radius.medium),
            onPressed: _showNewRequestDialog,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(CupertinoIcons.plus, color: Colors.white),
                SizedBox(width: AppTheme.spacing.sm),
                Text(
                  'Nouvelle demande',
                  style: AppTheme.typography.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
        final parsedDate = DateTime.parse(date);
        dateStr = DateFormat('dd/MM/yyyy à HH:mm').format(parsedDate);
      }
    } catch (e) {
      debugPrint('Erreur format date: $e');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
                      child: Icon(
                        _getTypeIcon(type),
                        color: _getTypeColor(type),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['title'] ?? 'Demande',
                            style: AppTheme.typography.h4.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.colors.textPrimary,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _getTypeLabel(type),
                            style: AppTheme.typography.caption.copyWith(
                              color: AppTheme.colors.textSecondary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radius.small),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTheme.typography.caption.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
                if (request['description'] != null) ...[
                  SizedBox(height: AppTheme.spacing.sm),
                  Text(
                    request['description'],
                    style: AppTheme.typography.bodySmall.copyWith(
                      color: AppTheme.colors.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: AppTheme.spacing.sm),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.clock,
                      size: 14,
                      color: AppTheme.colors.textSecondary,
                    ),
                    SizedBox(width: 4),
                    Text(
                      dateStr,
                      style: AppTheme.typography.caption.copyWith(
                        color: AppTheme.colors.textSecondary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 16,
                      color: AppTheme.colors.textSecondary,
                    ),
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
        return CupertinoIcons.wrench;
      case 'quote':
        return CupertinoIcons.doc_text;
      case 'modification':
        return CupertinoIcons.pencil;
      case 'question':
        return CupertinoIcons.question_circle;
      default:
        return CupertinoIcons.doc;
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
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.circular(2),
                  ),
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
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Divider(height: 1),
                
                // Description
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          request['description'] ?? 'Aucune description',
                          style: const TextStyle(fontSize: 15),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Type de demande',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.secondaryLabel,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getTypeLabel(request['request_type'] ?? 'general'),
                          style: const TextStyle(fontSize: 15),
                        ),
                        if (request['created_at'] != null) ...[
                          const SizedBox(height: 20),
                          const Text(
                            'Date de création',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.parse(request['created_at'])),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                // Actions
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6,
                    border: const Border(top: BorderSide(color: CupertinoColors.separator)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          color: AppTheme.colors.primary,
                          borderRadius: BorderRadius.circular(10),
                          onPressed: () {
                            Navigator.pop(context);
                            _navigateToMessages(request);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(CupertinoIcons.chat_bubble, color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Envoyer un message', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CupertinoButton(
                        padding: const EdgeInsets.all(12),
                        color: CupertinoColors.systemGrey5,
                        borderRadius: BorderRadius.circular(10),
                        onPressed: () => Navigator.pop(context),
                        child: const Icon(CupertinoIcons.xmark, color: CupertinoColors.label, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToMessages(Map<String, dynamic> request) {
    // Naviguer vers la messagerie avec le contexte de la demande
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

    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text('Annuler'),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                        const Text(
                          'Nouvelle demande',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: const Text('Envoyer'),
                          onPressed: () async {
                            if (titleController.text.isEmpty) return;
                            
                            try {
                              final userCompany = await SupabaseService.getUserCompany();
                              if (userCompany == null) return;

                              await SupabaseService.client
                                  .from('client_requests')
                                  .insert({
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
                          const Text(
                            'Type de demande',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoSlidingSegmentedControl<String>(
                            groupValue: selectedType,
                            children: const {
                              'general': Text('Général'),
                              'support': Text('Support'),
                              'quote': Text('Devis'),
                              'question': Text('Question'),
                            },
                            onValueChanged: (value) {
                              if (value != null) {
                                setDialogState(() => selectedType = value);
                              }
                            },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          const Text(
                            'Titre',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            controller: titleController,
                            placeholder: 'Titre de votre demande',
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            controller: descriptionController,
                            placeholder: 'Décrivez votre demande en détail...',
                            maxLines: 5,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
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
      ),
    );
  }

  IconData _getIconForPlatform(IconData material, IconData cupertino) {
    return DeviceDetector.shouldUseIOSInterface() ? cupertino : material;
  }
}

