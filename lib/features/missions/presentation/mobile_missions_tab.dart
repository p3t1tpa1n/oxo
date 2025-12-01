// ============================================================================
// MOBILE MISSIONS TAB - OXO TIME SHEETS
// Liste Missions iOS selon design spécifié
// Utilise STRICTEMENT AppTheme
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../services/supabase_service.dart';
import '../../../models/user_role.dart';
import '../../../utils/device_detector.dart';

class MobileMissionsTab extends StatefulWidget {
  const MobileMissionsTab({Key? key}) : super(key: key);

  @override
  State<MobileMissionsTab> createState() => _MobileMissionsTabState();
}

class _MobileMissionsTabState extends State<MobileMissionsTab> {
  List<Map<String, dynamic>> _missions = [];
  List<Map<String, dynamic>> _filteredMissions = [];
  List<Map<String, dynamic>> _companies = [];
  bool _isLoading = true;
  String _selectedFilter = 'en_cours'; // "En cours" sélectionné par défaut
  String _searchQuery = '';
  int _unreadCount = 0;
  UserRole? _userRole;

  final TextEditingController _searchController = TextEditingController();
  
  // Permissions selon les rôles - seuls admin et associé peuvent créer des missions
  bool get _canCreateMission => _userRole == UserRole.admin || _userRole == UserRole.associe;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadMissions();
    _loadUnreadCount();
    _loadCompanies();
    _searchController.addListener(_onSearchChanged);
  }

  Future<void> _loadUserRole() async {
    final role = await SupabaseService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  Future<void> _loadCompanies() async {
    try {
      final companies = await SupabaseService.getAllCompanies();
      if (mounted) {
        setState(() {
          _companies = companies;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement companies: $e');
    }
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

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    
    try {
      final currentUserId = SupabaseService.currentUser?.id;
      final userRole = _userRole ?? await SupabaseService.getCurrentUserRole();
      
      debugPrint('📱 MobileMissionsTab: Chargement missions pour rôle=$userRole, userId=$currentUserId');
      
      List<Map<String, dynamic>> missions;
      
      if (userRole == UserRole.partenaire) {
        // Pour les partenaires: uniquement leurs missions assignées
        missions = await _loadPartnerMissions(currentUserId);
      } else if (userRole == UserRole.client) {
        // Pour les clients: uniquement les missions de leur entreprise
        missions = await _loadClientMissions();
      } else {
        // Pour admin/associé: toutes les missions
        final allMissions = await SupabaseService.getCompanyMissions();
        missions = allMissions;
      }
      
      debugPrint('📱 MobileMissionsTab: ${missions.length} missions chargées');
      
      setState(() {
        _missions = missions;
        _userRole = userRole;
        _isLoading = false;
      });
      
      _applyFilters();
    } catch (e) {
      debugPrint('❌ Erreur chargement missions: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Charge les missions assignées à un partenaire
  Future<List<Map<String, dynamic>>> _loadPartnerMissions(String? partnerId) async {
    if (partnerId == null) {
      debugPrint('❌ _loadPartnerMissions: partnerId est null');
      return [];
    }
    
    debugPrint('🔍 _loadPartnerMissions: Recherche pour $partnerId');
    
    List<Map<String, dynamic>> allMissions = [];
    
    // Méthode 1: Chercher par assigned_to
    try {
      final response1 = await SupabaseService.client
          .from('missions')
          .select()
          .eq('assigned_to', partnerId);
      
      debugPrint('📱 Méthode 1 (assigned_to): ${response1.length} missions');
      allMissions.addAll(List<Map<String, dynamic>>.from(response1));
    } catch (e) {
      debugPrint('⚠️ Erreur méthode 1: $e');
    }
    
    // Méthode 2: Chercher par partner_id
    try {
      final response2 = await SupabaseService.client
          .from('missions')
          .select()
          .eq('partner_id', partnerId);
      
      debugPrint('📱 Méthode 2 (partner_id): ${response2.length} missions');
      
      // Ajouter seulement les missions pas déjà présentes
      for (final mission in response2) {
        final exists = allMissions.any((m) => m['id'] == mission['id']);
        if (!exists) {
          allMissions.add(Map<String, dynamic>.from(mission));
        }
      }
    } catch (e) {
      debugPrint('⚠️ Erreur méthode 2: $e');
    }
    
    // Si toujours rien, fallback sur toutes les missions et filtrer
    if (allMissions.isEmpty) {
      debugPrint('🔄 Fallback: récupération de toutes les missions et filtrage');
      try {
        final allResponse = await SupabaseService.client
            .from('missions')
            .select()
            .order('created_at', ascending: false);
        
        allMissions = (allResponse as List).where((m) {
          final assignedTo = m['assigned_to']?.toString();
          final missionPartnerId = m['partner_id']?.toString();
          return assignedTo == partnerId || missionPartnerId == partnerId;
        }).map((m) => Map<String, dynamic>.from(m)).toList();
        
        debugPrint('📱 Fallback: ${allMissions.length} missions après filtrage');
      } catch (e) {
        debugPrint('❌ Erreur fallback: $e');
      }
    }
    
    debugPrint('✅ Total missions partenaire: ${allMissions.length}');
    for (final m in allMissions) {
      debugPrint('  - ${m['title']} (ID: ${m['id']}, assigned_to: ${m['assigned_to']}, partner_id: ${m['partner_id']})');
    }
    
    return allMissions;
  }

  /// Charge les missions pour un client (de son entreprise)
  Future<List<Map<String, dynamic>>> _loadClientMissions() async {
    try {
      final userCompany = await SupabaseService.getUserCompany();
      if (userCompany == null) return [];
      
      final companyId = userCompany['company_id'];
      
      final response = await SupabaseService.client
          .from('missions')
          .select()
          .eq('company_id', companyId)
          .order('start_date', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur chargement missions client: $e');
      return [];
    }
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

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_missions);

    // Filtre par statut
    if (_selectedFilter != 'tous') {
      filtered = filtered.where((m) {
        final status = m['progress_status'] ?? m['status'] ?? '';
        if (_selectedFilter == 'en_cours') {
          return status == 'en_cours' || status == 'in_progress';
        } else if (_selectedFilter == 'à_venir') {
          final startDate = m['start_date'];
          if (startDate != null) {
            try {
              final date = startDate is String ? DateTime.parse(startDate) : startDate as DateTime;
              return date.isAfter(DateTime.now());
            } catch (e) {
              return false;
            }
          }
          return false;
        }
        return status == _selectedFilter;
      }).toList();
    }

    // Filtre par recherche
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        final title = (m['title'] ?? '').toString().toLowerCase();
        final description = (m['description'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery) || description.contains(_searchQuery);
      }).toList();
    }

    setState(() {
      _filteredMissions = filtered;
    });
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
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  // Header personnalisé
                  _buildHeader(),
                  
                  // Barre de recherche
                  _buildSearchBar(),
                  
                  // Boutons de filtre
                  _buildFilterButtons(),
                  
                  // Liste des missions
                  Expanded(
                  child: _isLoading
                    ? Center(
                        child: CupertinoActivityIndicator(
                          color: AppTheme.colors.primary,
                        ),
                      )
                    : _filteredMissions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getIconForPlatform(AppIcons.missions, AppIcons.missionsIOS),
                                size: 48,
                                color: AppTheme.colors.textSecondary,
                              ),
                              SizedBox(height: AppTheme.spacing.md),
                              Text(
                                _searchQuery.isNotEmpty 
                                  ? 'Aucune mission trouvée'
                                  : 'Aucune mission',
                                style: AppTheme.typography.h4.copyWith(
                                  color: AppTheme.colors.textSecondary,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMissions,
                          color: AppTheme.colors.primary,
                          child: ListView.builder(
                            padding: EdgeInsets.only(
                              left: AppTheme.spacing.md,
                              right: AppTheme.spacing.md,
                              top: AppTheme.spacing.md,
                              bottom: 80, // Espace pour le FAB
                            ),
                            itemCount: _filteredMissions.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: EdgeInsets.only(bottom: AppTheme.spacing.sm),
                                child: _buildMissionCard(_filteredMissions[index]),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
            // FAB positionné en bas à droite - visible uniquement pour les admins/associés
            if (_canCreateMission)
              Positioned(
                right: AppTheme.spacing.md,
                bottom: AppTheme.spacing.md + 60, // Au-dessus de la barre de navigation
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _showCreateMissionDialog,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.colors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.colors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getIconForPlatform(AppIcons.add, AppIcons.addIOS),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String get _headerTitle {
    if (_userRole == UserRole.partenaire) {
      return 'Mes Missions';
    } else if (_userRole == UserRole.client) {
      return 'Mes Projets';
    }
    return 'Missions';
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
          // Titre adapté selon le rôle
          Text(
            _headerTitle,
            style: AppTheme.typography.h1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.colors.textPrimary,
              decoration: TextDecoration.none,
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

  Widget _buildSearchBar() {
    return Container(
      margin: EdgeInsets.all(AppTheme.spacing.md),
      child: CupertinoSearchTextField(
        controller: _searchController,
        placeholder: 'Rechercher une mission...',
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
        ),
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      height: 40,
      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md),
        children: [
          _buildFilterButton('Tous', 'tous'),
          SizedBox(width: AppTheme.spacing.sm),
          _buildFilterButton('En cours', 'en_cours'),
          SizedBox(width: AppTheme.spacing.sm),
          _buildFilterButton('À venir', 'à_venir'),
          SizedBox(width: AppTheme.spacing.sm),
          _buildSortButton(),
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
        _applyFilters();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.md,
          vertical: AppTheme.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected 
            ? AppTheme.colors.inputBackground 
            : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radius.small),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.typography.bodyMedium.copyWith(
              color: isSelected 
                ? AppTheme.colors.textPrimary 
                : AppTheme.colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return GestureDetector(
      onTap: () {
        _showSortDialog();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.md,
          vertical: AppTheme.spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Trier',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textSecondary,
                decoration: TextDecoration.none,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              _getIconForPlatform(AppIcons.next, AppIcons.nextIOS),
              size: 14,
              color: AppTheme.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(Map<String, dynamic> mission) {
    final status = mission['progress_status'] ?? mission['status'] ?? 'pending';
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);
    final priority = mission['priority'] ?? 'medium';
    final priorityLabel = _getPriorityLabel(priority);
    
    // Format de date
    String dateStr = '';
    try {
      final startDate = mission['start_date'];
      if (startDate != null) {
        final date = startDate is String ? DateTime.parse(startDate) : startDate as DateTime;
        dateStr = DateFormat('dd/MM/yyyy').format(date);
      }
    } catch (e) {
      debugPrint('Erreur format date: $e');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context, rootNavigator: true).pushNamed(
              '/mission_detail',
              arguments: mission['id'],
            );
          },
          borderRadius: BorderRadius.circular(AppTheme.radius.medium),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre et tag statut
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre en gras
                          Text(
                            mission['title'] ?? 'Mission sans titre',
                            style: AppTheme.typography.h4.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.colors.textPrimary,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          // Description
                          if (mission['description'] != null)
                            Text(
                              mission['description'],
                              style: AppTheme.typography.bodySmall.copyWith(
                                color: AppTheme.colors.textSecondary,
                                decoration: TextDecoration.none,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.sm),
                    // Tag statut (fond bleu clair, texte blanc)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppTheme.spacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(AppTheme.radius.small),
                      ),
                      child: Text(
                        statusLabel,
                        style: AppTheme.typography.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacing.sm),
                // Date et priorité
                Row(
                  children: [
                    // Date avec icône calendrier
                    if (dateStr.isNotEmpty) ...[
                      Icon(
                        _getIconForPlatform(AppIcons.planning, AppIcons.planningIOS),
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
                    Spacer(),
                    // Priorité
                    Text(
                      priorityLabel.toUpperCase(),
                      style: AppTheme.typography.caption.copyWith(
                        color: AppTheme.colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.none,
                      ),
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

  void _showSortDialog() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Trier par'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _filteredMissions.sort((a, b) {
                  final dateA = a['start_date'];
                  final dateB = b['start_date'];
                  if (dateA == null || dateB == null) return 0;
                  try {
                    final dA = dateA is String ? DateTime.parse(dateA) : dateA as DateTime;
                    final dB = dateB is String ? DateTime.parse(dateB) : dateB as DateTime;
                    return dB.compareTo(dA); // Plus récent en premier
                  } catch (e) {
                    return 0;
                  }
                });
              });
              Navigator.pop(context);
            },
            child: Text('Date (plus récent)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _filteredMissions.sort((a, b) {
                  final titleA = (a['title'] ?? '').toString().toLowerCase();
                  final titleB = (b['title'] ?? '').toString().toLowerCase();
                  return titleA.compareTo(titleB);
                });
              });
              Navigator.pop(context);
            },
            child: Text('Titre (A-Z)'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en_cours':
      case 'in_progress':
        return Color(0xFF4A90E2); // Bleu clair comme dans l'image
      case 'fait':
      case 'done':
      case 'completed':
        return AppTheme.colors.success;
      case 'à_assigner':
      case 'pending':
        return AppTheme.colors.info;
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
        return 'À assigner';
      default:
        return status.toUpperCase();
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return 'Urgent';
      case 'high':
        return 'Haute';
      case 'medium':
        return 'Moyenne';
      case 'low':
        return 'Basse';
      default:
        return priority;
    }
  }

  IconData _getIconForPlatform(IconData material, IconData cupertino) {
    return DeviceDetector.shouldUseIOSInterface() ? cupertino : material;
  }

  void _showCreateMissionDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    Map<String, dynamic>? selectedCompany;
    DateTime? startDate;
    String priority = 'medium';

    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey3,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                        const Text(
                          'Nouvelle mission',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Créer',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: CupertinoColors.systemBlue,
                            ),
                          ),
                          onPressed: () async {
                            if (titleController.text.isEmpty) {
                              _showMessage('Le titre est requis', isError: true);
                              return;
                            }
                            if (selectedCompany == null) {
                              _showMessage('Veuillez sélectionner un client', isError: true);
                              return;
                            }
                            
                            try {
                              await SupabaseService.createMission({
                                'title': titleController.text,
                                'description': descriptionController.text,
                                'company_id': selectedCompany!['id'],
                                'start_date': startDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
                                'priority': priority,
                                'status': 'pending',
                                'progress_status': 'à_assigner',
                              });
                              
                              Navigator.pop(dialogContext);
                              _showMessage('Mission créée avec succès');
                              _loadMissions();
                            } catch (e) {
                              _showMessage('Erreur: $e', isError: true);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Titre
                          Text(
                            'Titre',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            controller: titleController,
                            placeholder: 'Nom de la mission',
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: CupertinoColors.systemGrey4),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Client
                          Text(
                            'Client',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showCompanyPickerForMission(dialogContext, (company) {
                              setDialogState(() => selectedCompany = company);
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: CupertinoColors.systemGrey4),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedCompany?['name'] ?? 'Sélectionner un client',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: selectedCompany != null 
                                          ? CupertinoColors.label 
                                          : CupertinoColors.tertiaryLabel,
                                      ),
                                    ),
                                  ),
                                  const Icon(CupertinoIcons.chevron_down, size: 16, color: CupertinoColors.secondaryLabel),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Description
                          Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            controller: descriptionController,
                            placeholder: 'Description de la mission (optionnel)',
                            maxLines: 3,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: CupertinoColors.systemGrey4),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Date de début
                          Text(
                            'Date de début',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              await showCupertinoModalPopup(
                                context: dialogContext,
                                builder: (context) => Container(
                                  height: 250,
                                  color: CupertinoColors.systemBackground,
                                  child: CupertinoDatePicker(
                                    initialDateTime: startDate ?? DateTime.now(),
                                    mode: CupertinoDatePickerMode.date,
                                    onDateTimeChanged: (date) {
                                      setDialogState(() => startDate = date);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: CupertinoColors.systemGrey4),
                              ),
                              child: Row(
                                children: [
                                  Icon(CupertinoIcons.calendar, size: 18, color: CupertinoColors.secondaryLabel),
                                  const SizedBox(width: 10),
                                  Text(
                                    startDate != null 
                                      ? DateFormat('dd/MM/yyyy').format(startDate!)
                                      : 'Sélectionner une date',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: startDate != null 
                                        ? CupertinoColors.label 
                                        : CupertinoColors.tertiaryLabel,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Priorité
                          Text(
                            'Priorité',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildPriorityButton('low', 'Basse', priority, (p) => setDialogState(() => priority = p)),
                              const SizedBox(width: 8),
                              _buildPriorityButton('medium', 'Moyenne', priority, (p) => setDialogState(() => priority = p)),
                              const SizedBox(width: 8),
                              _buildPriorityButton('high', 'Haute', priority, (p) => setDialogState(() => priority = p)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityButton(String value, String label, String currentValue, Function(String) onSelect) {
    final isSelected = currentValue == value;
    Color color;
    switch (value) {
      case 'high':
        color = CupertinoColors.systemRed;
        break;
      case 'medium':
        color = CupertinoColors.systemOrange;
        break;
      default:
        color = CupertinoColors.systemGreen;
    }
    
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : CupertinoColors.systemGrey6,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : CupertinoColors.systemGrey4,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? CupertinoColors.white : CupertinoColors.label,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCompanyPickerForMission(BuildContext parentContext, Function(Map<String, dynamic>) onSelect) {
    showCupertinoModalPopup(
      context: parentContext,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.5,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Sélectionner un client',
                    style: TextStyle(
                      fontSize: 17, 
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _companies.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun client disponible',
                          style: TextStyle(color: CupertinoColors.secondaryLabel),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _companies.length,
                        itemBuilder: (context, index) {
                          final company = _companies[index];
                          return GestureDetector(
                            onTap: () {
                              onSelect(company);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: const BoxDecoration(
                                border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
                              ),
                              child: Text(
                                company['name'] ?? 'Client',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.label,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? CupertinoColors.systemRed : CupertinoColors.systemGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}
