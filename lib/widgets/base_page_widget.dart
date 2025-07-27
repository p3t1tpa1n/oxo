import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/supabase_service.dart';
import 'top_bar.dart';
import 'side_menu.dart';
import 'messaging_button.dart';

/// Widget de base pour standardiser toutes les pages de l'application
/// Fournit une structure cohérente avec gestion d'états et actions uniformes
class BasePageWidget extends StatefulWidget {
  final String title;
  final Widget body;
  final String route;
  final List<Widget>? floatingActionButtons;
  final Widget? bottomNavigationBar;
  final bool showSideMenu;
  final bool showMessaging;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRefresh;
  final Widget? emptyStateWidget;
  final bool hasData;

  const BasePageWidget({
    super.key,
    required this.title,
    required this.body,
    required this.route,
    this.floatingActionButtons,
    this.bottomNavigationBar,
    this.showSideMenu = true,
    this.showMessaging = true,
    this.isLoading = false,
    this.errorMessage,
    this.onRefresh,
    this.emptyStateWidget,
    this.hasData = true,
  });

  @override
  State<BasePageWidget> createState() => _BasePageWidgetState();
}

class _BasePageWidgetState extends State<BasePageWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          if (widget.showSideMenu)
            SideMenu(
              userRole: SupabaseService.currentUserRole,
              selectedRoute: widget.route,
            ),
          Expanded(
            child: Column(
              children: [
                TopBar(title: widget.title),
                Expanded(
                  child: _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return _buildLoadingState();
    }

    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    if (!widget.hasData && widget.emptyStateWidget != null) {
      return widget.emptyStateWidget!;
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
      },
      child: widget.body,
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1784af)),
          ),
          SizedBox(height: 16),
          Text(
            'Chargement...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 20),
            Text(
              'Une erreur est survenue',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.errorMessage ?? 'Erreur inconnue',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1784af),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButtons() {
    final buttons = <Widget>[];
    
    if (widget.showMessaging) {
      buttons.add(const MessagingFloatingButton());
    }
    
    if (widget.floatingActionButtons != null) {
      buttons.addAll(widget.floatingActionButtons!);
    }
    
    if (buttons.isEmpty) return null;
    
    if (buttons.length == 1) return buttons.first;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: buttons
          .expand((button) => [button, const SizedBox(height: 16)])
          .take(buttons.length * 2 - 1)
          .toList(),
    );
  }
}

/// Widget d'état vide standardisé
class StandardEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const StandardEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1784af),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Extension pour simplifier l'utilisation
extension BasePageExtension on StatefulWidget {
  Widget withStandardLayout({
    required String title,
    required String route,
    List<Widget>? floatingActionButtons,
    Widget? bottomNavigationBar,
    bool showSideMenu = true,
    bool showMessaging = true,
    bool isLoading = false,
    String? errorMessage,
    VoidCallback? onRefresh,
    Widget? emptyStateWidget,
    bool hasData = true,
  }) {
    return BasePageWidget(
      title: title,
      body: this as Widget,
      route: route,
      floatingActionButtons: floatingActionButtons,
      bottomNavigationBar: bottomNavigationBar,
      showSideMenu: showSideMenu,
      showMessaging: showMessaging,
      isLoading: isLoading,
      errorMessage: errorMessage,
      onRefresh: onRefresh,
      emptyStateWidget: emptyStateWidget,
      hasData: hasData,
    );
  }
} 