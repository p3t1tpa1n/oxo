// ============================================================================
// MOBILE CLIENT PROJECTS TAB - OXO TIME SHEETS
// Tab Projets pour les Clients iOS
// Utilise STRICTEMENT AppTheme (pas IOSTheme)
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/device_detector.dart';

class MobileClientProjectsTab extends StatefulWidget {
  const MobileClientProjectsTab({Key? key}) : super(key: key);

  @override
  State<MobileClientProjectsTab> createState() => _MobileClientProjectsTabState();
}

class _MobileClientProjectsTabState extends State<MobileClientProjectsTab> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  String _selectedFilter = 'tous';
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
      // Récupérer les missions du client
      final projects = await SupabaseService.getClientRecentMissions();
      
      setState(() {
        _projects = projects;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement projets: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProjects {
    if (_selectedFilter == 'tous') return _projects;
    return _projects.where((p) {
      final status = p['progress_status'] ?? p['status'] ?? '';
      if (_selectedFilter == 'en_cours') {
        return status == 'en_cours' || status == 'in_progress';
      } else if (_selectedFilter == 'terminé') {
        return status == 'fait' || status == 'done' || status == 'completed';
      }
      return true;
    }).toList();
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
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildFilterButtons(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CupertinoActivityIndicator(
                          color: AppTheme.colors.primary,
                        ),
                      )
                    : _filteredProjects.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppTheme.colors.primary,
                            child: ListView.builder(
                              padding: EdgeInsets.all(AppTheme.spacing.md),
                              itemCount: _filteredProjects.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: AppTheme.spacing.sm),
                                  child: _buildProjectCard(_filteredProjects[index]),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
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
            'Mes Projets',
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

  Widget _buildFilterButtons() {
    return Container(
      height: 48,
      margin: EdgeInsets.symmetric(vertical: AppTheme.spacing.sm),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md),
        children: [
          _buildFilterButton('Tous', 'tous'),
          SizedBox(width: AppTheme.spacing.sm),
          _buildFilterButton('En cours', 'en_cours'),
          SizedBox(width: AppTheme.spacing.sm),
          _buildFilterButton('Terminés', 'terminé'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.md,
          vertical: AppTheme.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.colors.primary : AppTheme.colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.typography.bodyMedium.copyWith(
              color: isSelected ? Colors.white : AppTheme.colors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS),
            size: 64,
            color: AppTheme.colors.textSecondary,
          ),
          SizedBox(height: AppTheme.spacing.md),
          Text(
            'Aucun projet',
            style: AppTheme.typography.h3.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Text(
            'Vos projets apparaîtront ici',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final status = project['progress_status'] ?? project['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    
    String dateStr = '';
    try {
      final startDate = project['start_date'];
      if (startDate != null) {
        final date = startDate is String ? DateTime.parse(startDate) : startDate as DateTime;
        dateStr = DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      debugPrint('Erreur format date: $e');
    }

    final progress = project['completion_percentage'] ?? 0;

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
          onTap: () {
            Navigator.of(context, rootNavigator: true).pushNamed(
              '/mission_detail',
              arguments: project['id'],
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radius.medium),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project['title'] ?? 'Projet sans titre',
                        style: AppTheme.typography.h4.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.colors.textPrimary,
                          decoration: TextDecoration.none,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                if (project['description'] != null) ...[
                  SizedBox(height: AppTheme.spacing.xs),
                  Text(
                    project['description'],
                    style: AppTheme.typography.bodySmall.copyWith(
                      color: AppTheme.colors.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                SizedBox(height: AppTheme.spacing.md),
                // Barre de progression
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progression',
                          style: AppTheme.typography.caption.copyWith(
                            color: AppTheme.colors.textSecondary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Text(
                          '${progress.toInt()}%',
                          style: AppTheme.typography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.colors.textPrimary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppTheme.spacing.xs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress / 100,
                        minHeight: 6,
                        backgroundColor: AppTheme.colors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progress < 30
                              ? AppTheme.colors.error
                              : progress < 70
                                  ? AppTheme.colors.warning
                                  : AppTheme.colors.success,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacing.sm),
                Row(
                  children: [
                    if (dateStr.isNotEmpty) ...[
                      Icon(
                        CupertinoIcons.calendar,
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
                    ],
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
      case 'en_cours':
      case 'in_progress':
        return AppTheme.colors.info;
      case 'fait':
      case 'done':
      case 'completed':
        return AppTheme.colors.success;
      case 'à_assigner':
      case 'pending':
        return AppTheme.colors.warning;
      default:
        return AppTheme.colors.textSecondary;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'fait':
      case 'done':
      case 'completed':
        return 'Terminé';
      case 'en_cours':
      case 'in_progress':
        return 'En cours';
      case 'à_assigner':
      case 'pending':
        return 'En attente';
      default:
        return status;
    }
  }

  IconData _getIconForPlatform(IconData material, IconData cupertino) {
    return DeviceDetector.shouldUseIOSInterface() ? cupertino : material;
  }
}

