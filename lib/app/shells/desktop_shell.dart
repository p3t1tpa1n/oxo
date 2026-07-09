// ============================================================================
// DESKTOP SHELL - OXO TIME SHEETS
// Shell pour macOS/Web desktop avec sidebar + topbar
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../config/app_icons.dart';
import '../../services/notification_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/side_menu.dart';

class DesktopShell extends StatefulWidget {
  final Widget child;
  final String currentRoute;
  
  const DesktopShell({
    Key? key,
    required this.child,
    required this.currentRoute,
  }) : super(key: key);

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadNotificationsCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      debugPrint('Erreur comptage notifications: $e');
    }
  }

  Future<void> _showNotifications(BuildContext anchorContext) async {
    List<Map<String, dynamic>> notifications;
    try {
      notifications = await NotificationService.getUserNotifications();
    } catch (e) {
      debugPrint('Erreur chargement notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de charger les notifications')),
        );
      }
      return;
    }
    if (!mounted) return;

    final renderBox = anchorContext.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);

    await showMenu<void>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx - 280,
        offset.dy + renderBox.size.height,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      constraints: const BoxConstraints(maxWidth: 360, maxHeight: 420),
      items: notifications.isEmpty
          ? [
              const PopupMenuItem<void>(
                enabled: false,
                child: Text('Aucune notification'),
              ),
            ]
          : notifications.take(15).map((notif) {
              final isRead = notif['is_read'] == true || notif['read'] == true;
              final createdAt = DateTime.tryParse(notif['created_at'] ?? '');
              return PopupMenuItem<void>(
                onTap: () {
                  final id = notif['id']?.toString();
                  if (id != null && !isRead) {
                    NotificationService.markNotificationAsRead(id)
                        .then((_) => _refreshUnreadCount());
                  }
                },
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    isRead
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: isRead ? AppTheme.colors.textSecondary : AppTheme.colors.primary,
                  ),
                  title: Text(
                    notif['title']?.toString() ?? 'Notification',
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    [
                      if ((notif['message'] ?? notif['body']) != null)
                        (notif['message'] ?? notif['body']).toString(),
                      if (createdAt != null)
                        DateFormat('dd/MM/yyyy HH:mm').format(createdAt),
                    ].join('\n'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: Row(
        children: [
          // Sidebar gauche (réutilise le SideMenu existant)
          SideMenu(
            userRole: SupabaseService.currentUserRole,
            selectedRoute: widget.currentRoute,
          ),
          
          // Contenu principal
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppTheme.colors.border,
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Retour + titre de page
          Row(
            children: [
              if (Navigator.of(context).canPop()) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Retour',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                SizedBox(width: AppTheme.spacing.sm),
              ],
              Text(
                _getPageTitle(),
                style: AppTheme.typography.h3,
              ),
            ],
          ),
          
          // Actions rapides
          Row(
            children: [
              Builder(
                builder: (buttonContext) => Badge(
                  isLabelVisible: _unreadCount > 0,
                  label: Text('$_unreadCount'),
                  child: IconButton(
                    icon: Icon(AppIcons.notifications),
                    tooltip: 'Notifications',
                    onPressed: () => _showNotifications(buttonContext),
                  ),
                ),
              ),
              SizedBox(width: AppTheme.spacing.sm),
              IconButton(
                icon: Icon(AppIcons.settings),
                tooltip: 'Paramètres',
                onPressed: () {
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPageTitle() {
    // Logique pour déterminer le titre de la page selon la route
    if (widget.currentRoute.contains('/dashboard')) return 'Dashboard';
    if (widget.currentRoute.contains('/missions')) return 'Missions';
    if (widget.currentRoute.contains('/timesheet')) return 'Timesheet';
    if (widget.currentRoute.contains('/partners')) return 'Partenaires';
    if (widget.currentRoute.contains('/actions')) return 'Actions commerciales';
    if (widget.currentRoute.contains('/messaging')) return 'Messages';
    if (widget.currentRoute.contains('/profile')) return 'Profil';
    if (widget.currentRoute.contains('/availability')) return 'Disponibilités';
    if (widget.currentRoute.contains('/admin')) return 'Administration';
    return 'OXO Time Sheets';
  }
}

