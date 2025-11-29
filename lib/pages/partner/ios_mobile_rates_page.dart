import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/timesheet_models.dart';
import '../../services/timesheet_service.dart';
import '../../services/supabase_service.dart';

class IOSMobileRatesPage extends StatefulWidget {
  final bool showHeader;
  
  const IOSMobileRatesPage({
    Key? key,
    this.showHeader = true,
  }) : super(key: key);

  @override
  State<IOSMobileRatesPage> createState() => _IOSMobileRatesPageState();
}

class _IOSMobileRatesPageState extends State<IOSMobileRatesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Données
  List<PartnerRate> _rates = [];
  List<PartnerClientPermission> _permissions = [];
  List<Map<String, dynamic>> _partners = [];
  List<Map<String, dynamic>> _companies = [];
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
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        TimesheetService.getAllRates(),
        TimesheetService.getAllPermissions(),
        SupabaseService.getPartners(),
        SupabaseService.getAllCompanies(),
      ]);

      if (mounted) {
        setState(() {
          _rates = results[0] as List<PartnerRate>;
          _permissions = results[1] as List<PartnerClientPermission>;
          _partners = results[2] as List<Map<String, dynamic>>;
          _companies = results[3] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement tarifs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showHeader) {
      // Sans header - utilisé dans le TabBarView
      return DefaultTextStyle(
        style: const TextStyle(
          decoration: TextDecoration.none,
          color: CupertinoColors.label,
          fontFamily: '.SF Pro Text',
        ),
        child: Container(
          color: CupertinoColors.systemGroupedBackground,
          child: Column(
            children: [
              // Tabs internes
              Material(
                color: CupertinoColors.systemGroupedBackground,
                child: TabBar(
                  controller: _tabController,
                  labelColor: CupertinoColors.systemBlue,
                  unselectedLabelColor: CupertinoColors.secondaryLabel,
                  indicatorColor: CupertinoColors.systemBlue,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.person_add, size: 16),
                          SizedBox(width: 6),
                          Text('Journalier'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.person_2, size: 16),
                          SizedBox(width: 6),
                          Text('Permissions clients'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CupertinoActivityIndicator())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDailyRatesTab(),
                          _buildPermissionsTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Avec header (navigation standalone)
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_left, color: CupertinoColors.systemBlue),
        ),
        middle: const Text(
          'Tarifs',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Tabs
            Material(
              color: CupertinoColors.systemGroupedBackground,
              child: TabBar(
                controller: _tabController,
                labelColor: CupertinoColors.systemBlue,
                unselectedLabelColor: CupertinoColors.secondaryLabel,
                indicatorColor: CupertinoColors.systemBlue,
                tabs: const [
                  Tab(text: 'Journalier'),
                  Tab(text: 'Permissions clients'),
                ],
              ),
            ),
            
            Expanded(
              child: _isLoading
                  ? const Center(child: CupertinoActivityIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDailyRatesTab(),
                        _buildPermissionsTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ONGLET TARIFS JOURNALIERS
  // ============================================

  Widget _buildDailyRatesTab() {
    final totalValue = _rates.fold(0.0, (sum, rate) => sum + rate.dailyRate);
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre section
            const Text(
              'Gestion des tarifs journaliers',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.label,
                decoration: TextDecoration.none,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Compteurs
            Row(
              children: [
                Expanded(
                  child: _buildCounterCard(
                    value: _rates.length.toString(),
                    label: 'Propositions',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCounterCard(
                    value: totalValue.toStringAsFixed(0),
                    label: 'Valeur potentielle',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Liste des tarifs
            if (_rates.isEmpty)
              _buildEmptyState('Aucun tarif défini', 'Créez votre premier tarif journalier')
            else
              ..._rates.map((rate) => _buildRateCard(rate)),
            
            const SizedBox(height: 16),
            
            // Bouton ajouter
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: _showAddRateDialog,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add, color: CupertinoColors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Nouveau tarif',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterCard({required String value, required String label}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.label,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: CupertinoColors.secondaryLabel,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildRateCard(PartnerRate rate) {
    final partnerName = rate.partnerName ?? rate.partnerEmail ?? 'Partenaire';
    final companyName = rate.companyName ?? 'Client';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: CupertinoColors.systemBlue,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre (nom du partenaire ou mission)
          Text(
            partnerName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
              decoration: TextDecoration.none,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Client
          Text(
            'Client: $companyName',
            style: const TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel,
              decoration: TextDecoration.none,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Description (date de création)
          Text(
            'Créé le ${DateFormat('dd/MM/yyyy').format(rate.createdAt)}',
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.tertiaryLabel,
              decoration: TextDecoration.none,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Badge montant
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CupertinoColors.systemGrey4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '€',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.secondaryLabel,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      '${NumberFormat('#,##0.00', 'fr_FR').format(rate.dailyRate)} €',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.label,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Bouton modifier
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 32,
                onPressed: () => _showEditRateDialog(rate),
                child: const Icon(
                  CupertinoIcons.pencil,
                  color: CupertinoColors.systemBlue,
                  size: 20,
                ),
              ),
              // Bouton supprimer
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 32,
                onPressed: () => _confirmDeleteRate(rate),
                child: const Icon(
                  CupertinoIcons.trash,
                  color: CupertinoColors.systemRed,
                  size: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // ONGLET PERMISSIONS CLIENTS
  // ============================================

  Widget _buildPermissionsTab() {
    final allowedCount = _permissions.where((p) => p.allowed).length;
    
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre section
            const Text(
              'Permissions clients',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.label,
                decoration: TextDecoration.none,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Compteurs
            Row(
              children: [
                Expanded(
                  child: _buildCounterCard(
                    value: _permissions.length.toString(),
                    label: 'Permissions',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildCounterCard(
                    value: allowedCount.toString(),
                    label: 'Autorisées',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Liste des permissions
            if (_permissions.isEmpty)
              _buildEmptyState('Aucune permission', 'Les permissions clients apparaîtront ici')
            else
              ..._permissions.map((perm) => _buildPermissionCard(perm)),
            
            const SizedBox(height: 16),
            
            // Bouton ajouter
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: CupertinoColors.systemBlue,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 14),
                onPressed: _showAddPermissionDialog,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.add, color: CupertinoColors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Nouvelle permission',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionCard(PartnerClientPermission permission) {
    final partnerName = permission.partnerName ?? permission.partnerEmail ?? 'Partenaire';
    final clientName = permission.clientName ?? 'Client';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: permission.allowed ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  partnerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Client: $clientName',
                  style: const TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.secondaryLabel,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
          // Toggle permission
          CupertinoSwitch(
            value: permission.allowed,
            activeColor: CupertinoColors.systemGreen,
            onChanged: (value) => _togglePermission(permission, value),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.doc_text,
              size: 48,
              color: CupertinoColors.systemGrey3,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.secondaryLabel,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 15,
                color: CupertinoColors.tertiaryLabel,
                decoration: TextDecoration.none,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // DIALOGS
  // ============================================

  void _showAddRateDialog() {
    Map<String, dynamic>? selectedPartner;
    Map<String, dynamic>? selectedCompany;
    final rateController = TextEditingController();

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.6,
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
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Nouveau tarif',
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
                            if (selectedPartner != null && selectedCompany != null) {
                              final rate = double.tryParse(rateController.text.replaceAll(',', '.'));
                              if (rate != null && rate > 0) {
                                try {
                                  await TimesheetService.upsertRate(
                                    partnerId: selectedPartner!['user_id'],
                                    companyId: selectedCompany!['id'],
                                    dailyRate: rate,
                                  );
                                  Navigator.pop(context);
                                  _loadData();
                                  _showSuccessMessage('Tarif créé avec succès');
                                } catch (e) {
                                  _showErrorMessage('Erreur: $e');
                                }
                              } else {
                                _showErrorMessage('Veuillez saisir un tarif valide');
                              }
                            } else {
                              _showErrorMessage('Veuillez sélectionner un partenaire et un client');
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
                          // Sélecteur partenaire
                          Text(
                            'Partenaire',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showPartnerPicker(context, (partner) {
                              setDialogState(() => selectedPartner = partner);
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemGrey6,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: CupertinoColors.systemGrey4),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedPartner != null 
                                        ? '${selectedPartner!['first_name'] ?? ''} ${selectedPartner!['last_name'] ?? ''}'.trim()
                                        : 'Sélectionner un partenaire',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: selectedPartner != null 
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
                          
                          const SizedBox(height: 24),
                          
                          // Sélecteur client/company
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
                            onTap: () => _showCompanyPicker(context, (company) {
                              setDialogState(() => selectedCompany = company);
                            }),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          
                          const SizedBox(height: 24),
                          
                          // Champ tarif
                          Text(
                            'Tarif journalier',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: CupertinoColors.systemGrey4),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGrey5,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(9),
                                      bottomLeft: Radius.circular(9),
                                    ),
                                  ),
                                  child: Text(
                                    '€',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: CupertinoTextField(
                                    controller: rateController,
                                    placeholder: '500.00',
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    decoration: const BoxDecoration(),
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: Text(
                                    '/jour',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: CupertinoColors.secondaryLabel,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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

  void _showEditRateDialog(PartnerRate rate) {
    final rateController = TextEditingController(text: rate.dailyRate.toStringAsFixed(2));

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.4,
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
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Modifier le tarif',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text(
                          'OK',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: CupertinoColors.systemBlue,
                          ),
                        ),
                        onPressed: () async {
                          final newRate = double.tryParse(rateController.text.replaceAll(',', '.'));
                          if (newRate != null && newRate > 0) {
                            try {
                              await TimesheetService.upsertRate(
                                partnerId: rate.partnerId,
                                companyId: rate.companyId ?? 0,
                                dailyRate: newRate,
                              );
                              Navigator.pop(context);
                              _loadData();
                              _showSuccessMessage('Tarif modifié avec succès');
                            } catch (e) {
                              _showErrorMessage('Erreur: $e');
                            }
                          } else {
                            _showErrorMessage('Tarif invalide');
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
                        // Info partenaire/client
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                CupertinoIcons.person_fill,
                                size: 18,
                                color: CupertinoColors.systemBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  '${rate.partnerName ?? rate.partnerEmail ?? 'Partenaire'} • ${rate.companyName ?? 'Client'}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: CupertinoColors.systemBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Text(
                          'Tarif journalier',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: CupertinoColors.secondaryLabel,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: CupertinoColors.systemGrey4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemGrey5,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(9),
                                    bottomLeft: Radius.circular(9),
                                  ),
                                ),
                                child: Text(
                                  '€',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: CupertinoTextField(
                                  controller: rateController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: const BoxDecoration(),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Text(
                                  '/jour',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: CupertinoColors.secondaryLabel,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
    );
  }

  void _confirmDeleteRate(PartnerRate rate) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Supprimer le tarif'),
        content: Text('Supprimer le tarif de ${rate.partnerName ?? rate.partnerEmail ?? 'ce partenaire'} ?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Annuler'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Supprimer'),
            onPressed: () async {
              try {
                await TimesheetService.deleteRate(rate.id);
                Navigator.pop(context);
                _loadData();
                _showSuccessMessage('Tarif supprimé');
              } catch (e) {
                Navigator.pop(context);
                _showErrorMessage('Erreur: $e');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAddPermissionDialog() {
    // TODO: Implémenter le dialog d'ajout de permission
    _showSuccessMessage('Fonctionnalité à venir');
  }

  Future<void> _togglePermission(PartnerClientPermission permission, bool value) async {
    try {
      // Mise à jour directe via Supabase
      await SupabaseService.client
          .from('partner_client_permissions')
          .update({'allowed': value})
          .eq('id', permission.id);
      _loadData();
    } catch (e) {
      _showErrorMessage('Erreur: $e');
    }
  }

  void _showPartnerPicker(BuildContext parentContext, Function(Map<String, dynamic>) onSelect) {
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
                    'Sélectionner un partenaire',
                    style: TextStyle(
                      fontSize: 17, 
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: _partners.length,
                    itemBuilder: (context, index) {
                      final partner = _partners[index];
                      final name = '${partner['first_name'] ?? ''} ${partner['last_name'] ?? ''}'.trim();
                      return GestureDetector(
                        onTap: () {
                          onSelect(partner);
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
                          ),
                          child: Text(
                            name.isNotEmpty ? name : partner['email'] ?? 'Partenaire',
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

  void _showCompanyPicker(BuildContext parentContext, Function(Map<String, dynamic>) onSelect) {
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
                  child: ListView.builder(
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

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CupertinoColors.systemGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: CupertinoColors.systemRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}

