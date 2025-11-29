// ============================================================================
// MOBILE ADMIN TAB - OXO TIME SHEETS
// Tab Administration pour les Admins iOS
// Utilise STRICTEMENT AppTheme (pas IOSTheme)
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/device_detector.dart';

class MobileAdminTab extends StatefulWidget {
  const MobileAdminTab({Key? key}) : super(key: key);

  @override
  State<MobileAdminTab> createState() => _MobileAdminTabState();
}

class _MobileAdminTabState extends State<MobileAdminTab> {
  Map<String, int> _stats = {};
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
      // Charger les statistiques
      final users = await SupabaseService.client
          .from('profiles')
          .select('role')
          .neq('role', 'client');
      
      final clients = await SupabaseService.getAllCompanies();
      final missions = await SupabaseService.getCompanyMissions();
      
      // Compter les demandes clients en attente
      int pendingRequests = 0;
      try {
        final requests = await SupabaseService.client
            .from('client_requests')
            .select('id')
            .eq('status', 'pending');
        pendingRequests = requests.length;
      } catch (e) {
        debugPrint('Erreur chargement demandes: $e');
      }

      setState(() {
        _stats = {
          'users': users.length,
          'clients': clients.length,
          'missions': missions.length,
          'pendingRequests': pendingRequests,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement stats admin: $e');
      setState(() => _isLoading = false);
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
        child: SafeArea(
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
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppTheme.colors.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.all(AppTheme.spacing.md),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatsSection(),
                              SizedBox(height: AppTheme.spacing.lg),
                              _buildQuickActionsSection(),
                              SizedBox(height: AppTheme.spacing.lg),
                              _buildManagementSection(),
                            ],
                          ),
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
            'Administration',
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

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vue d\'ensemble',
          style: AppTheme.typography.h3.copyWith(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: AppTheme.spacing.md),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Utilisateurs',
                '${_stats['users'] ?? 0}',
                CupertinoIcons.person_2,
                AppTheme.colors.primary,
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: _buildStatCard(
                'Clients',
                '${_stats['clients'] ?? 0}',
                CupertinoIcons.building_2_fill,
                AppTheme.colors.success,
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.spacing.sm),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Missions',
                '${_stats['missions'] ?? 0}',
                CupertinoIcons.folder,
                AppTheme.colors.info,
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: _buildStatCard(
                'Demandes',
                '${_stats['pendingRequests'] ?? 0}',
                CupertinoIcons.bell,
                AppTheme.colors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppTheme.spacing.sm),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radius.small),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: AppTheme.spacing.md),
          Text(
            value,
            style: AppTheme.typography.h2.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            title,
            style: AppTheme.typography.bodySmall.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: AppTheme.typography.h3.copyWith(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: AppTheme.spacing.md),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionButton(
                'Ajouter utilisateur',
                CupertinoIcons.person_add,
                AppTheme.colors.primary,
                () => Navigator.of(context, rootNavigator: true).pushNamed('/admin/roles'),
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: _buildQuickActionButton(
                'Ajouter client',
                CupertinoIcons.building_2_fill,
                AppTheme.colors.success,
                () => Navigator.of(context, rootNavigator: true).pushNamed('/create-client'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacing.md),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: AppTheme.spacing.sm),
            Flexible(
              child: Text(
                label,
                style: AppTheme.typography.bodySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gestion',
          style: AppTheme.typography.h3.copyWith(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        ),
        SizedBox(height: AppTheme.spacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius.medium),
          ),
          child: Column(
            children: [
              _buildManagementTile(
                'Gestion des utilisateurs',
                'Ajouter, modifier ou supprimer des utilisateurs',
                CupertinoIcons.person_2,
                () => Navigator.of(context, rootNavigator: true).pushNamed('/admin/roles'),
              ),
              _buildDivider(),
              _buildManagementTile(
                'Gestion des clients',
                'Gérer les entreprises clientes',
                CupertinoIcons.building_2_fill,
                () => Navigator.of(context, rootNavigator: true).pushNamed('/clients'),
              ),
              _buildDivider(),
              _buildManagementTile(
                'Demandes clients',
                'Voir et traiter les demandes',
                CupertinoIcons.bell,
                () => Navigator.of(context, rootNavigator: true).pushNamed('/admin/client-requests'),
                badge: _stats['pendingRequests'] ?? 0,
              ),
              _buildDivider(),
              _buildManagementTile(
                'Profils partenaires',
                'Gérer les profils des partenaires',
                CupertinoIcons.person_crop_circle,
                () => Navigator.of(context, rootNavigator: true).pushNamed('/partner-profiles'),
              ),
              _buildDivider(),
              _buildManagementTile(
                'Reporting',
                'Voir les rapports et statistiques',
                CupertinoIcons.chart_bar,
                () {
                  // TODO: Naviguer vers le reporting
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManagementTile(String title, String subtitle, IconData icon, VoidCallback onTap, {int badge = 0}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacing.md),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppTheme.spacing.sm),
              decoration: BoxDecoration(
                color: AppTheme.colors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radius.small),
              ),
              child: Icon(icon, color: AppTheme.colors.primary, size: 22),
            ),
            SizedBox(width: AppTheme.spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTheme.typography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.colors.textPrimary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTheme.typography.caption.copyWith(
                      color: AppTheme.colors.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
              ),
            ),
            if (badge > 0)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.colors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: AppTheme.typography.caption.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            SizedBox(width: AppTheme.spacing.sm),
            Icon(
              CupertinoIcons.chevron_right,
              color: AppTheme.colors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 56,
      color: AppTheme.colors.border,
    );
  }

  IconData _getIconForPlatform(IconData material, IconData cupertino) {
    return DeviceDetector.shouldUseIOSInterface() ? cupertino : material;
  }
}

