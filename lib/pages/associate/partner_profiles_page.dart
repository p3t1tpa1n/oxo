import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import 'partner_detail_page.dart';

class PartnerProfilesPage extends StatefulWidget {
  final bool embedded;
  
  const PartnerProfilesPage({super.key, this.embedded = false});

  @override
  State<PartnerProfilesPage> createState() => _PartnerProfilesPageState();
}

class _PartnerProfilesPageState extends State<PartnerProfilesPage> {
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
    final content = Column(
      children: [
        // Barre de recherche et filtres
        _buildSearchAndFilters(),
        
        // Liste des partenaires
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredPartners.isEmpty
                  ? _buildEmptyState()
                  : _buildPartnersList(),
        ),
      ],
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profils Partenaires'),
        backgroundColor: const Color(0xFF1E3D54),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPartners,
          ),
        ],
      ),
      body: content,
      floatingActionButton: FloatingActionButton(
        heroTag: 'partner_profiles_fab',
        onPressed: () {
          // Action pour ajouter un nouveau partenaire
        },
        backgroundColor: const Color(0xFF1E3D54),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: const InputDecoration(
              hintText: 'Rechercher un partenaire...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
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
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                      _filterPartners();
                    },
                    selectedColor: const Color(0xFF1E3D54).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF1E3D54),
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
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun partenaire trouvé',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les partenaires apparaîtront ici une fois qu\'ils auront complété leur profil.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartnerDetailPage(partner: partner),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et entreprise
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: const Color(0xFF1E3D54).withOpacity(0.1),
                    child: Text(
                      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}',
                      style: const TextStyle(
                        color: Color(0xFF1E3D54),
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
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
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (companyName.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            companyName,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
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
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: partner['questionnaire_completed'] == true 
                            ? Colors.green
                            : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      partner['questionnaire_completed'] == true ? 'Complet' : 'Incomplet',
                      style: TextStyle(
                        color: partner['questionnaire_completed'] == true 
                            ? Colors.green[700]
                            : Colors.orange[700],
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
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
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PartnerDetailPage(partner: partner),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Voir profil'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _assignMission(partner),
                    icon: const Icon(Icons.assignment, size: 16),
                    label: const Text('Proposer mission'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3D54),
                      foregroundColor: Colors.white,
                    ),
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
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
                color: const Color(0xFF1E3D54).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF1E3D54).withOpacity(0.3),
                ),
              ),
              child: Text(
                tag.toString(),
                style: const TextStyle(
                  color: Color(0xFF1E3D54),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _assignMission(Map<String, dynamic> partner) async {
    // Charger les missions non assignées
    List<Map<String, dynamic>> unassignedMissions = [];
    String? selectedMissionId;
    
    try {
      final response = await SupabaseService.client
          .from('missions')
          .select('*')
          .eq('progress_status', 'à_assigner')
          .order('created_at', ascending: false);
      
      unassignedMissions = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur chargement missions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (unassignedMissions.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune mission à proposer disponible'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Proposer une mission à ${partner['first_name']} ${partner['last_name']}'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sélectionnez une mission à proposer:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedMissionId,
                  decoration: const InputDecoration(
                    labelText: 'Mission',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.assignment),
                  ),
                  items: unassignedMissions.map((mission) {
                    return DropdownMenuItem(
                      value: mission['id']?.toString(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mission['title']?.toString() ?? 'Sans titre',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (mission['description'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              mission['description'].toString(),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedMissionId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  '${unassignedMissions.length} mission(s) disponible(s)',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: selectedMissionId == null
                  ? null
                  : () async {
                      try {
                        final currentUserId = SupabaseService.client.auth.currentUser?.id;
                        if (currentUserId == null) {
                          throw Exception('Utilisateur non connecté');
                        }

                        // Créer une proposition de mission
                        final proposalData = {
                          'mission_id': selectedMissionId,
                          'partner_id': partner['user_id'],
                          'associate_id': currentUserId,
                          'status': 'pending',
                        };

                        final success = await SupabaseService.createMissionProposal(proposalData);

                        if (success && context.mounted) {
                          Navigator.pop(context);
                          _showSuccessMessage('Mission proposée avec succès');
                        } else if (context.mounted) {
                          throw Exception('Erreur lors de la création de la proposition');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3D54),
                foregroundColor: Colors.white,
              ),
              child: const Text('Proposer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
