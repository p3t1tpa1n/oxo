import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oxo/services/supabase_service.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';

class IOSMobileAdminClientsPage extends StatefulWidget {
  const IOSMobileAdminClientsPage({Key? key}) : super(key: key);

  @override
  State<IOSMobileAdminClientsPage> createState() => _IOSMobileAdminClientsPageState();
}

class _IOSMobileAdminClientsPageState extends State<IOSMobileAdminClientsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final clientsFuture = SupabaseService.fetchClients();
      final invoicesFuture = SupabaseService.getAllInvoices();
      
      final results = await Future.wait([clientsFuture, invoicesFuture]);
      
      if (mounted) {
        setState(() {
          _clients = List<Map<String, dynamic>>.from(results[0]);
          _invoices = List<Map<String, dynamic>>.from(results[1]);
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement clients/factures: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      // 🧭 RÈGLE 2: Navigation intuitive
      navigationBar: IOSNavigationBar(
        title: "Clients & Facturation", // 🎯 RÈGLE 1: Titre clair
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: IOSTheme.primaryBlue),
        ),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.of(context).pushNamed('/create-client'),
            child: const Icon(CupertinoIcons.add, color: IOSTheme.primaryBlue),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator()) // ⚡ RÈGLE 4: Feedback chargement
          : Column(
              children: [
                // 📊 RÈGLE 7: Vue d'ensemble en premier
                _buildOverview(),
                
                // 🧭 RÈGLE 2: Navigation claire entre sections
                _buildTabs(),
                
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildClientsList(),
                      _buildInvoicesList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // 🎯 RÈGLE 1: Vue d'ensemble simple et claire
  Widget _buildOverview() {
    final totalRevenue = _invoices.fold(0.0, (sum, inv) => sum + (inv['amount'] ?? 0.0));
    final pendingInvoices = _invoices.where((inv) => inv['status'] == 'pending').length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: IOSTheme.primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('${_clients.length}', 'Clients Actifs', CupertinoIcons.person_3_fill)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard(NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(totalRevenue), 'Revenu total', CupertinoIcons.money_euro_circle_fill)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('$pendingInvoices', 'En attente', CupertinoIcons.hourglass)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // 🧭 RÈGLE 2: Navigation claire et prévisible
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: CupertinoSegmentedControl(
        children: {
          0: _buildTab('Clients', CupertinoIcons.person_2),
          1: _buildTab('Factures', CupertinoIcons.doc_text),
        },
        onValueChanged: (int index) {
          _tabController.animateTo(index);
          setState(() {}); // Pour mettre à jour l'icône
        },
        groupValue: _tabController.index,
      ),
    );
  }

  Widget _buildTab(String text, IconData icon) {
    final isSelected = _tabController.index == (_tabController.animation?.value.round() ?? _tabController.index);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? IOSTheme.primaryBlue : IOSTheme.labelSecondary,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }

  // Section Clients
  Widget _buildClientsList() {
    final filteredClients = _clients.where((client) {
      final name = (client['name'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // 👤 RÈGLE 5: Recherche facile
        CupertinoSearchTextField(
          placeholder: 'Rechercher un client',
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 20),
        
        if (filteredClients.isEmpty)
          _buildEmptyState('Aucun client trouvé', 'Les clients que vous ajoutez apparaîtront ici.', CupertinoIcons.person_2_fill),
        
        ...filteredClients.map((client) => _buildClientCard(client)),
      ],
    );
  }

  // 📊 RÈGLE 7: Hiérarchisation visuelle de la carte client
  Widget _buildClientCard(Map<String, dynamic> client) {
    final clientName = client['name'] ?? 'Client inconnu';
    final contactEmail = client['contact_email'] ?? 'Aucun contact';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IOSTheme.systemGray5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info principale
          Text(
            clientName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: IOSTheme.labelPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(CupertinoIcons.mail, size: 16, color: IOSTheme.labelSecondary),
              const SizedBox(width: 8),
              Text(
                contactEmail,
                style: const TextStyle(
                  fontSize: 14,
                  color: IOSTheme.labelSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 👤 RÈGLE 5: Actions claires et accessibles
          Row(
            children: [
              // 📊 RÈGLE 7: Action principale mise en avant
              Expanded(
                child: CupertinoButton(
                  color: IOSTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: () {
                    // TODO: Naviguer vers les détails du client
                  },
                  child: const Text('Voir détails', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              // 📱 RÈGLE 3: Touch target suffisant pour les actions secondaires
              CupertinoButton(
                color: IOSTheme.systemGray5,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.all(12),
                onPressed: () {
                  // TODO: Lancer l'email
                },
                child: const Icon(CupertinoIcons.mail_solid, color: IOSTheme.labelSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section Factures
  Widget _buildInvoicesList() {
    final filteredInvoices = _invoices.where((invoice) {
      final clientName = _clients.firstWhere((c) => c['id'] == invoice['client_id'], orElse: () => {})['name'] ?? '';
      final query = _searchQuery.toLowerCase();
      return clientName.toLowerCase().contains(query);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CupertinoSearchTextField(
          placeholder: 'Rechercher une facture par client',
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        const SizedBox(height: 20),
        
        if (filteredInvoices.isEmpty)
          _buildEmptyState('Aucune facture trouvée', 'Les factures créées apparaîtront ici.', CupertinoIcons.doc_text_fill),
          
        ...filteredInvoices.map((invoice) => _buildInvoiceCard(invoice)),
      ],
    );
  }

  // 🔒 RÈGLE 6: Pas que de la couleur pour le statut
  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final status = invoice['status'] ?? 'pending';
    final amount = (invoice['amount'] ?? 0.0).toDouble();
    final dueDate = DateTime.tryParse(invoice['due_date'] ?? '') ?? DateTime.now();
    final clientName = _clients.firstWhere((c) => c['id'] == invoice['client_id'], orElse: () => {})['name'] ?? 'Client inconnu';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(status).withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  clientName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: IOSTheme.labelPrimary,
                  ),
                ),
              ),
              // 🔒 RÈGLE 6: Statut avec couleur ET texte
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 📊 RÈGLE 7: Info principale (montant) mise en avant
          Text(
            NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(amount),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: IOSTheme.labelPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Échéance: ${DateFormat('d MMMM yyyy', 'fr_FR').format(dueDate)}',
            style: const TextStyle(
              fontSize: 14,
              color: IOSTheme.labelSecondary,
            ),
          ),
          
          if (status == 'pending') ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                color: IOSTheme.successColor,
                borderRadius: BorderRadius.circular(12),
                padding: const EdgeInsets.symmetric(vertical: 12),
                onPressed: () {
                  // TODO: Marquer comme payée
                },
                child: const Text('Marquer comme payée', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🎯 RÈGLE 1: État vide clair
  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: IOSTheme.systemGray6,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                icon,
                size: 40,
                color: IOSTheme.systemGray3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: IOSTheme.labelPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: IOSTheme.labelSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Méthodes utilitaires
  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid': return IOSTheme.successColor;
      case 'pending': return IOSTheme.warningColor;
      case 'overdue': return IOSTheme.errorColor;
      default: return IOSTheme.systemGray;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'paid': return 'Payée';
      case 'pending': return 'En attente';
      case 'overdue': return 'En retard';
      default: return status;
    }
  }
}
