// ============================================================================
// PROFILE PAGE IMPROVED - OXO TIME SHEETS
// Page de profil améliorée avec stats et accès aux préférences
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../config/ios_theme.dart';
import '../../../config/app_theme.dart';
import '../../../services/supabase_service.dart';
import '../../../models/user_role.dart';
import '../../../utils/device_detector.dart';
import '../../../widgets/ios_widgets.dart';
import '../../../services/feedback_service.dart';
import 'preferences_page.dart';

class ProfilePageImproved extends StatefulWidget {
  const ProfilePageImproved({Key? key}) : super(key: key);

  @override
  State<ProfilePageImproved> createState() => _ProfilePageImprovedState();
}

class _ProfilePageImprovedState extends State<ProfilePageImproved> {
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();
  }

  Future<void> _loadUserStats() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger les statistiques de l'utilisateur
      final missions = await SupabaseService.getCompanyMissions();
      final userRole = SupabaseService.currentUserRole;
      
      int totalMissions = 0;
      int completedMissions = 0;
      int daysLogged = 0;
      
      if (userRole == UserRole.partenaire) {
        // Pour les partenaires, compter seulement leurs missions
        final myMissions = missions.where((m) => 
          m['assigned_to'] == SupabaseService.currentUser?.id ||
          m['created_by'] == SupabaseService.currentUser?.id
        ).toList();
        
        totalMissions = myMissions.length;
        completedMissions = myMissions.where((m) => m['status'] == 'done').length;
      } else {
        totalMissions = missions.length;
        completedMissions = missions.where((m) => m['status'] == 'done').length;
      }
      
      // TODO: Charger les jours de timesheet depuis Supabase
      // daysLogged = await SupabaseService.getDaysLogged();
      
      setState(() {
        _stats = {
          'total_missions': totalMissions,
          'completed_missions': completedMissions,
          'days_logged': daysLogged,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIOS = DeviceDetector.shouldUseIOSInterface();
    final user = SupabaseService.currentUser;
    
    if (user == null) {
      Navigator.of(context).pushReplacementNamed('/login');
      return const SizedBox.shrink();
    }

    if (isIOS) {
      return CupertinoPageScaffold(
        backgroundColor: IOSTheme.systemGroupedBackground,
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Profil'),
        ),
        child: SafeArea(
          child: _buildIOSContent(user),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mon Profil'),
          backgroundColor: AppTheme.colors.primary,
          foregroundColor: Colors.white,
        ),
        body: _buildDesktopContent(user),
      );
    }
  }

  Widget _buildIOSContent(user) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 24),
          
          // Header avec avatar et infos
          _buildProfileHeader(user, isIOS: true),
          
          const SizedBox(height: 32),
          
          // Stats
          _buildStatsSection(isIOS: true),
          
          const SizedBox(height: 24),
          
          // Menu
          _buildMenuSection(isIOS: true),
          
          const SizedBox(height: 24),
          
          // Déconnexion
          _buildLogoutSection(isIOS: true),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(user) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacing.lg),
      child: Column(
        children: [
          _buildProfileHeader(user, isIOS: false),
          SizedBox(height: AppTheme.spacing.xl),
          _buildStatsSection(isIOS: false),
          SizedBox(height: AppTheme.spacing.xl),
          _buildMenuSection(isIOS: false),
          SizedBox(height: AppTheme.spacing.xl),
          _buildLogoutSection(isIOS: false),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(user, {required bool isIOS}) {
    final userName = user.email?.split('@').first ?? 'Utilisateur';
    final userRole = SupabaseService.currentUserRole;
    
    return Column(
      children: [
        CircleAvatar(
          radius: isIOS ? 50 : 60,
          backgroundColor: isIOS ? IOSTheme.primaryBlue : AppTheme.colors.primary,
          child: Text(
            userName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: isIOS ? 32 : 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: isIOS ? 16 : 20),
        Text(
          userName,
          style: isIOS ? IOSTheme.title2 : AppTheme.typography.h2,
        ),
        SizedBox(height: 4),
        Text(
          user.email ?? '',
          style: isIOS 
            ? IOSTheme.body.copyWith(color: IOSTheme.labelSecondary)
            : AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: (isIOS ? IOSTheme.primaryBlue : AppTheme.colors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _getRoleLabel(userRole),
            style: TextStyle(
              color: isIOS ? IOSTheme.primaryBlue : AppTheme.colors.primary,
              fontWeight: FontWeight.w600,
              fontSize: isIOS ? 13 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection({required bool isIOS}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isIOS ? 16 : 0),
      padding: EdgeInsets.all(isIOS ? 16 : 20),
      decoration: isIOS 
        ? IOSTheme.cardDecoration
        : BoxDecoration(
            color: AppTheme.colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius.medium),
            border: Border.all(color: AppTheme.colors.border),
          ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: isIOS ? IOSTheme.title3 : AppTheme.typography.h3,
          ),
          SizedBox(height: isIOS ? 16 : 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  label: 'Missions',
                  value: '${_stats['total_missions'] ?? 0}',
                  icon: isIOS ? CupertinoIcons.folder : Icons.folder,
                  color: isIOS ? IOSTheme.primaryBlue : AppTheme.colors.primary,
                  isIOS: isIOS,
                ),
              ),
              SizedBox(width: isIOS ? 12 : 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Terminées',
                  value: '${_stats['completed_missions'] ?? 0}',
                  icon: isIOS ? CupertinoIcons.checkmark_circle : Icons.check_circle,
                  color: isIOS ? IOSTheme.successColor : AppTheme.colors.success,
                  isIOS: isIOS,
                ),
              ),
              SizedBox(width: isIOS ? 12 : 16),
              Expanded(
                child: _buildStatItem(
                  label: 'Jours',
                  value: '${_stats['days_logged'] ?? 0}',
                  icon: isIOS ? CupertinoIcons.calendar : Icons.calendar_today,
                  color: isIOS ? IOSTheme.systemOrange : AppTheme.colors.warning,
                  isIOS: isIOS,
                ),
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
    required Color color,
    required bool isIOS,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: isIOS ? 24 : 28),
        SizedBox(height: 8),
        Text(
          value,
          style: isIOS 
            ? IOSTheme.title2.copyWith(color: color, fontWeight: FontWeight.bold)
            : AppTheme.typography.h2.copyWith(color: color),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: isIOS 
            ? IOSTheme.caption1
            : AppTheme.typography.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuSection({required bool isIOS}) {
    if (isIOS) {
      return IOSListSection(
        title: 'Paramètres',
        children: [
          IOSListTile(
            leading: const Icon(CupertinoIcons.settings, color: IOSTheme.primaryBlue),
            title: const Text('Préférences', style: IOSTheme.body),
            subtitle: const Text('Thème, notifications, etc.', style: IOSTheme.footnote),
            trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.systemGray),
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const PreferencesPage(),
                ),
              );
            },
          ),
          IOSListTile(
            leading: const Icon(CupertinoIcons.person_circle, color: IOSTheme.systemOrange),
            title: const Text('Informations personnelles', style: IOSTheme.body),
            subtitle: const Text('Modifier votre profil', style: IOSTheme.footnote),
            trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.systemGray),
            onTap: () {
              // TODO: Navigation vers édition profil
            },
          ),
          if (SupabaseService.currentUserRole == UserRole.admin)
            IOSListTile(
              leading: const Icon(CupertinoIcons.shield, color: IOSTheme.systemRed),
              title: const Text('Gestion des rôles', style: IOSTheme.body),
              subtitle: const Text('Administration', style: IOSTheme.footnote),
              trailing: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.systemGray),
              onTap: () {
                Navigator.of(context, rootNavigator: true).pushNamed('/admin/roles');
              },
            ),
        ],
      );
    } else {
      return Card(
        child: Column(
          children: [
            ListTile(
              leading: Icon(Icons.settings, color: AppTheme.colors.primary),
              title: const Text('Préférences'),
              subtitle: const Text('Thème, notifications, etc.'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PreferencesPage(),
                  ),
                );
              },
            ),
            Divider(
              color: AppTheme.colors.border,
              thickness: 0.5,
            ),
            ListTile(
              leading: Icon(Icons.person, color: AppTheme.colors.primary),
              title: const Text('Informations personnelles'),
              subtitle: const Text('Modifier votre profil'),
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                // TODO: Navigation vers édition profil
              },
            ),
            if (SupabaseService.currentUserRole == UserRole.admin) ...[
              Divider(
              color: AppTheme.colors.border,
              thickness: 0.5,
            ),
              ListTile(
                leading: Icon(Icons.admin_panel_settings, color: AppTheme.colors.error),
                title: const Text('Gestion des rôles'),
                subtitle: const Text('Administration'),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context, rootNavigator: true).pushNamed('/admin/roles');
                },
              ),
            ],
          ],
        ),
      );
    }
  }

  Widget _buildLogoutSection({required bool isIOS}) {
    if (isIOS) {
      return IOSListSection(
        children: [
          IOSListTile(
            leading: const Icon(CupertinoIcons.square_arrow_right, color: IOSTheme.systemRed),
            title: Text(
              'Déconnexion',
              style: IOSTheme.body.copyWith(color: IOSTheme.systemRed),
            ),
            onTap: _handleLogout,
          ),
        ],
      );
    } else {
      return Card(
        child: ListTile(
          leading: Icon(Icons.logout, color: AppTheme.colors.error),
          title: Text(
            'Déconnexion',
            style: TextStyle(color: AppTheme.colors.error),
          ),
          onTap: _handleLogout,
        ),
      );
    }
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
}

