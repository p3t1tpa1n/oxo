import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oxo/services/supabase_service.dart';
import '../../config/app_theme.dart';

class IOSMobileActionsPage extends StatefulWidget {
  final bool showHeader;
  
  const IOSMobileActionsPage({
    Key? key,
    this.showHeader = true,
  }) : super(key: key);

  @override
  State<IOSMobileActionsPage> createState() => _IOSMobileActionsPageState();
}

class _IOSMobileActionsPageState extends State<IOSMobileActionsPage> {
  List<Map<String, dynamic>> _actions = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    setState(() => _isLoading = true);
    try {
      final actions = await SupabaseService.getCommercialActions();
      if (mounted) {
        setState(() => _actions = actions);
      }
    } catch (e) {
      debugPrint('Erreur chargement actions: $e');
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
            : Column(
                children: [
                  // Header avec bouton retour (optionnel)
                  if (widget.showHeader) _buildHeader(),
                  // Compteurs
                  _buildCounters(),
                  // Filtres
                  _buildFilters(),
                  // Liste
                  Expanded(child: _buildActionsList()),
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
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              CupertinoIcons.chevron_left,
              color: AppTheme.colors.textPrimary,
              size: 24,
            ),
          ),
          SizedBox(width: AppTheme.spacing.md),
          Expanded(
            child: Text(
              'Actions Commerciales',
              style: AppTheme.typography.h3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.colors.textPrimary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounters() {
    final activeActions = _actions.where((a) {
      final status = a['status'] ?? '';
      return status == 'in_progress' || status == 'planned';
    }).length;
    
    final potentialValue = _actions.fold(0.0, (sum, a) {
      final value = a['estimated_value'] ?? a['potential_value'] ?? 0;
      return sum + (value is num ? value.toDouble() : 0.0);
    });

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildCounterCard(activeActions.toString(), 'Actions en cours'),
          _buildCounterCard(potentialValue.toStringAsFixed(0), 'Valeur potentielle'),
        ],
      ),
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

  Widget _buildFilters() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.sm,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('Toutes', 'all'),
            SizedBox(width: AppTheme.spacing.sm),
            _buildFilterChip('En cours', 'in_progress'),
            SizedBox(width: AppTheme.spacing.sm),
            _buildFilterChip('Terminées', 'completed'),
            SizedBox(width: AppTheme.spacing.sm),
            _buildFilterChip('Annulées', 'cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.md,
          vertical: AppTheme.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.colors.primary : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.colors.primary : AppTheme.colors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTheme.typography.bodyMedium.copyWith(
            color: isSelected ? Colors.white : AppTheme.colors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }

  Widget _buildActionsList() {
    final filteredActions = _actions.where((action) {
      if (_filterStatus == 'all') return true;
      final status = action['status'] ?? '';
      if (_filterStatus == 'in_progress') {
        return status == 'in_progress' || status == 'planned';
      }
      if (_filterStatus == 'completed') {
        return status == 'completed' || status == 'done';
      }
      return status == _filterStatus;
    }).toList();

    if (filteredActions.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadActions,
      color: AppTheme.colors.primary,
      child: ListView.builder(
        padding: EdgeInsets.all(AppTheme.spacing.md),
        itemCount: filteredActions.length,
        itemBuilder: (context, index) {
          return _buildActionCard(filteredActions[index]);
        },
      ),
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    final status = action['status'] ?? 'planned';
    final dueDate = DateTime.tryParse(action['due_date'] ?? '');
    final estimatedValue = action['estimated_value'] ?? action['potential_value'] ?? 0;

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.md),
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: _getStatusColor(status),
            width: 4,
          ),
        ),
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
            action['title'] ?? 'Action non définie',
            style: AppTheme.typography.h4.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.colors.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.xs),
          
          // Client
          Text(
            'Client: ${action['client_name'] ?? 'Non spécifié'}',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          
          // Description
          Text(
            action['description'] ?? action['notes'] ?? '',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppTheme.spacing.md),
          
          // Badges
          Row(
            children: [
              _buildInfoBadge(
                '${estimatedValue is num ? estimatedValue.toStringAsFixed(0) : estimatedValue}€',
                CupertinoIcons.money_euro_circle,
              ),
              SizedBox(width: AppTheme.spacing.sm),
              if (dueDate != null)
                _buildInfoBadge(
                  DateFormat('dd/MM/yyyy').format(dueDate),
                  CupertinoIcons.calendar,
                ),
              const Spacer(),
              // Badge statut
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: AppTheme.typography.caption.copyWith(
                    color: _getStatusColor(status),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoBadge(String text, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppTheme.colors.inputBackground,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.colors.textSecondary),
          SizedBox(width: 4),
          Text(
            text,
            style: AppTheme.typography.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: AppTheme.colors.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
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
              CupertinoIcons.briefcase,
              size: 48,
              color: AppTheme.colors.textSecondary,
            ),
            SizedBox(height: AppTheme.spacing.md),
            Text(
              'Aucune action commerciale',
              style: AppTheme.typography.h4.copyWith(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: AppTheme.spacing.xs),
            Text(
              'Créez votre première action pour commencer votre prospection.',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
      case 'planned':
        return const Color(0xFFF59E0B); // Orange
      case 'done':
      case 'completed':
        return const Color(0xFF34C759); // Vert
      case 'cancelled':
        return const Color(0xFFFF3B30); // Rouge
      default:
        return AppTheme.colors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'in_progress':
        return 'En cours';
      case 'planned':
        return 'Planifiée';
      case 'done':
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return 'N/A';
    }
  }
}
