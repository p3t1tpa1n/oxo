import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oxo/services/supabase_service.dart';
import '../../config/app_theme.dart';

class IOSMobileAdminClientsPage extends StatefulWidget {
  const IOSMobileAdminClientsPage({Key? key}) : super(key: key);

  @override
  State<IOSMobileAdminClientsPage> createState() => _IOSMobileAdminClientsPageState();
}

class _IOSMobileAdminClientsPageState extends State<IOSMobileAdminClientsPage> {
  int _selectedTab = 0; // 0 = Sociétés, 1 = Groupes
  List<Map<String, dynamic>> _companies = [];
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = true;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
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
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger les sociétés (companies)
      final companiesResponse = await SupabaseService.client
          .from('company')
          .select('*, investor_group:group_id(name)')
          .order('name', ascending: true);
      
      // Charger les groupes d'investisseurs
      final groupsResponse = await SupabaseService.client
          .from('investor_group')
          .select('*')
          .order('name', ascending: true);
      
      if (mounted) {
        setState(() {
          _companies = List<Map<String, dynamic>>.from(companiesResponse);
          _groups = List<Map<String, dynamic>>.from(groupsResponse);
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement sociétés/groupes: $e');
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
                  // Sous-onglets Sociétés / Groupes
                  _buildSubTabs(),
                  
                  // Barre de recherche
                  _buildSearchBar(),
                  
                  // Liste
                  Expanded(
                    child: _selectedTab == 0
                        ? _buildCompaniesList()
                        : _buildGroupsList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSubTabs() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.sm,
      ),
      child: Row(
        children: [
          _buildTabButton('Sociétés', 0),
          SizedBox(width: AppTheme.spacing.md),
          _buildTabButton('Groupes', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _searchController.clear();
        });
      },
      child: Text(
        label,
        style: AppTheme.typography.h3.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected 
              ? AppTheme.colors.textPrimary 
              : AppTheme.colors.textSecondary,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(AppTheme.spacing.md),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: _selectedTab == 0 
            ? 'Rechercher une société...' 
            : 'Rechercher un groupe...',
        style: AppTheme.typography.bodyMedium.copyWith(
          decoration: TextDecoration.none,
        ),
        placeholderStyle: AppTheme.typography.bodyMedium.copyWith(
          color: AppTheme.colors.textSecondary,
          decoration: TextDecoration.none,
        ),
        decoration: BoxDecoration(
          color: AppTheme.colors.inputBackground,
          borderRadius: BorderRadius.circular(AppTheme.radius.medium),
          border: Border.all(color: AppTheme.colors.border),
        ),
      ),
    );
  }

  Widget _buildCompaniesList() {
    final filteredCompanies = _companies.where((company) {
      final name = (company['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    if (filteredCompanies.isEmpty) {
      return _buildEmptyState(
        'Aucune société trouvée',
        'Les sociétés que vous ajoutez apparaîtront ici.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.colors.primary,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md),
        itemCount: filteredCompanies.length,
        itemBuilder: (context, index) {
          return _buildCompanyCard(filteredCompanies[index]);
        },
      ),
    );
  }

  Widget _buildCompanyCard(Map<String, dynamic> company) {
    final name = company['name'] ?? 'Société inconnue';
    final city = company['city'] ?? company['address'] ?? '';
    final status = company['status'] ?? 'active';
    final group = company['investor_group'];
    final groupName = group != null ? group['name'] : null;
    final detention = company['detention_percentage'];

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.colors.primary,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: AppTheme.typography.h4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacing.md),
          
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom
                Text(
                  name,
                  style: AppTheme.typography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.colors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
                
                // Groupe
                if (groupName != null) ...[
                  SizedBox(height: 2),
                  Text(
                    'Groupe: $groupName',
                    style: AppTheme.typography.bodySmall.copyWith(
                      color: AppTheme.colors.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ],
                
                // Ville
                if (city.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.location_solid,
                        size: 14,
                        color: AppTheme.colors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        city,
                        style: AppTheme.typography.bodySmall.copyWith(
                          color: AppTheme.colors.textSecondary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
                
                // Détention
                if (detention != null) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.building_2_fill,
                        size: 14,
                        color: AppTheme.colors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Détention: ${detention.toStringAsFixed(1)}%',
                        style: AppTheme.typography.bodySmall.copyWith(
                          color: AppTheme.colors.textSecondary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Statut et édition
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Badge Actif
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.spacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: status == 'active' 
                      ? const Color(0xFF34C759).withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status == 'active' ? 'Actif' : 'Inactif',
                  style: AppTheme.typography.caption.copyWith(
                    color: status == 'active' 
                        ? const Color(0xFF34C759) 
                        : Colors.grey,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
              SizedBox(height: AppTheme.spacing.xs),
              // Icône édition
              GestureDetector(
                onTap: () {
                  // TODO: Éditer la société
                },
                child: Icon(
                  CupertinoIcons.pencil,
                  size: 20,
                  color: AppTheme.colors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    final filteredGroups = _groups.where((group) {
      final name = (group['name'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    if (filteredGroups.isEmpty) {
      return _buildEmptyState(
        'Aucun groupe trouvé',
        'Les groupes d\'investisseurs apparaîtront ici.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.colors.primary,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md),
        itemCount: filteredGroups.length,
        itemBuilder: (context, index) {
          return _buildGroupCard(filteredGroups[index]);
        },
      ),
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group) {
    final name = group['name'] ?? 'Groupe inconnu';
    final description = group['description'] ?? '';

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.colors.secondary,
            child: Text(
              name.substring(0, 1).toUpperCase(),
              style: AppTheme.typography.h4.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          SizedBox(width: AppTheme.spacing.md),
          
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTheme.typography.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.colors.textPrimary,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: AppTheme.typography.bodySmall.copyWith(
                      color: AppTheme.colors.textSecondary,
                      decoration: TextDecoration.none,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          
          // Icône édition
          GestureDetector(
            onTap: () {
              // TODO: Éditer le groupe
            },
            child: Icon(
              CupertinoIcons.pencil,
              size: 20,
              color: AppTheme.colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.building_2_fill,
              size: 48,
              color: AppTheme.colors.textSecondary,
            ),
            SizedBox(height: AppTheme.spacing.md),
            Text(
              title,
              style: AppTheme.typography.h4.copyWith(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(height: AppTheme.spacing.xs),
            Text(
              subtitle,
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
}
