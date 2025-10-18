import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/ios_widgets.dart';
import '../../config/ios_theme.dart';
import 'ios_partner_detail_page.dart';

class IOSPartnerProfilesPage extends StatefulWidget {
  const IOSPartnerProfilesPage({super.key});

  @override
  State<IOSPartnerProfilesPage> createState() => _IOSPartnerProfilesPageState();
}

class _IOSPartnerProfilesPageState extends State<IOSPartnerProfilesPage> {
  List<Map<String, dynamic>> _partners = [];
  List<Map<String, dynamic>> _filteredPartners = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'Tous';
  
  final List<String> _filterOptions = [
    'Tous',
    'Disponibles',
    'Par domaine',
    'Par expérience'
  ];

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final partners = await SupabaseService.getAllPartnerProfiles();
      setState(() {
        _partners = partners;
        _filteredPartners = partners;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des partenaires: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterPartners() {
    setState(() {
      _filteredPartners = _partners.where((partner) {
        // Filtre par recherche
        if (_searchQuery.isNotEmpty) {
          final name = '${partner['first_name'] ?? ''} ${partner['last_name'] ?? ''}'.toLowerCase();
          final company = partner['company_name']?.toString().toLowerCase() ?? '';
          final searchLower = _searchQuery.toLowerCase();
          
          if (!name.contains(searchLower) && !company.contains(searchLower)) {
            return false;
          }
        }

        // Filtre par type
        switch (_selectedFilter) {
          case 'Disponibles':
            // Logique pour vérifier la disponibilité (à implémenter)
            return true;
          case 'Par domaine':
            // Logique pour filtrer par domaine d'activité
            return partner['activity_domains'] != null && 
                   (partner['activity_domains'] as List).isNotEmpty;
          case 'Par expérience':
            // Logique pour filtrer par expérience
            return partner['professional_experiences'] != null && 
                   (partner['professional_experiences'] as List).isNotEmpty;
          default:
            return true;
        }
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          'Profils Partenaires',
          style: IOSTheme.title2,
        ),
        backgroundColor: CupertinoColors.systemBackground,
        border: null,
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.refresh),
          onPressed: _loadPartners,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Barre de recherche et filtres
            _buildSearchAndFilters(),
            
            // Liste des partenaires
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : _filteredPartners.isEmpty
                      ? _buildEmptyState()
                      : _buildPartnersList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Barre de recherche
          IOSTextField(
            placeholder: 'Rechercher un partenaire...',
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              _filterPartners();
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filtres
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: isSelected ? IOSTheme.primaryBlue : CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(20),
                    child: Text(
                      filter,
                      style: IOSTheme.caption1.copyWith(
                        color: isSelected ? Colors.white : CupertinoColors.label,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      _filterPartners();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.person_2,
            size: 64,
            color: CupertinoColors.systemGrey3,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun partenaire trouvé',
            style: IOSTheme.title3.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les partenaires apparaîtront ici une fois qu\'ils auront complété leur profil.',
            style: IOSTheme.body.copyWith(
              color: CupertinoColors.systemGrey2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredPartners.length,
      itemBuilder: (context, index) {
        final partner = _filteredPartners[index];
        return _buildPartnerCard(partner);
      },
    );
  }

  Widget _buildPartnerCard(Map<String, dynamic> partner) {
    final firstName = partner['first_name'] ?? '';
    final lastName = partner['last_name'] ?? '';
    final companyName = partner['company_name'] ?? '';
    final activityDomains = partner['activity_domains'] as List<dynamic>? ?? [];
    final professionalExperiences = partner['professional_experiences'] as List<dynamic>? ?? [];
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: IOSCard(
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => IOSPartnerDetailPage(partner: partner),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et entreprise
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: IOSTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Center(
                      child: Text(
                        '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                        style: IOSTheme.title3.copyWith(
                          color: IOSTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Informations principales
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$firstName $lastName',
                          style: IOSTheme.title3.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (companyName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            companyName,
                            style: IOSTheme.body.copyWith(
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Indicateur de complétion
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: partner['questionnaire_completed'] == true 
                          ? CupertinoColors.systemGreen.withOpacity(0.1)
                          : CupertinoColors.systemOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      partner['questionnaire_completed'] == true ? 'Complet' : 'Incomplet',
                      style: IOSTheme.caption1.copyWith(
                        color: partner['questionnaire_completed'] == true 
                            ? CupertinoColors.systemGreen
                            : CupertinoColors.systemOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Domaines d'activité
              if (activityDomains.isNotEmpty) ...[
                _buildTagsSection('Domaines', activityDomains.take(3).toList()),
                const SizedBox(height: 8),
              ],
              
              // Expériences professionnelles
              if (professionalExperiences.isNotEmpty) ...[
                _buildTagsSection('Expériences', professionalExperiences.take(3).toList()),
                const SizedBox(height: 8),
              ],
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IOSSecondaryButton(
                    text: 'Voir profil',
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => IOSPartnerDetailPage(partner: partner),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  IOSPrimaryButton(
                    text: 'Assigner mission',
                    onPressed: () {
                      // TODO: Implémenter l'assignation de mission
                      _showMissionAssignmentDialog(partner);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagsSection(String title, List<dynamic> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: IOSTheme.caption1.copyWith(
            fontWeight: FontWeight.w600,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: tags.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                tag.toString(),
                style: IOSTheme.caption1.copyWith(
                  color: CupertinoColors.label,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showMissionAssignmentDialog(Map<String, dynamic> partner) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Assigner une mission'),
        content: Text('Assigner une mission à ${partner['first_name']} ${partner['last_name']} ?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Assigner'),
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implémenter la logique d'assignation
              _showSuccessMessage('Mission assignée avec succès');
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Succès'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}