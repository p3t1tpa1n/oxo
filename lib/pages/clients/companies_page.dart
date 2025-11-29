// ============================================================================
// PAGE: Gestion des Sociétés et Groupes d'Investissement
// ============================================================================

import 'package:flutter/material.dart';
import '../../models/company.dart';
import '../../models/investor_group.dart';
import '../../services/supabase_service.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';

class CompaniesPage extends StatefulWidget {
  final bool embedded;
  
  const CompaniesPage({super.key, this.embedded = false});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<Company> _companies = [];
  List<Company> _filteredCompanies = [];
  List<InvestorGroup> _groups = [];
  List<InvestorGroup> _filteredGroups = [];
  
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les sociétés avec leurs groupes
      final companiesResponse = await SupabaseService.client
          .from('company_with_group')
          .select()
          .order('company_name');

      // Charger les groupes
      final groupsResponse = await SupabaseService.client
          .from('investor_group')
          .select()
          .order('name');

      setState(() {
        _companies = (companiesResponse as List)
            .map((json) => Company.fromJson(json))
            .toList();
        _groups = (groupsResponse as List)
            .map((json) => InvestorGroup.fromJson(json))
            .toList();
        _filteredCompanies = _companies;
        _filteredGroups = _groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters(String searchTerm) {
    if (_selectedTab == 0) {
      // Filtrer les sociétés
      if (searchTerm.isEmpty) {
        _filteredCompanies = _companies;
      } else {
        _filteredCompanies = _companies.where((company) {
          final name = company.name.toLowerCase();
          final group = (company.groupName ?? '').toLowerCase();
          final city = (company.city ?? '').toLowerCase();
          final term = searchTerm.toLowerCase();
          
          return name.contains(term) || group.contains(term) || city.contains(term);
        }).toList();
      }
    } else {
      // Filtrer les groupes
      if (searchTerm.isEmpty) {
        _filteredGroups = _groups;
      } else {
        _filteredGroups = _groups.where((group) {
          final name = group.name.toLowerCase();
          final sector = (group.sector ?? '').toLowerCase();
          final term = searchTerm.toLowerCase();
          
          return name.contains(term) || sector.contains(term);
        }).toList();
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return Stack(
        children: [
          _buildContent(),
          // FAB pour ajouter
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'companies_embedded_fab',
              onPressed: () {
                if (_selectedTab == 0) {
                  _showCompanyForm();
                } else {
                  _showGroupForm();
                }
              },
              backgroundColor: const Color(0xFF2A4B63),
              child: const Icon(Icons.add),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            userRole: SupabaseService.currentUserRole,
            selectedRoute: '/companies',
          ),
          Expanded(
            child: Column(
              children: [
                const TopBar(title: 'Sociétés et Groupes'),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'companies_standalone_fab',
        onPressed: () {
          if (_selectedTab == 0) {
            _showCompanyForm();
          } else {
            _showGroupForm();
          }
        },
        backgroundColor: const Color(0xFF2A4B63),
        tooltip: _selectedTab == 0 ? 'Ajouter une société' : 'Ajouter un groupe',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        // Tabs
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF2A4B63),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF2A4B63),
            tabs: const [
              Tab(text: 'Sociétés', icon: Icon(Icons.business)),
              Tab(text: 'Groupes d\'investissement', icon: Icon(Icons.account_balance)),
            ],
          ),
        ),

        // Barre de recherche
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: _selectedTab == 0 
                  ? 'Rechercher une société...' 
                  : 'Rechercher un groupe...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: _applyFilters,
          ),
        ),

        // Contenu des tabs
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCompaniesTab(),
                    _buildGroupsTab(),
                  ],
                ),
        ),
      ],
    );
  }

  // ============================================================================
  // ONGLET SOCIÉTÉS
  // ============================================================================

  Widget _buildCompaniesTab() {
    if (_filteredCompanies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text('Aucune société', style: TextStyle(fontSize: 20, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredCompanies.length,
      itemBuilder: (context, index) {
        final company = _filteredCompanies[index];
        return _buildCompanyCard(company);
      },
    );
  }

  Widget _buildCompanyCard(Company company) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2A4B63),
          child: Text(
            company.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          company.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (company.groupName != null)
              Text('Groupe: ${company.groupName}', style: const TextStyle(fontSize: 12)),
            if (company.city != null)
              Text('📍 ${company.city}', style: const TextStyle(fontSize: 12)),
            if (company.sector != null)
              Text('🏷️ ${company.sector}', style: const TextStyle(fontSize: 12)),
            if (company.ownershipShare != null)
              Text('💼 Détention: ${company.ownershipShare!.toStringAsFixed(1)}%', 
                   style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: company.active ? Colors.green[50] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                company.active ? 'Actif' : 'Inactif',
                style: TextStyle(
                  color: company.active ? Colors.green : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showCompanyForm(company: company),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteCompany(company),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // ONGLET GROUPES
  // ============================================================================

  Widget _buildGroupsTab() {
    if (_filteredGroups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text('Aucun groupe', style: TextStyle(fontSize: 20, color: Colors.grey[600])),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredGroups.length,
      itemBuilder: (context, index) {
        final group = _filteredGroups[index];
        return _buildGroupCard(group);
      },
    );
  }

  Widget _buildGroupCard(InvestorGroup group) {
    // Compter les sociétés du groupe
    final companiesCount = _companies.where((c) => c.groupId == group.id).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2A4B63),
          child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
        ),
        title: Text(
          group.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (group.sector != null)
              Text('🏷️ ${group.sector}', style: const TextStyle(fontSize: 12)),
            if (group.country != null)
              Text('🌍 ${group.country}', style: const TextStyle(fontSize: 12)),
            Text('🏢 $companiesCount société(s)', style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: group.active ? Colors.green[50] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                group.active ? 'Actif' : 'Inactif',
                style: TextStyle(
                  color: group.active ? Colors.green : Colors.grey,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showGroupForm(group: group),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteGroup(group),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // FORMULAIRES
  // ============================================================================

  void _showCompanyForm({Company? company}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: company?.name ?? '');
    final cityController = TextEditingController(text: company?.city ?? '');
    final sectorController = TextEditingController(text: company?.sector ?? '');
    final ownershipController = TextEditingController(
      text: company?.ownershipShare?.toString() ?? '',
    );
    int? selectedGroupId = company?.groupId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(company == null ? 'Ajouter une société' : 'Modifier la société'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Groupe d'investissement
                  DropdownButtonFormField<int>(
                    value: selectedGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Groupe d\'investissement',
                      prefixIcon: Icon(Icons.account_balance),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Aucun (indépendant)'),
                      ),
                      ..._groups.map((group) => DropdownMenuItem<int>(
                        value: group.id,
                        child: Text(group.name),
                      )),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedGroupId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Nom de la société
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom de la société *',
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le nom est requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Ville
                  TextFormField(
                    controller: cityController,
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Secteur
                  TextFormField(
                    controller: sectorController,
                    decoration: const InputDecoration(
                      labelText: 'Secteur d\'activité',
                      prefixIcon: Icon(Icons.category),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Part de détention
                  TextFormField(
                    controller: ownershipController,
                    decoration: const InputDecoration(
                      labelText: 'Part de détention (%)',
                      prefixIcon: Icon(Icons.percent),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final num = double.tryParse(value);
                        if (num == null || num < 0 || num > 100) {
                          return 'Entre 0 et 100%';
                        }
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await _saveCompany(
                    id: company?.id,
                    name: nameController.text,
                    groupId: selectedGroupId,
                    city: cityController.text.isEmpty ? null : cityController.text,
                    sector: sectorController.text.isEmpty ? null : sectorController.text,
                    ownershipShare: ownershipController.text.isEmpty 
                        ? null 
                        : double.tryParse(ownershipController.text),
                  );
                  if (mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2A4B63),
              ),
              child: Text(company == null ? 'Ajouter' : 'Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupForm({InvestorGroup? group}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: group?.name ?? '');
    final sectorController = TextEditingController(text: group?.sector ?? '');
    final countryController = TextEditingController(text: group?.country ?? 'France');
    final contactController = TextEditingController(text: group?.contactMain ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group == null ? 'Ajouter un groupe' : 'Modifier le groupe'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du groupe *',
                    prefixIcon: Icon(Icons.account_balance),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Le nom est requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: sectorController,
                  decoration: const InputDecoration(
                    labelText: 'Secteur',
                    prefixIcon: Icon(Icons.category),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: countryController,
                  decoration: const InputDecoration(
                    labelText: 'Pays',
                    prefixIcon: Icon(Icons.public),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: contactController,
                  decoration: const InputDecoration(
                    labelText: 'Contact principal',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                await _saveGroup(
                  id: group?.id,
                  name: nameController.text,
                  sector: sectorController.text.isEmpty ? null : sectorController.text,
                  country: countryController.text.isEmpty ? null : countryController.text,
                  contactMain: contactController.text.isEmpty ? null : contactController.text,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A4B63),
            ),
            child: Text(group == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // CRUD OPERATIONS
  // ============================================================================

  Future<void> _saveCompany({
    int? id,
    required String name,
    int? groupId,
    String? city,
    String? sector,
    double? ownershipShare,
  }) async {
    try {
      if (id == null) {
        // Création
        await SupabaseService.client.from('company').insert({
          'name': name,
          'group_id': groupId,
          'city': city,
          'sector': sector,
          'ownership_share': ownershipShare,
        });
      } else {
        // Mise à jour
        await SupabaseService.client.from('company').update({
          'name': name,
          'group_id': groupId,
          'city': city,
          'sector': sector,
          'ownership_share': ownershipShare,
        }).eq('id', id);
      }

      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Société enregistrée'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveGroup({
    int? id,
    required String name,
    String? sector,
    String? country,
    String? contactMain,
  }) async {
    try {
      if (id == null) {
        // Création
        await SupabaseService.client.from('investor_group').insert({
          'name': name,
          'sector': sector,
          'country': country,
          'contact_main': contactMain,
        });
      } else {
        // Mise à jour
        await SupabaseService.client.from('investor_group').update({
          'name': name,
          'sector': sector,
          'country': country,
          'contact_main': contactMain,
        }).eq('id', id);
      }

      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Groupe enregistré'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteCompany(Company company) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la société'),
        content: Text('Supprimer ${company.name} ?\n\nToutes les missions associées seront également supprimées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.client.from('company').delete().eq('id', company.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Société supprimée'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteGroup(InvestorGroup group) async {
    final companiesCount = _companies.where((c) => c.groupId == group.id).length;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le groupe'),
        content: Text(
          'Supprimer ${group.name} ?\n\n'
          '${companiesCount > 0 ? "⚠️ $companiesCount société(s) associée(s) seront également supprimées." : ""}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await SupabaseService.client.from('investor_group').delete().eq('id', group.id);
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Groupe supprimé'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}

