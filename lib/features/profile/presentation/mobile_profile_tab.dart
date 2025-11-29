// ============================================================================
// MOBILE PROFILE TAB - OXO TIME SHEETS
// Profil iOS compact avec stats et préférences
// Utilise STRICTEMENT AppTheme
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../services/supabase_service.dart';
import '../../../models/user_role.dart';
import '../../../utils/device_detector.dart';
import '../../../services/feedback_service.dart';
import '../../../widgets/oxo_card.dart';
import 'preferences_page.dart';

class MobileProfileTab extends StatefulWidget {
  const MobileProfileTab({Key? key}) : super(key: key);

  @override
  State<MobileProfileTab> createState() => _MobileProfileTabState();
}

class _MobileProfileTabState extends State<MobileProfileTab> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
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

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final missions = await SupabaseService.getCompanyMissions();
      final userRole = SupabaseService.currentUserRole;
      
      int totalMissions = 0;
      int completedMissions = 0;
      
      if (userRole == UserRole.partenaire) {
        final myMissions = missions.where((m) => 
          m['assigned_to'] == SupabaseService.currentUser?.id ||
          m['created_by'] == SupabaseService.currentUser?.id
        ).toList();
        
        totalMissions = myMissions.length;
        completedMissions = myMissions.where((m) => 
          m['status'] == 'done' || m['progress_status'] == 'fait'
        ).length;
      } else {
        totalMissions = missions.length;
        completedMissions = missions.where((m) => 
          m['status'] == 'done' || m['progress_status'] == 'fait'
        ).length;
      }
      
      setState(() {
        _stats = {
          'total_missions': totalMissions,
          'completed_missions': completedMissions,
          'days_logged': 0, // TODO: Charger depuis timesheet
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;
    
    if (user == null) {
      return CupertinoPageScaffold(
        child: Center(
          child: Text('Non connecté'),
        ),
      );
    }

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.colors.background,
      child: SafeArea(
        child: Column(
          children: [
            // Header personnalisé
            _buildHeader(),
            
            // Contenu
            Expanded(
              child:
              _isLoading
                ? Center(
                    child: CupertinoActivityIndicator(
                      color: AppTheme.colors.primary,
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadStats,
                    color: AppTheme.colors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(AppTheme.spacing.md),
                      child: Column(
                        children: [
                          _buildProfileHeader(user),
                          SizedBox(height: AppTheme.spacing.lg),
                          _buildWeeklyStats(),
                          SizedBox(height: AppTheme.spacing.lg),
                          _buildPreferencesSection(),
                          SizedBox(height: AppTheme.spacing.lg),
                          _buildLogoutButton(),
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
          // Titre "Profil" en grand et gras
          Text(
            'Profil',
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
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const PreferencesPage(),
                ),
              );
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

  Widget _buildProfileHeader(user) {
    final userName = user.email?.split('@').first ?? 'Utilisateur';
    final userRole = SupabaseService.currentUserRole;
    
    return OxoCard(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.colors.primary,
            child: Text(
              userName.substring(0, 1).toUpperCase(),
              style: AppTheme.typography.h1.copyWith(
                color: AppTheme.colors.textOnPrimary,
              ),
            ),
          ),
          SizedBox(height: AppTheme.spacing.md),
          Text(
            userName,
            style: AppTheme.typography.h3,
          ),
          SizedBox(height: AppTheme.spacing.xs),
          Text(
            user.email ?? '',
            style: AppTheme.typography.bodySmall.copyWith(
              color: AppTheme.colors.textSecondary,
            ),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spacing.md,
              vertical: AppTheme.spacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppTheme.colors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radius.small),
            ),
            child: Text(
              _getRoleLabel(userRole),
              style: AppTheme.typography.bodySmall.copyWith(
                color: AppTheme.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats() {
    return OxoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: AppTheme.typography.h4,
          ),
          SizedBox(height: AppTheme.spacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                label: 'Missions',
                value: '${_stats['total_missions'] ?? 0}',
                icon: _getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS),
              ),
              _buildStatItem(
                label: 'Terminées',
                value: '${_stats['completed_missions'] ?? 0}',
                icon: _getIconForPlatform(AppIcons.done, AppIcons.doneIOS),
              ),
              _buildStatItem(
                label: 'Jours',
                value: '${_stats['days_logged'] ?? 0}',
                icon: _getIconForPlatform(AppIcons.timesheet, AppIcons.timesheetIOS),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.colors.primary, size: 24),
        SizedBox(height: AppTheme.spacing.xs),
        Text(
          value,
          style: AppTheme.typography.h3.copyWith(
            color: AppTheme.colors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: AppTheme.typography.caption.copyWith(
            color: AppTheme.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return OxoCard(
      child: Column(
        children: [
          _buildPreferenceTile(
            icon: _getIconForPlatform(AppIcons.settings, AppIcons.settingsIOS),
            title: 'Préférences',
            subtitle: 'Thème, notifications, etc.',
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const PreferencesPage(),
                ),
              );
            },
          ),
          Divider(
            height: 1,
            color: AppTheme.colors.border,
            thickness: 0.5,
          ),
          if (SupabaseService.currentUserRole == UserRole.admin)
            _buildPreferenceTile(
              icon: _getIconForPlatform(AppIcons.admin, AppIcons.adminIOS),
              title: 'Gestion des rôles',
              subtitle: 'Administration',
              onTap: () {
                Navigator.of(context, rootNavigator: true).pushNamed('/admin/roles');
              },
            ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.md,
          vertical: AppTheme.spacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.colors.primary, size: 20),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.typography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTheme.typography.bodySmall.copyWith(
                      color: AppTheme.colors.textSecondary,
                    ),
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
      ),
    );
  }

  Widget _buildLogoutButton() {
    return OxoCard(
      backgroundColor: AppTheme.colors.error.withOpacity(0.1),
      onTap: _handleLogout,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.sm),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForPlatform(AppIcons.logout, AppIcons.logoutIOS),
              color: AppTheme.colors.error,
              size: 20,
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Text(
              'Déconnexion',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout() async {
    final confirmed = await FeedbackService.showConfirmDialog(
      context,
      title: 'Déconnexion',
      message: 'Êtes-vous sûr de vouloir vous déconnecter ?',
      confirmText: 'Déconnexion',
      cancelText: 'Annuler',
      isDestructive: true,
    );
    
    if (confirmed) {
      try {
        await SupabaseService.signOut();
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      } catch (e) {
        if (mounted) {
          FeedbackService.showError(context, 'Erreur lors de la déconnexion: $e');
        }
      }
    }
  }

  String _getRoleLabel(UserRole? role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrateur';
      case UserRole.associe:
        return 'Associé';
      case UserRole.partenaire:
        return 'Partenaire';
      case UserRole.client:
        return 'Client';
      default:
        return 'Utilisateur';
    }
  }

  IconData _getIconForPlatform(IconData material, IconData cupertino) {
    return DeviceDetector.shouldUseIOSInterface() ? cupertino : material;
  }
}

