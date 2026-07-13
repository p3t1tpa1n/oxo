// ============================================================================
// MOBILE PARTNERS TAB - OXO TIME SHEETS
// Liste Partenaires/Clients iOS professionnelle et compacte
// Utilise STRICTEMENT AppTheme
// ============================================================================

import 'package:flutter/material.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../services/supabase_service.dart';
import '../../../services/notification_service.dart';
import '../../../models/user_role.dart';
import '../../../widgets/oxo_card.dart';
import '../../../pages/associate/ios_partner_detail_page.dart';

class MobilePartnersTab extends StatefulWidget {
  const MobilePartnersTab({Key? key}) : super(key: key);

  @override
  State<MobilePartnersTab> createState() => _MobilePartnersTabState();
}

class _MobilePartnersTabState extends State<MobilePartnersTab> {
  List<Map<String, dynamic>> _partners = [];
  List<Map<String, dynamic>> _filteredPartners = [];
  bool _isLoading = true;
  String _searchQuery = '';
  int _unreadCount = 0;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPartners();
    _loadUnreadCount();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
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

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_partners);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((p) {
        final firstName = (p['first_name'] ?? '').toString().toLowerCase();
        final lastName = (p['last_name'] ?? '').toString().toLowerCase();
        final email = (p['email'] ?? '').toString().toLowerCase();
        return firstName.contains(_searchQuery) ||
               lastName.contains(_searchQuery) ||
               email.contains(_searchQuery);
      }).toList();
    }

    setState(() {
      _filteredPartners = filtered;
    });
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoading = true);

    try {
      final partners = await SupabaseService.getPartners();
      setState(() {
        _partners = partners;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = SupabaseService.currentUserRole;
    final title = userRole == UserRole.client ? 'Demandes' : 'Partenaires';

    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header personnalisé
            _buildHeader(title),

            // Barre de recherche
            _buildSearchBar(),

            // Liste des partenaires
            Expanded(
            child: _isLoading
              ? Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: AppTheme.colors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : _filteredPartners.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          AppIcons.partners,
                          size: 48,
                          color: AppTheme.colors.textSecondary,
                        ),
                        SizedBox(height: AppTheme.spacing.md),
                        Text(
                          _searchQuery.isNotEmpty
                            ? 'Aucun partenaire trouvé'
                            : 'Aucun partenaire',
                          style: AppTheme.typography.h4.copyWith(
                            color: AppTheme.colors.textSecondary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPartners,
                    color: AppTheme.colors.primary,
                    child: ListView.builder(
                      padding: EdgeInsets.all(AppTheme.spacing.md),
                      itemCount: _filteredPartners.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppTheme.spacing.sm),
                          child: _buildPartnerCard(_filteredPartners[index]),
                        );
                      },
                    ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.sm,
      ),
      color: AppTheme.colors.surface,
      child: Row(
        children: [
          // Titre en grand et gras
          Expanded(
            child: Text(
              title,
              style: AppTheme.typography.h1.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.colors.textPrimary,
                decoration: TextDecoration.none,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          // Icône cloche (notifications)
          GestureDetector(
            onTap: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/messaging');
            },
            child: Stack(
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
          GestureDetector(
            onTap: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/profile');
            },
            child: Icon(
              AppIcons.settings,
              color: AppTheme.colors.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(AppTheme.spacing.md),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un partenaire...',
          hintStyle: AppTheme.typography.bodyMedium.copyWith(
            color: AppTheme.colors.textSecondary,
            decoration: TextDecoration.none,
          ),
          prefixIcon: Icon(Icons.search),
          filled: true,
          fillColor: AppTheme.colors.inputBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radius.medium),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 8),
        ),
        style: AppTheme.typography.bodyMedium.copyWith(
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> partner) {
    final firstName = partner['first_name'] ?? '';
    final lastName = partner['last_name'] ?? '';
    final email = partner['email'] ?? '';
    final name = '$firstName $lastName'.trim();
    final displayName = name.isNotEmpty ? name : email.split('@').first;

    return OxoCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => IOSPartnerDetailPage(partner: partner),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.colors.primary,
            child: Text(
              displayName.substring(0, 1).toUpperCase(),
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textOnPrimary,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: AppTheme.typography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  email,
                  style: AppTheme.typography.bodySmall.copyWith(
                    color: AppTheme.colors.textSecondary,
                    decoration: TextDecoration.none,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            AppIcons.next,
            color: AppTheme.colors.textSecondary,
            size: 16,
          ),
        ],
      ),
    );
  }
}
