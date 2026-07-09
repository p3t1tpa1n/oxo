// ============================================================================
// PAGE DE PARAMÈTRES DU MODULE TIMESHEET - Pour les associés uniquement
// ============================================================================

import 'package:flutter/material.dart';
import '../../models/timesheet_models.dart';
import '../../services/timesheet_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../services/company_service.dart';

class TimesheetSettingsPage extends StatefulWidget {
  const TimesheetSettingsPage({super.key});

  @override
  State<TimesheetSettingsPage> createState() => _TimesheetSettingsPageState();
}

class _TimesheetSettingsPageState extends State<TimesheetSettingsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PartnerRate> _rates = [];
  List<PartnerClientPermission> _permissions = [];
  List<Map<String, dynamic>> _operators = [];
  List<Map<String, dynamic>> _companies = []; // Pour les tarifs journaliers
  List<Map<String, dynamic>> _clients = []; // Pour les permissions (encore basées sur clients)
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await Future.wait([
        TimesheetService.getAllRates(),
        TimesheetService.getAllPermissions(),
        SupabaseService.getPartners(),
        CompanyService.getAllCompanies(), // Pour les tarifs journaliers
        SupabaseService.fetchClients(), // Pour les permissions (encore basées sur clients)
      ]);

      setState(() {
        _rates = results[0] as List<PartnerRate>;
        _permissions = results[1] as List<PartnerClientPermission>;
        _operators = results[2] as List<Map<String, dynamic>>;
        _companies = results[3] as List<Map<String, dynamic>>; // Pour les tarifs
        _clients = results[4] as List<Map<String, dynamic>>; // Pour les permissions
        _isLoading = false;
      });
      
      // Debug: vérifier les companies chargées
      debugPrint('📊 Companies chargées: ${_companies.length}');
      if (_companies.isNotEmpty) {
        debugPrint('📋 Première company: ${_companies.first}');
        debugPrint('📋 Type de l\'ID: ${_companies.first['id'].runtimeType}');
      } else {
        debugPrint('⚠️ Aucune company trouvée !');
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement données: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            userRole: SupabaseService.currentUserRole,
            selectedRoute: '/timesheet/settings',
          ),
          Expanded(
            child: Column(
              children: [
                const TopBar(title: 'OXO TIME SHEETS - Paramètres'),
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2A4B63),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF2A4B63),
                  tabs: const [
                    Tab(text: 'Tarifs journaliers', icon: Icon(Icons.euro)),
                    Tab(text: 'Permissions clients', icon: Icon(Icons.lock)),
                  ],
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildRatesTab(),
                            _buildPermissionsTab(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_timesheet_settings',
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddRateDialog();
          } else {
            _showAddPermissionDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'Nouveau tarif' : 'Nouvelle permission'),
        backgroundColor: const Color(0xFF2A4B63),
      ),
    );
  }

  // ============================================================================
  // ONGLET TARIFS
  // ============================================================================

  Widget _buildRatesTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestion des tarifs journaliers',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2A4B63),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Définissez les tarifs journaliers pour chaque opérateur et client.',
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildRatesTable()),
        ],
      ),
    );
  }

  Widget _buildRatesTable() {
    if (_rates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.euro_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Aucun tarif défini',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              'Cliquez sur le bouton + pour ajouter un tarif',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: MaterialStateProperty.all(const Color(0xFF2A4B63).withOpacity(0.1)),
          columns: const [
            DataColumn(label: Text('Partenaire', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Tarif journalier (€)', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _rates.map((rate) {
            return DataRow(cells: [
              DataCell(Text(rate.partnerName ?? rate.partnerId)),
              DataCell(Text(rate.partnerEmail ?? '-')),
              DataCell(Text(rate.companyName ?? (rate.companyId?.toString() ?? '-'))),
              DataCell(Text('${rate.dailyRate.toStringAsFixed(2)} €', style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => _showEditRateDialog(rate),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _deleteRate(rate),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _showAddRateDialog() {
    String? selectedOperatorId;
    int? selectedCompanyId; // Changé de String? selectedClientId à int? selectedCompanyId
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouveau tarif journalier'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedOperatorId,
                  decoration: const InputDecoration(
                    labelText: 'Partenaire',
                    border: OutlineInputBorder(),
                  ),
                  items: _operators.where((op) => op['user_id'] != null && op['email'] != null).map((op) {
                    return DropdownMenuItem(
                      value: op['user_id'].toString(),
                      child: Text(op['email'].toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedOperatorId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCompanyId,
                  decoration: const InputDecoration(
                    labelText: 'Company',
                    border: OutlineInputBorder(),
                  ),
                  items: _companies.where((company) => company['id'] != null && company['name'] != null).map((company) {
                    // Convertir l'ID en int de manière sécurisée
                    final id = company['id'];
                    final companyId = id is int ? id : (id is num ? id.toInt() : int.tryParse(id.toString()));
                    if (companyId == null) return null;
                    return DropdownMenuItem<int>(
                      value: companyId,
                      child: Text(company['name'].toString()),
                    );
                  }).whereType<DropdownMenuItem<int>>().toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCompanyId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: rateController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Tarif journalier (€)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.euro),
                  ),
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
              onPressed: () async {
                if (selectedOperatorId == null || selectedCompanyId == null || rateController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tous les champs sont requis')),
                  );
                  return;
                }

                final rate = double.tryParse(rateController.text);
                if (rate == null || rate < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tarif invalide')),
                  );
                  return;
                }

                try {
                  await TimesheetService.upsertRate(
                    partnerId: selectedOperatorId!,
                    companyId: selectedCompanyId!,
                    dailyRate: rate,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Tarif créé'), backgroundColor: Colors.green),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A4B63)),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRateDialog(PartnerRate rate) {
    final rateController = TextEditingController(text: rate.dailyRate.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le tarif'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Partenaire',
                  border: const OutlineInputBorder(),
                  hintText: rate.partnerEmail ?? rate.partnerId,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Company',
                  border: const OutlineInputBorder(),
                  hintText: rate.companyName ?? (rate.companyId?.toString() ?? '-'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Tarif journalier (€)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.euro),
                ),
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
            onPressed: () async {
              final newRate = double.tryParse(rateController.text);
              if (newRate == null || newRate < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tarif invalide')),
                );
                return;
              }

              try {
                await TimesheetService.upsertRate(
                  partnerId: rate.partnerId,
                  companyId: rate.companyId!,
                  dailyRate: newRate,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Tarif modifié'), backgroundColor: Colors.green),
                  );
                  _loadData();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A4B63)),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRate(PartnerRate rate) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le tarif'),
        content: Text('Supprimer le tarif de ${rate.partnerEmail ?? rate.partnerId} pour ${rate.companyName ?? (rate.companyId?.toString() ?? '-')} ?'),
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

    if (confirm != true) return;

    try {
      await TimesheetService.deleteRate(rate.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Tarif supprimé'), backgroundColor: Colors.green),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ============================================================================
  // ONGLET PERMISSIONS
  // ============================================================================

  Widget _buildPermissionsTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestion des permissions clients',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2A4B63),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Définissez quels clients sont accessibles pour chaque opérateur.',
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
          const SizedBox(height: 24),
          Expanded(child: _buildPermissionsTable()),
        ],
      ),
    );
  }

  Widget _buildPermissionsTable() {
    if (_permissions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              'Aucune permission définie',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 10),
            Text(
              'Par défaut, tous les opérateurs ont accès à tous les clients',
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      color: Colors.white,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 16,
          headingRowColor: MaterialStateProperty.all(const Color(0xFF2A4B63).withOpacity(0.1)),
          columns: const [
            DataColumn(label: Text('Partenaire', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Accès autorisé', style: TextStyle(fontWeight: FontWeight.w600))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w600))),
          ],
          rows: _permissions.map((perm) {
            return DataRow(cells: [
              DataCell(Text(perm.partnerName ?? perm.partnerId)),
              DataCell(Text(perm.partnerEmail ?? '-')),
              DataCell(Text(perm.clientName ?? perm.clientId)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: perm.allowed ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: perm.allowed ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    perm.allowed ? '✅ OUI' : '⛔ NON',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: perm.allowed ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () => _showEditPermissionDialog(perm),
                      tooltip: 'Modifier',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _deletePermission(perm),
                      tooltip: 'Supprimer',
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _showAddPermissionDialog() {
    String? selectedOperatorId;
    String? selectedClientId; // Les permissions utilisent encore clients (pas company)
    bool allowed = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nouvelle permission'),
          content: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedOperatorId,
                  decoration: const InputDecoration(
                    labelText: 'Partenaire',
                    border: OutlineInputBorder(),
                  ),
                  items: _operators.where((op) => op['user_id'] != null && op['email'] != null).map((op) {
                    return DropdownMenuItem(
                      value: op['user_id'].toString(),
                      child: Text(op['email'].toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedOperatorId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedClientId,
                  decoration: const InputDecoration(
                    labelText: 'Client',
                    border: OutlineInputBorder(),
                  ),
                  items: _clients.where((client) => client['id'] != null && client['name'] != null).map((client) {
                    return DropdownMenuItem(
                      value: client['id'].toString(),
                      child: Text(client['name'].toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedClientId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Accès autorisé'),
                  value: allowed,
                  onChanged: (value) {
                    setDialogState(() {
                      allowed = value;
                    });
                  },
                  activeColor: const Color(0xFF2A4B63),
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
              onPressed: () async {
                if (selectedOperatorId == null || selectedClientId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tous les champs sont requis')),
                  );
                  return;
                }

                try {
                  await TimesheetService.upsertPermission(
                    partnerId: selectedOperatorId!,
                    clientId: selectedClientId!,
                    allowed: allowed,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Permission créée'), backgroundColor: Colors.green),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A4B63)),
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPermissionDialog(PartnerClientPermission perm) {
    bool allowed = perm.allowed;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Modifier la permission'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Partenaire',
                    border: const OutlineInputBorder(),
                    hintText: perm.partnerEmail ?? perm.partnerId,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Client',
                    border: const OutlineInputBorder(),
                    hintText: perm.clientName ?? perm.clientId,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Accès autorisé'),
                  value: allowed,
                  onChanged: (value) {
                    setDialogState(() {
                      allowed = value;
                    });
                  },
                  activeColor: const Color(0xFF2A4B63),
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
              onPressed: () async {
                try {
                  await TimesheetService.upsertPermission(
                    partnerId: perm.partnerId,
                    clientId: perm.clientId,
                    allowed: allowed,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Permission modifiée'), backgroundColor: Colors.green),
                    );
                    _loadData();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2A4B63)),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePermission(PartnerClientPermission perm) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la permission'),
        content: Text('Supprimer la permission de ${perm.partnerEmail ?? perm.partnerId} pour ${perm.clientName ?? perm.clientId} ?'),
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

    if (confirm != true) return;

    try {
      await TimesheetService.deletePermission(perm.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Permission supprimée'), backgroundColor: Colors.green),
        );
        _loadData();
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

