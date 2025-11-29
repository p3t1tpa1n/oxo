// ============================================================================
// MOBILE DASHBOARD TAB - OXO TIME SHEETS
// Dashboard iOS professionnel avec PARITÉ COMPLÈTE avec macOS
// Utilise STRICTEMENT AppTheme (pas IOSTheme)
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../services/supabase_service.dart';
import '../../../models/user_role.dart';
import '../../../utils/device_detector.dart';
import '../../../utils/progress_utils.dart';
import '../../../widgets/oxo_card.dart';

class MobileDashboardTab extends StatefulWidget {
  const MobileDashboardTab({Key? key}) : super(key: key);

  @override
  State<MobileDashboardTab> createState() => _MobileDashboardTabState();
}

class _MobileDashboardTabState extends State<MobileDashboardTab> {
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentMissions = [];
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
      final missions = await SupabaseService.getCompanyMissions();
      final userRole = SupabaseService.currentUserRole;
      
      int totalMissions = 0;
      int completedMissions = 0;
      int inProgressMissions = 0;
      int urgentMissions = 0;
      int overdueMissions = 0;
      double totalTimeProgress = 0;
      int missionsWithEndDate = 0;
      
      if (userRole == UserRole.partenaire) {
        final myMissions = missions.where((m) => 
          m['assigned_to'] == SupabaseService.currentUser?.id ||
          m['created_by'] == SupabaseService.currentUser?.id
        ).toList();
        
        totalMissions = myMissions.length;
        completedMissions = myMissions.where((m) => 
          m['status'] == 'done' || m['progress_status'] == 'fait'
        ).length;
        inProgressMissions = myMissions.where((m) => 
          m['status'] == 'in_progress' || m['progress_status'] == 'en_cours'
        ).length;
        urgentMissions = myMissions.where((m) => 
          (m['priority'] == 'urgent' || m['priority'] == 'high') && 
          (m['status'] != 'done' && m['progress_status'] != 'fait')
        ).length;
        
        // Calculer progression temporelle et missions en retard
        for (final mission in myMissions) {
          final startDate = mission['start_date'] != null 
            ? DateTime.tryParse(mission['start_date']) 
            : null;
          final endDate = mission['end_date'] != null 
            ? DateTime.tryParse(mission['end_date']) 
            : null;
          final createdAt = mission['created_at'] != null 
            ? DateTime.tryParse(mission['created_at']) 
            : null;
          
          if (endDate != null) {
            missionsWithEndDate++;
            final timeProgressDetails = ProgressUtils.calculateTimeProgressDetails(
              startDate: startDate,
              endDate: endDate,
              createdAt: createdAt,
            );
            totalTimeProgress += timeProgressDetails['progress'];
            if (timeProgressDetails['isOverdue']) {
              overdueMissions++;
            }
          }
        }
      } else {
        totalMissions = missions.length;
        completedMissions = missions.where((m) => 
          m['status'] == 'done' || m['progress_status'] == 'fait'
        ).length;
        inProgressMissions = missions.where((m) => 
          m['status'] == 'in_progress' || m['progress_status'] == 'en_cours'
        ).length;
        urgentMissions = missions.where((m) => 
          (m['priority'] == 'urgent' || m['priority'] == 'high') && 
          (m['status'] != 'done' && m['progress_status'] != 'fait')
        ).length;
        
        // Calculer progression temporelle et missions en retard
        for (final mission in missions) {
          final startDate = mission['start_date'] != null 
            ? DateTime.tryParse(mission['start_date']) 
            : null;
          final endDate = mission['end_date'] != null 
            ? DateTime.tryParse(mission['end_date']) 
            : null;
          final createdAt = mission['created_at'] != null 
            ? DateTime.tryParse(mission['created_at']) 
            : null;
          
          if (endDate != null) {
            missionsWithEndDate++;
            final timeProgressDetails = ProgressUtils.calculateTimeProgressDetails(
              startDate: startDate,
              endDate: endDate,
              createdAt: createdAt,
            );
            totalTimeProgress += timeProgressDetails['progress'];
            if (timeProgressDetails['isOverdue']) {
              overdueMissions++;
            }
          }
        }
      }
      
      final avgTimeProgress = missionsWithEndDate > 0 
        ? (totalTimeProgress / missionsWithEndDate * 100).round() 
        : 0;
      
      setState(() {
        _stats = {
          'total_missions': totalMissions,
          'completed_missions': completedMissions,
          'in_progress_missions': inProgressMissions,
          'urgent_missions': urgentMissions,
          'completion_rate': totalMissions > 0 
            ? (completedMissions / totalMissions * 100).round() 
            : 0,
          'time_progress': avgTimeProgress,
          'overdue_missions': overdueMissions,
          'missions_with_end_date': missionsWithEndDate,
        };
        // Limiter à 1-3 éléments récents selon la spécification
        _recentMissions = missions.take(3).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.colors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Header personnalisé
            _buildHeader(),
            
            // Contenu
            Expanded(
              child: _isLoading
                ? Center(
                    child: CupertinoActivityIndicator(
                      color: AppTheme.colors.primary,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: AppTheme.colors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(AppTheme.spacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeHeader(),
                          SizedBox(height: AppTheme.spacing.lg),
                          _buildOverviewSection(),
                          SizedBox(height: AppTheme.spacing.lg),
                          _buildQuickActionsSection(),
                          SizedBox(height: AppTheme.spacing.lg),
                          _buildRecentActivitySection(),
                        ],
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
          // Titre "Dashboard" en grand et gras
          Text(
            'Dashboard',
            style: AppTheme.typography.h1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.colors.textPrimary,
            ),
          ),
          Spacer(),
          // Icône cloche (notifications)
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
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.colors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          // Icône engrenage (paramètres)
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

  Widget _buildWelcomeHeader() {
    final user = SupabaseService.currentUser;
    final userName = user?.email?.split('@').first ?? 'Utilisateur';
    final greeting = _getGreeting();
    
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$greeting $userName",
                  style: AppTheme.typography.h4,
                ),
                SizedBox(height: 2),
                Text(
                  "Vue d'ensemble",
                  style: AppTheme.typography.bodySmall.copyWith(
                    color: AppTheme.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Icône de notifications
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              _getIconForPlatform(AppIcons.notifications, AppIcons.notificationsIOS),
              color: AppTheme.colors.textSecondary,
              size: 24,
            ),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          SizedBox(width: AppTheme.spacing.sm),
          // Avatar utilisateur
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.colors.primary,
            child: Text(
              userName.substring(0, 1).toUpperCase(),
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textOnPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Vue d'ensemble",
          style: AppTheme.typography.h4,
        ),
        SizedBox(height: AppTheme.spacing.sm),
        // Grille 2 colonnes avec TOUS les KPIs
        _buildKPIGrid(),
      ],
    );
  }

  Widget _buildKPIGrid() {
    // Grille 2 colonnes avec TOUS les KPIs du macOS
    return Column(
      children: [
        // Ligne 1: Missions total / Missions terminées
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                label: 'Missions',
                value: '${_stats['total_missions'] ?? 0}',
                subtitle: 'Total',
                color: AppTheme.colors.primary,
                icon: _getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS),
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: _buildKPICard(
                label: 'Terminées',
                value: '${_stats['completed_missions'] ?? 0}',
                subtitle: 'Complétées',
                color: AppTheme.colors.success,
                icon: _getIconForPlatform(AppIcons.done, AppIcons.doneIOS),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.sm),
        // Ligne 2: En cours / Urgentes
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                label: 'En cours',
                value: '${_stats['in_progress_missions'] ?? 0}',
                subtitle: 'Missions actives',
                color: AppTheme.colors.warning,
                icon: _getIconForPlatform(AppIcons.inProgress, AppIcons.inProgressIOS),
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: _buildKPICard(
                label: 'Urgentes',
                value: '${_stats['urgent_missions'] ?? 0}',
                subtitle: 'À traiter',
                color: AppTheme.colors.error,
                icon: _getIconForPlatform(AppIcons.warning, AppIcons.warningIOS),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.sm),
        // Ligne 3: Taux de complétion / Progression temporelle
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                label: 'Taux',
                value: '${_stats['completion_rate'] ?? 0}%',
                subtitle: 'Complétion',
                color: AppTheme.colors.secondary,
                icon: _getIconForPlatform(AppIcons.reporting, AppIcons.reportingIOS),
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: _buildKPICard(
                label: 'Progression',
                value: '${_stats['time_progress'] ?? 0}%',
                subtitle: 'Temporelle',
                color: (_stats['time_progress'] ?? 0) > 80 
                  ? AppTheme.colors.warning 
                  : AppTheme.colors.primary,
                icon: _getIconForPlatform(AppIcons.timesheet, AppIcons.timesheetIOS),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.sm),
        // Ligne 4: Missions en retard
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                label: 'En retard',
                value: '${_stats['overdue_missions'] ?? 0}',
                subtitle: 'Missions',
                color: (_stats['overdue_missions'] ?? 0) > 0 
                  ? AppTheme.colors.error 
                  : AppTheme.colors.success,
                icon: (_stats['overdue_missions'] ?? 0) > 0
                  ? _getIconForPlatform(AppIcons.warning, AppIcons.warningIOS)
                  : _getIconForPlatform(AppIcons.done, AppIcons.doneIOS),
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            // Espace vide pour garder la grille 2 colonnes
            Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required String label,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return OxoCard(
      padding: EdgeInsets.all(AppTheme.spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 18),
              SizedBox(width: AppTheme.spacing.xs),
            ],
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: AppTheme.typography.h3.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: AppTheme.typography.bodySmall.copyWith(
              color: AppTheme.colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTheme.typography.caption.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final userRole = SupabaseService.currentUserRole;
    
    if (userRole != UserRole.admin && userRole != UserRole.associe) {
      // Pour partenaires et clients, afficher les actions simples
      final actions = _getAllQuickActionsForRole(userRole);
      if (actions.isEmpty) return SizedBox.shrink();
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actions rapides',
            style: AppTheme.typography.h4,
          ),
          SizedBox(height: AppTheme.spacing.sm),
          _buildActionsGrid(actions),
        ],
      );
    }
    
    // Pour admin/associé : organiser en 3 groupes logiques
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Groupe 1: Missions
        _buildActionGroup(
          title: 'Missions',
          actions: [
            QuickAction(
              label: 'Nouvelle mission',
              icon: _getIconForPlatform(AppIcons.add, AppIcons.addIOS),
              onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/missions'),
            ),
            QuickAction(
              label: 'Gestion missions',
              icon: _getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS),
              onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/mission-management'),
            ),
            QuickAction(
              label: 'Disponibilités',
              icon: _getIconForPlatform(AppIcons.availability, AppIcons.availabilityIOS),
              onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/availability'),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.lg),
        // Groupe 2: Partenaires et clients
        _buildActionGroup(
          title: 'Partenaires et clients',
          actions: [
            QuickAction(
              label: 'Partenaires',
              icon: _getIconForPlatform(AppIcons.partners, AppIcons.partnersIOS),
              onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/partner-profiles'),
            ),
            QuickAction(
              label: 'Demandes clients',
              icon: _getIconForPlatform(AppIcons.requests, AppIcons.requestsIOS),
              onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/admin/client-requests'),
            ),
            QuickAction(
              label: 'Inviter utilisateur',
              icon: _getIconForPlatform(AppIcons.add, AppIcons.addIOS),
              onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/add_user'),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.lg),
        // Groupe 3: Outils
        _buildActionGroup(
          title: 'Outils',
          actions: [
            QuickAction(
              label: 'Timesheet',
              icon: _getIconForPlatform(AppIcons.timesheet, AppIcons.timesheetIOS),
              onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/timesheet'),
            ),
            QuickAction(
              label: 'Actions commerciales',
              icon: _getIconForPlatform(AppIcons.actions, AppIcons.actionsIOS),
              onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/actions'),
            ),
            QuickAction(
              label: 'Planifier réunion',
              icon: _getIconForPlatform(AppIcons.planning, AppIcons.planningIOS),
              onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/calendar'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionGroup({
    required String title,
    required List<QuickAction> actions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.typography.h4,
        ),
        SizedBox(height: AppTheme.spacing.sm),
        _buildActionsGrid(actions),
      ],
    );
  }

  List<QuickAction> _getAllQuickActionsForRole(UserRole? role) {
    final actions = <QuickAction>[];
    
    if (role == UserRole.admin || role == UserRole.associe) {
      actions.addAll([
        QuickAction(
          label: 'Nouvelle mission',
          icon: _getIconForPlatform(AppIcons.add, AppIcons.addIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/missions'),
        ),
        QuickAction(
          label: 'Inviter utilisateur',
          icon: _getIconForPlatform(AppIcons.add, AppIcons.addIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/add_user'),
        ),
        QuickAction(
          label: 'Timesheet',
          icon: _getIconForPlatform(AppIcons.timesheet, AppIcons.timesheetIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/timesheet'),
        ),
        QuickAction(
          label: 'Disponibilités',
          icon: _getIconForPlatform(AppIcons.availability, AppIcons.availabilityIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/availability'),
        ),
        QuickAction(
          label: 'Partenaires',
          icon: _getIconForPlatform(AppIcons.partners, AppIcons.partnersIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/partner-profiles'),
        ),
        QuickAction(
          label: 'Demandes clients',
          icon: _getIconForPlatform(AppIcons.requests, AppIcons.requestsIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/admin/client-requests'),
        ),
        QuickAction(
          label: 'Actions commerciales',
          icon: _getIconForPlatform(AppIcons.actions, AppIcons.actionsIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/actions'),
        ),
        QuickAction(
          label: 'Gestion missions',
          icon: _getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/mission-management'),
        ),
        QuickAction(
          label: 'Planifier réunion',
          icon: _getIconForPlatform(AppIcons.planning, AppIcons.planningIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/calendar'),
        ),
      ]);
    } else if (role == UserRole.partenaire) {
      actions.addAll([
        QuickAction(
          label: 'Mes missions',
          icon: _getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS),
          onTap: () {
            // TODO: Navigate to missions tab
          },
        ),
        QuickAction(
          label: 'Disponibilités',
          icon: _getIconForPlatform(AppIcons.availability, AppIcons.availabilityIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/availability'),
        ),
      ]);
    } else if (role == UserRole.client) {
      actions.addAll([
        QuickAction(
          label: 'Nouvelle demande',
          icon: _getIconForPlatform(AppIcons.add, AppIcons.addIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/admin/client-requests'),
        ),
        QuickAction(
          label: 'Messagerie',
          icon: _getIconForPlatform(AppIcons.messaging, AppIcons.messagingIOS),
          onTap: () => Navigator.of(context, rootNavigator: true).pushNamed('/messaging'),
        ),
      ]);
    }
    
    return actions;
  }

  Widget _buildActionsGrid(List<QuickAction> actions) {
    // Grille 2 colonnes pour toutes les actions
    return Column(
      children: [
        for (int i = 0; i < actions.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: _buildActionButton(actions[i]),
                ),
                if (i + 1 < actions.length) ...[
                  SizedBox(width: AppTheme.spacing.sm),
                  Expanded(
                    child: _buildActionButton(actions[i + 1]),
                  ),
                ] else
                  Expanded(child: SizedBox()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildActionButton(QuickAction action) {
    return OxoCard(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.sm,
        vertical: AppTheme.spacing.md,
      ),
      onTap: action.onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            action.icon,
            color: AppTheme.colors.primary,
            size: 18,
          ),
          SizedBox(width: AppTheme.spacing.xs),
          Flexible(
            child: Text(
              action.label,
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Activité récente',
              style: AppTheme.typography.h4,
            ),
            if (_recentMissions.isNotEmpty)
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text(
                  'Voir tout',
                  style: AppTheme.typography.bodySmall.copyWith(
                    color: AppTheme.colors.primary,
                  ),
                ),
                onPressed: () {
                  // TODO: Navigate to full activity history if exists
                },
              ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.sm),
        if (_recentMissions.isEmpty)
          OxoCard(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            child: Center(
              child: Text(
                'Aucune activité récente',
                style: AppTheme.typography.bodyMedium.copyWith(
                  color: AppTheme.colors.textSecondary,
                ),
              ),
            ),
          )
        else
          ..._recentMissions.map((mission) => Padding(
            padding: EdgeInsets.only(bottom: AppTheme.spacing.xs),
            child: _buildMissionItem(mission),
          )),
      ],
    );
  }

  Widget _buildMissionItem(Map<String, dynamic> mission) {
    final status = mission['progress_status'] ?? mission['status'] ?? 'pending';
    final statusColor = _getStatusColor(status);
    final updatedAt = mission['updated_at'] != null 
      ? DateTime.tryParse(mission['updated_at']) 
      : null;
    final createdAt = mission['created_at'] != null 
      ? DateTime.tryParse(mission['created_at']) 
      : null;
    final displayDate = updatedAt ?? createdAt;
    
    return OxoCard(
      padding: EdgeInsets.all(AppTheme.spacing.sm),
      onTap: () {
        Navigator.of(context, rootNavigator: true).pushNamed(
          '/mission_detail',
          arguments: mission['id'],
        );
      },
      child: Row(
        children: [
          // Icône de mission
          Icon(
            _getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS),
            color: statusColor,
            size: 20,
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission['title'] ?? 'Mission sans titre',
                  style: AppTheme.typography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    if (mission['company_name'] != null) ...[
                      Text(
                        mission['company_name'],
                        style: AppTheme.typography.bodySmall.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (displayDate != null) ...[
                        Text(
                          ' • ',
                          style: AppTheme.typography.bodySmall.copyWith(
                            color: AppTheme.colors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                    if (displayDate != null)
                      Text(
                        _formatDate(displayDate),
                        style: AppTheme.typography.bodySmall.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            _getIconForPlatform(AppIcons.next, AppIcons.nextIOS),
            color: AppTheme.colors.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return "Aujourd'hui";
    } else if (difference.inDays == 1) {
      return "Hier";
    } else if (difference.inDays < 7) {
      return "Il y a ${difference.inDays} jours";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'fait':
      case 'done':
      case 'completed':
        return AppTheme.colors.success;
      case 'en_cours':
      case 'in_progress':
        return AppTheme.colors.warning;
      case 'à_assigner':
      case 'pending':
        return AppTheme.colors.info;
      default:
        return AppTheme.colors.textSecondary;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Bonjour";
    if (hour < 17) return "Bonne après-midi";
    return "Bonsoir";
  }

  IconData _getIconForPlatform(IconData material, IconData cupertino) {
    return DeviceDetector.shouldUseIOSInterface() ? cupertino : material;
  }
}

class QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
