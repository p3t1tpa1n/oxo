import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oxo/services/supabase_service.dart';
import '../../config/app_theme.dart';

class IOSMobileClientRequestsPage extends StatefulWidget {
  const IOSMobileClientRequestsPage({Key? key}) : super(key: key);

  @override
  State<IOSMobileClientRequestsPage> createState() => _IOSMobileClientRequestsPageState();
}

class _IOSMobileClientRequestsPageState extends State<IOSMobileClientRequestsPage> {
  List<Map<String, dynamic>> _projectProposals = [];
  List<Map<String, dynamic>> _timeExtensionRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final proposalsFuture = SupabaseService.getProjectProposals();
      final extensionsFuture = SupabaseService.getTimeExtensionRequests();
      
      final results = await Future.wait([proposalsFuture, extensionsFuture]);
      
      if (mounted) {
        setState(() {
          _projectProposals = List<Map<String, dynamic>>.from(results[0]);
          _timeExtensionRequests = List<Map<String, dynamic>>.from(results[1]);
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement demandes clients: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: TextStyle(
        decoration: TextDecoration.none,
        color: AppTheme.colors.textPrimary,
      ),
      child: Container(
        color: AppTheme.colors.background,
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Center(
                      child: Text(
                        'Demandes Clients',
                        style: AppTheme.typography.h2.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.colors.textPrimary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                    SizedBox(height: AppTheme.spacing.lg),
                    
                    // Compteurs
                    _buildCounters(),
                    SizedBox(height: AppTheme.spacing.lg),
                    
                    // Liste des propositions
                    ..._projectProposals.map((proposal) => _buildProposalCard(proposal)),
                    
                    // Liste des extensions
                    ..._timeExtensionRequests.map((request) => _buildExtensionCard(request)),
                    
                    // État vide si aucune demande
                    if (_projectProposals.isEmpty && _timeExtensionRequests.isEmpty)
                      _buildEmptyState(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCounters() {
    final pendingProposals = _projectProposals.where((p) => p['status'] == 'pending').length;
    final pendingExtensions = _timeExtensionRequests.where((e) => e['status'] == 'pending').length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCounterCard(pendingProposals.toString(), 'Propositions'),
        _buildCounterCard(pendingExtensions.toString(), 'Extensions'),
      ],
    );
  }

  Widget _buildCounterCard(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.typography.h1.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.colors.textPrimary,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        Text(
          label,
          style: AppTheme.typography.bodyMedium.copyWith(
            color: AppTheme.colors.textSecondary,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildProposalCard(Map<String, dynamic> proposal) {
    final status = proposal['status'] ?? 'pending';
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la mission
          Text(
            proposal['mission_name'] ?? proposal['title'] ?? 'Nouvelle Mission',
            style: AppTheme.typography.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.colors.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.xs),
          
          // Client
          Text(
            'Client: ${proposal['client_name'] ?? 'Inconnu'}',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          
          // Description
          Text(
            proposal['description'] ?? 'Aucune description',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppTheme.spacing.md),
          
          // Boutons d'action
          if (status == 'pending')
            _buildActionButtons(
              onApprove: () => _updateStatus('project_proposals', proposal['id'], 'approved'),
              onReject: () => _updateStatus('project_proposals', proposal['id'], 'rejected'),
            ),
          
          // Badge de statut si déjà traité
          if (status != 'pending')
            _buildStatusBadge(status),
        ],
      ),
    );
  }

  Widget _buildExtensionCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          Text(
            'Extension de temps',
            style: AppTheme.typography.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.colors.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.xs),
          
          // Mission
          Text(
            'Mission: ${request['mission_name'] ?? request['mission_title'] ?? 'Inconnue'}',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.xs),
          
          // Client
          Text(
            'Client: ${request['client_name'] ?? 'Inconnu'}',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          
          // Jours demandés
          Text(
            'Jours demandés: ${request['days_requested'] ?? 0}',
            style: AppTheme.typography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.colors.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.xs),
          
          // Raison
          Text(
            request['reason'] ?? 'Aucune raison spécifiée',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppTheme.spacing.md),
          
          // Boutons d'action
          if (status == 'pending')
            _buildActionButtons(
              onApprove: () => _updateStatus('time_extension_requests', request['id'], 'approved'),
              onReject: () => _updateStatus('time_extension_requests', request['id'], 'rejected'),
            ),
          
          // Badge de statut si déjà traité
          if (status != 'pending')
            _buildStatusBadge(status),
        ],
      ),
    );
  }
  
  Widget _buildActionButtons({required VoidCallback onApprove, required VoidCallback onReject}) {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            color: const Color(0xFF34C759), // Vert iOS
            borderRadius: BorderRadius.circular(8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: onApprove,
            child: Text(
              'Approuver',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
        SizedBox(width: AppTheme.spacing.sm),
        Expanded(
          child: CupertinoButton(
            color: const Color(0xFFFF3B30), // Rouge iOS
            borderRadius: BorderRadius.circular(8),
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: onReject,
            child: Text(
              'Rejeter',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String label;
    
    switch (status) {
      case 'approved':
        badgeColor = const Color(0xFF34C759);
        label = 'Approuvé';
        break;
      case 'rejected':
        badgeColor = const Color(0xFFFF3B30);
        label = 'Rejeté';
        break;
      default:
        badgeColor = Colors.grey;
        label = status;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.sm,
        vertical: AppTheme.spacing.xs,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTheme.typography.caption.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 48,
              color: AppTheme.colors.textSecondary,
            ),
            SizedBox(height: AppTheme.spacing.md),
            Text(
              'Aucune demande',
              style: AppTheme.typography.h4.copyWith(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: AppTheme.spacing.xs),
            Text(
              'Les demandes clients apparaîtront ici',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStatus(String table, dynamic id, String newStatus) async {
    try {
      await SupabaseService.client.from(table).update({'status': newStatus}).eq('id', id);
      _loadData(); // Recharger les données
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Demande ${newStatus == 'approved' ? 'approuvée' : 'rejetée'}',
              style: const TextStyle(decoration: TextDecoration.none),
            ),
            backgroundColor: newStatus == 'approved' 
                ? const Color(0xFF34C759) 
                : const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Erreur lors de la mise à jour',
              style: TextStyle(decoration: TextDecoration.none),
            ),
            backgroundColor: const Color(0xFFFF3B30),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    }
  }
}
