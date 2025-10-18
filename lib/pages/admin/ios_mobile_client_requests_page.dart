import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:oxo/services/supabase_service.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';

class IOSMobileClientRequestsPage extends StatefulWidget {
  const IOSMobileClientRequestsPage({Key? key}) : super(key: key);

  @override
  State<IOSMobileClientRequestsPage> createState() => _IOSMobileClientRequestsPageState();
}

class _IOSMobileClientRequestsPageState extends State<IOSMobileClientRequestsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _projectProposals = [];
  List<Map<String, dynamic>> _timeExtensionRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final proposalsFuture = SupabaseService.getProjectProposals();
      final extensionsFuture = SupabaseService.getTimeExtensionRequests();
      
      final results = await Future.wait([proposalsFuture, extensionsFuture]);
      
      if (mounted) {
        setState(() {
          _projectProposals = List<Map<String, dynamic>>.from(results[0]);
          _timeExtensionRequests = List<Map<String, dynamic>>.from(results[1]);
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement demandes clients: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      // 🧭 RÈGLE 2: Navigation intuitive
      navigationBar: IOSNavigationBar(
        title: "Demandes Clients", // 🎯 RÈGLE 1: Titre clair
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: IOSTheme.primaryBlue),
        ),
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
                      _buildProposalsList(),
                      _buildExtensionsList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // 🎯 RÈGLE 1: Vue d'ensemble simple et claire
  Widget _buildOverview() {
    final pendingProposals = _projectProposals.where((p) => p['status'] == 'pending').length;
    final pendingExtensions = _timeExtensionRequests.where((e) => e['status'] == 'pending').length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: IOSTheme.primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('$pendingProposals', 'Propositions', CupertinoIcons.doc_append)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard('$pendingExtensions', 'Extensions', CupertinoIcons.time_solid)),
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
          0: _buildTab('Propositions', CupertinoIcons.doc_append),
          1: _buildTab('Extensions', CupertinoIcons.time),
        },
        onValueChanged: (int index) {
          _tabController.animateTo(index);
          setState(() {});
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

  // Section Propositions
  Widget _buildProposalsList() {
    if (_projectProposals.isEmpty) {
      return _buildEmptyState('Aucune proposition', 'Les propositions de projet des clients apparaîtront ici.', CupertinoIcons.doc_append);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: _projectProposals.map((proposal) => _buildProposalCard(proposal)).toList(),
    );
  }

  // 📊 RÈGLE 7: Hiérarchisation visuelle
  Widget _buildProposalCard(Map<String, dynamic> proposal) {
    final status = proposal['status'] ?? 'pending';
    
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
          // 📊 RÈGLE 7: Info principale en haut
          Text(
            proposal['project_name'] ?? 'Nouveau Projet',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: IOSTheme.labelPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Client: ${proposal['client_name'] ?? 'Inconnu'}',
            style: const TextStyle(fontSize: 14, color: IOSTheme.labelSecondary),
          ),
          const SizedBox(height: 16),
          // Description
          Text(
            proposal['description'] ?? 'Aucune description',
            style: const TextStyle(fontSize: 14, color: IOSTheme.labelSecondary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          
          // 👤 RÈGLE 5: Actions claires uniquement si nécessaires
          if (status == 'pending')
            _buildActionButtons(
              onApprove: () => _updateStatus('project_proposals', proposal['id'], 'approved'),
              onReject: () => _updateStatus('project_proposals', proposal['id'], 'rejected'),
            ),
        ],
      ),
    );
  }

  // Section Extensions
  Widget _buildExtensionsList() {
    if (_timeExtensionRequests.isEmpty) {
      return _buildEmptyState('Aucune demande', 'Les demandes d\'extension de temps apparaîtront ici.', CupertinoIcons.time);
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: _timeExtensionRequests.map((request) => _buildExtensionCard(request)).toList(),
    );
  }

  Widget _buildExtensionCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    
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
          Text(
            'Projet: ${request['project_name'] ?? 'Inconnu'}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: IOSTheme.labelPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Client: ${request['client_name'] ?? 'Inconnu'}',
            style: const TextStyle(fontSize: 14, color: IOSTheme.labelSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            'Extension demandée: ${request['days_requested']} jours',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: IOSTheme.labelPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Raison: ${request['reason'] ?? 'Non spécifiée'}',
            style: const TextStyle(fontSize: 14, color: IOSTheme.labelSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          
          if (status == 'pending')
            _buildActionButtons(
              onApprove: () => _updateStatus('time_extension_requests', request['id'], 'approved'),
              onReject: () => _updateStatus('time_extension_requests', request['id'], 'rejected'),
            ),
        ],
      ),
    );
  }
  
  // 📱 RÈGLE 3: Boutons avec large zone de clic
  Widget _buildActionButtons({required VoidCallback onApprove, required VoidCallback onReject}) {
    return Row(
      children: [
        Expanded(
          child: CupertinoButton(
            color: IOSTheme.successColor,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: onApprove,
            child: const Text('Approuver', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CupertinoButton(
            color: IOSTheme.errorColor,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.symmetric(vertical: 12),
            onPressed: onReject,
            child: const Text('Rejeter', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ],
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
              child: Icon(icon, size: 40, color: IOSTheme.systemGray3),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: IOSTheme.labelPrimary)),
            const SizedBox(height: 8),
            Text(subtitle, style: const TextStyle(fontSize: 16, color: IOSTheme.labelSecondary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ⚡ RÈGLE 4: Feedback visuel après action
  Future<void> _updateStatus(String table, int id, String newStatus) async {
    try {
      await SupabaseService.client.from(table).update({'status': newStatus}).eq('id', id);
      _loadData(); // Recharger les données
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Demande ${newStatus == 'approved' ? 'approuvée' : 'rejetée'}'),
          backgroundColor: newStatus == 'approved' ? IOSTheme.successColor : IOSTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Erreur lors de la mise à jour'),
          backgroundColor: IOSTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  // Méthodes utilitaires
  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return IOSTheme.successColor;
      case 'rejected': return IOSTheme.errorColor;
      case 'pending': return IOSTheme.warningColor;
      default: return IOSTheme.systemGray;
    }
  }
}
