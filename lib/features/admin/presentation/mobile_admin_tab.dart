// ============================================================================
// MOBILE ADMIN TAB - OXO TIME SHEETS
// Tab Administration pour les Admins iOS
// Utilise STRICTEMENT AppTheme (pas IOSTheme)
// ============================================================================

import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../services/supabase_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/company_service.dart';

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
      final users = await SupabaseService.client
          .from('profiles')
          .select('role')
          .neq('role', 'client');

      final clients = await CompanyService.getAllCompanies();
      final missions = await SupabaseService.getCompanyMissions();

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
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: SafeArea(
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
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/messaging');
            },
            icon: Stack(
              children: [
                Icon(
                  AppIcons.notifications,
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
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/profile');
            },
            icon: Icon(
              AppIcons.settings,
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
                Icons.people,
                AppTheme.colors.primary,
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: _buildStatCard(
                'Clients',
                '${_stats['clients'] ?? 0}',
                Icons.business,
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
                Icons.folder,
                AppTheme.colors.info,
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: _buildStatCard(
                'Demandes',
                '${_stats['pendingRequests'] ?? 0}',
                Icons.notifications,
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
                Icons.person_add,
                AppTheme.colors.primary,
                () => Navigator.of(context, rootNavigator: true).pushNamed('/admin/roles'),
              ),
            ),
            SizedBox(width: AppTheme.spacing.sm),
            Expanded(
              child: _buildQuickActionButton(
                'Ajouter client',
                Icons.business,
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radius.medium),
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
                Icons.people,
                () => Navigator.of(context, rootNavigator: true).pushNamed('/admin/roles'),
              ),
              _buildDivider(),
              _buildManagementTile(
                'Gestion des clients',
                'Gérer les entreprises clientes',
                Icons.business,
                () => Navigator.of(context, rootNavigator: true).pushNamed('/clients'),
              ),
              _buildDivider(),
              _buildManagementTile(
                'Demandes clients',
                'Voir et traiter les demandes',
                Icons.notifications,
                () => Navigator.of(context, rootNavigator: true).pushNamed('/admin/client-requests'),
                badge: _stats['pendingRequests'] ?? 0,
              ),
              _buildDivider(),
              _buildManagementTile(
                'Profils partenaires',
                'Gérer les profils des partenaires',
                Icons.account_circle,
                () => Navigator.of(context, rootNavigator: true).pushNamed('/partner-profiles'),
              ),
              _buildDivider(),
              _buildManagementTile(
                'Reporting',
                'Voir les rapports et statistiques',
                Icons.bar_chart,
                () => _showReportingOptions(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManagementTile(String title, String subtitle, IconData icon, VoidCallback onTap, {int badge = 0}) {
    return InkWell(
      onTap: onTap,
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
              Icons.chevron_right,
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

  void _showReportingOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Rapports et Statistiques', style: AppTheme.typography.h4),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.pie_chart),
              title: const Text('Statistiques générales'),
              onTap: () {
                Navigator.pop(context);
                _showStatsReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Rapport des missions'),
              onTap: () {
                Navigator.pop(context);
                _showMissionsReport();
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Activité des partenaires'),
              onTap: () {
                Navigator.pop(context);
                _showPartnersReport();
              },
            ),
            ListTile(
              title: const Text('Fermer'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatsReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Statistiques Générales'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportRow('Utilisateurs actifs', '${_stats['users'] ?? 0}'),
            _buildReportRow('Clients', '${_stats['clients'] ?? 0}'),
            _buildReportRow('Missions en cours', '${_stats['missions'] ?? 0}'),
            _buildReportRow('Demandes en attente', '${_stats['pendingRequests'] ?? 0}'),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Fermer'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showMissionsReport() async {
    try {
      final missions = await SupabaseService.getCompanyMissions();

      int enCours = 0;
      int termine = 0;
      int aAssigner = 0;

      for (final m in missions) {
        final status = m['progress_status'] ?? m['status'] ?? '';
        if (status == 'en_cours' || status == 'in_progress') enCours++;
        else if (status == 'fait' || status == 'done' || status == 'completed') termine++;
        else aAssigner++;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Rapport des Missions'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportRow('Total missions', '${missions.length}'),
              _buildReportRow('En cours', '$enCours'),
              _buildReportRow('Terminées', '$termine'),
              _buildReportRow('À assigner', '$aAssigner'),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Fermer'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Erreur rapport missions: $e');
    }
  }

  Future<void> _showPartnersReport() async {
    try {
      final partners = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('role', 'partenaire');

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Activité des Partenaires'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReportRow('Partenaires actifs', '${partners.length}'),
              const SizedBox(height: 8),
              Text(
                'Pour un rapport détaillé, consultez la section "Profils partenaires".',
                style: TextStyle(fontSize: 12, color: AppTheme.colors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Voir les profils'),
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context, rootNavigator: true).pushNamed('/partner-profiles');
              },
            ),
            TextButton(
              child: const Text('Fermer'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Erreur rapport partenaires: $e');
    }
  }
}
