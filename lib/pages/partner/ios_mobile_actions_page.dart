import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:oxo/services/supabase_service.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';

class IOSMobileActionsPage extends StatefulWidget {
  const IOSMobileActionsPage({Key? key}) : super(key: key);

  @override
  State<IOSMobileActionsPage> createState() => _IOSMobileActionsPageState();
}

class _IOSMobileActionsPageState extends State<IOSMobileActionsPage> {
  List<Map<String, dynamic>> _actions = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    setState(() => _isLoading = true);
    try {
      final actions = await SupabaseService.getCommercialActions();
      if (mounted) {
        setState(() => _actions = actions);
      }
    } catch (e) {
      debugPrint('Erreur chargement actions: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      // 🧭 RÈGLE 2: Navigation intuitive
      navigationBar: IOSNavigationBar(
        title: "Actions Commerciales", // 🎯 RÈGLE 1: Titre clair
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
                _buildOverview(),
                _buildFilters(),
                Expanded(child: _buildActionsList()),
              ],
            ),
    );
  }

  // 📊 RÈGLE 7: Vue d'ensemble en premier
  Widget _buildOverview() {
    final activeActions = _actions.where((a) => a['status'] == 'in_progress').length;
    final potentialValue = _actions.fold(0.0, (sum, a) => sum + ((a['potential_value'] ?? 0.0) as num));

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: IOSTheme.primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('$activeActions', 'Actions en cours', CupertinoIcons.flame_fill)),
          const SizedBox(width: 16),
          Expanded(child: _buildStatCard(NumberFormat.currency(locale: 'fr_FR', symbol: '€').format(potentialValue), 'Valeur potentielle', CupertinoIcons.money_euro_circle)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
      ],
    );
  }

  // 🎯 RÈGLE 1: Filtres clairs
  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: CupertinoSegmentedControl<String>(
        children: const {
          'all': Text('Toutes'),
          'in_progress': Text('En cours'),
          'done': Text('Terminées'),
          'cancelled': Text('Annulées'),
        },
        onValueChanged: (value) => setState(() => _filterStatus = value),
        groupValue: _filterStatus,
      ),
    );
  }

  Widget _buildActionsList() {
    final filteredActions = _actions.where((action) {
      if (_filterStatus == 'all') return true;
      return action['status'] == _filterStatus;
    }).toList();

    if (filteredActions.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredActions.length,
      itemBuilder: (context, index) {
        return _buildActionCard(filteredActions[index]);
      },
    );
  }

  // 📊 RÈGLE 7: Hiérarchisation visuelle de la carte
  Widget _buildActionCard(Map<String, dynamic> action) {
    final status = action['status'] ?? 'in_progress';
    final dueDate = DateTime.tryParse(action['due_date'] ?? '');

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
            action['action_name'] ?? 'Action non définie',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: IOSTheme.labelPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Client: ${action['client_name'] ?? 'Non spécifié'}',
            style: const TextStyle(fontSize: 14, color: IOSTheme.labelSecondary),
          ),
          const SizedBox(height: 16),
          Text(
            action['description'] ?? 'Aucune description.',
            style: const TextStyle(fontSize: 14, color: IOSTheme.labelSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildInfoChip(
                '${(action['potential_value'] ?? 0)}€',
                CupertinoIcons.money_euro_circle,
              ),
              const SizedBox(width: 8),
              if (dueDate != null)
                _buildInfoChip(
                  DateFormat('dd/MM/yyyy').format(dueDate),
                  CupertinoIcons.calendar,
                ),
              const Spacer(),
              // 🔒 RÈGLE 6: Statut avec couleur ET texte
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          // 👤 RÈGLE 5: Actions claires
          if (status == 'in_progress') ...[
            const SizedBox(height: 20),
            CupertinoButton(
              color: IOSTheme.successColor,
              onPressed: () => _updateActionStatus(action['id'], 'done'),
              child: const Text('Marquer comme terminée'),
            ),
          ]
        ],
      ),
    );
  }
  
  Widget _buildInfoChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: IOSTheme.systemGray6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: IOSTheme.labelSecondary),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // 🎯 RÈGLE 1: État vide clair
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(CupertinoIcons.rocket, size: 50, color: IOSTheme.systemGray3),
          const SizedBox(height: 16),
          const Text('Aucune action commerciale', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Les nouvelles actions apparaîtront ici.', style: TextStyle(fontSize: 16, color: IOSTheme.labelSecondary)),
        ],
      ),
    );
  }

  // ⚡ RÈGLE 4: Feedback visuel
  Future<void> _updateActionStatus(int id, String newStatus) async {
    try {
      await SupabaseService.client.from('commercial_actions').update({'status': newStatus}).eq('id', id);
      _loadActions();
    } catch (e) {
      // Gérer l'erreur
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'in_progress': return IOSTheme.warningColor;
      case 'done': return IOSTheme.successColor;
      case 'cancelled': return IOSTheme.errorColor;
      default: return IOSTheme.systemGray;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'in_progress': return 'En cours';
      case 'done': return 'Terminée';
      case 'cancelled': return 'Annulée';
      default: return 'N/A';
    }
  }
}


