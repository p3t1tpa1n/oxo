// lib/pages/partner/actions_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_role.dart';
import '../../services/supabase_service.dart';
import '../../widgets/base_page_widget.dart';
import '../../widgets/standard_dialogs.dart' as dialogs;

class ActionsPage extends StatefulWidget {
  const ActionsPage({super.key});

  @override
  State<ActionsPage> createState() => _ActionsPageState();
}

class _ActionsPageState extends State<ActionsPage> {
  List<Map<String, dynamic>> _actions = [];
  List<Map<String, dynamic>> _filteredActions = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'all';
  String _filterPriority = 'all';
  String _sortBy = 'created_at';
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadActions();
  }

  Future<void> _loadActions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Pour l'instant, créer des données fictives car il n'y a pas encore de table actions
      await Future.delayed(const Duration(milliseconds: 500)); // Simuler le chargement
      
      final mockActions = [
        {
          'id': '1',
          'title': 'Appel prospect ClientCorp',
          'description': 'Premier contact avec ClientCorp pour présenter nos services',
          'type': 'call',
          'status': 'planned',
          'priority': 'high',
          'due_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
          'client_name': 'ClientCorp',
          'contact_person': 'Jean Dubois',
          'contact_email': 'jean.dubois@clientcorp.com',
          'contact_phone': '+33 1 23 45 67 89',
          'estimated_value': 15000.0,
          'notes': 'Client intéressé par nos solutions de gestion de projet',
          'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          'updated_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
        },
        {
          'id': '2',
          'title': 'Présentation TechStart',
          'description': 'Démonstration de notre plateforme à TechStart',
          'type': 'meeting',
          'status': 'in_progress',
          'priority': 'urgent',
          'due_date': DateTime.now().add(const Duration(hours: 3)).toIso8601String(),
          'client_name': 'TechStart',
          'contact_person': 'Marie Martin',
          'contact_email': 'marie.martin@techstart.fr',
          'contact_phone': '+33 1 98 76 54 32',
          'estimated_value': 25000.0,
          'notes': 'Startup en croissance, budget confirmé',
          'created_at': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          'updated_at': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        },
        {
          'id': '3',
          'title': 'Suivi InnovaCorp',
          'description': 'Relance après envoi de devis',
          'type': 'follow_up',
          'status': 'completed',
          'priority': 'medium',
          'due_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
          'client_name': 'InnovaCorp',
          'contact_person': 'Paul Durand',
          'contact_email': 'paul.durand@innovacorp.com',
          'contact_phone': '+33 1 11 22 33 44',
          'estimated_value': 8000.0,
          'notes': 'Devis accepté, contrat en préparation',
          'created_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
          'updated_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'id': '4',
          'title': 'Email de prospection GlobalTech',
          'description': 'Envoi d\'email de présentation et demande de RDV',
          'type': 'email',
          'status': 'planned',
          'priority': 'low',
          'due_date': DateTime.now().add(const Duration(days: 3)).toIso8601String(),
          'client_name': 'GlobalTech',
          'contact_person': 'Sophie Leblanc',
          'contact_email': 'sophie.leblanc@globaltech.com',
          'estimated_value': 12000.0,
          'notes': 'Contact obtenu via LinkedIn',
          'created_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
          'updated_at': DateTime.now().subtract(const Duration(hours: 6)).toIso8601String(),
        },
      ];

      setState(() {
        _actions = mockActions;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = _actions;

    // Filtrer par statut
    if (_filterStatus != 'all') {
      filtered = filtered.where((action) => action['status'] == _filterStatus).toList();
    }

    // Filtrer par priorité
    if (_filterPriority != 'all') {
      filtered = filtered.where((action) => action['priority'] == _filterPriority).toList();
    }

    // Trier
    filtered.sort((a, b) {
      dynamic valueA, valueB;
      
      switch (_sortBy) {
        case 'due_date':
          valueA = DateTime.tryParse(a['due_date'] ?? '') ?? DateTime.now();
          valueB = DateTime.tryParse(b['due_date'] ?? '') ?? DateTime.now();
          break;
        case 'priority':
          final priorityOrder = {'urgent': 4, 'high': 3, 'medium': 2, 'low': 1};
          valueA = priorityOrder[a['priority']] ?? 0;
          valueB = priorityOrder[b['priority']] ?? 0;
          break;
        case 'estimated_value':
          valueA = a['estimated_value'] ?? 0;
          valueB = b['estimated_value'] ?? 0;
          break;
        default:
          valueA = DateTime.tryParse(a[_sortBy] ?? '') ?? DateTime.now();
          valueB = DateTime.tryParse(b[_sortBy] ?? '') ?? DateTime.now();
      }

      return _sortAscending ? valueA.compareTo(valueB) : valueB.compareTo(valueA);
    });

    setState(() {
      _filteredActions = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePageWidget(
      title: 'Actions Commerciales',
      route: '/actions',
      isLoading: _isLoading,
      errorMessage: _error,
      hasData: _filteredActions.isNotEmpty,
      onRefresh: _loadActions,
      floatingActionButtons: [
        FloatingActionButton.extended(
          onPressed: _showCreateActionDialog,
          backgroundColor: const Color(0xFF1784af),
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Nouvelle Action', style: TextStyle(color: Colors.white)),
        ),
      ],
      emptyStateWidget: StandardEmptyState(
        icon: Icons.business_center_outlined,
        title: 'Aucune action commerciale',
        subtitle: 'Créez votre première action pour commencer votre prospection.',
        actionLabel: 'Créer une action',
        onAction: _showCreateActionDialog,
      ),
      body: _buildActionsContent(),
    );
  }

  Widget _buildActionsContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildFiltersCard(),
          const SizedBox(height: 24),
          _buildStatsCards(),
          const SizedBox(height: 24),
          Expanded(
            child: _buildActionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _filterStatus,
                decoration: const InputDecoration(
                  labelText: 'Statut',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Tous les statuts')),
                  DropdownMenuItem(value: 'planned', child: Text('Planifiées')),
                  DropdownMenuItem(value: 'in_progress', child: Text('En cours')),
                  DropdownMenuItem(value: 'completed', child: Text('Terminées')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Annulées')),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterStatus = value!;
                  });
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _filterPriority,
                decoration: const InputDecoration(
                  labelText: 'Priorité',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('Toutes priorités')),
                  DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                  DropdownMenuItem(value: 'high', child: Text('Haute')),
                  DropdownMenuItem(value: 'medium', child: Text('Moyenne')),
                  DropdownMenuItem(value: 'low', child: Text('Basse')),
                ],
                onChanged: (value) {
                  setState(() {
                    _filterPriority = value!;
                  });
                  _applyFilters();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  labelText: 'Trier par',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'due_date', child: Text('Échéance')),
                  DropdownMenuItem(value: 'priority', child: Text('Priorité')),
                  DropdownMenuItem(value: 'estimated_value', child: Text('Valeur')),
                  DropdownMenuItem(value: 'created_at', child: Text('Date création')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sortBy = value!;
                  });
                  _applyFilters();
                },
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  _sortAscending = !_sortAscending;
                });
                _applyFilters();
              },
              icon: Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                color: const Color(0xFF1784af),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final plannedCount = _actions.where((a) => a['status'] == 'planned').length;
    final inProgressCount = _actions.where((a) => a['status'] == 'in_progress').length;
    final completedCount = _actions.where((a) => a['status'] == 'completed').length;
    final totalValue = _actions.fold<double>(0, (sum, action) => sum + (action['estimated_value'] ?? 0));

    return Row(
      children: [
        Expanded(child: _buildStatCard('Planifiées', plannedCount, Colors.orange, Icons.schedule)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('En cours', inProgressCount, Colors.blue, Icons.trending_up)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Terminées', completedCount, Colors.green, Icons.check_circle)),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard(
          'Valeur totale',
          '${NumberFormat.currency(locale: 'fr', symbol: '€').format(totalValue)}',
          const Color(0xFF1784af),
          Icons.euro,
        )),
      ],
    );
  }

  Widget _buildStatCard(String title, dynamic value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsList() {
    return ListView.builder(
      itemCount: _filteredActions.length,
      itemBuilder: (context, index) {
        final action = _filteredActions[index];
        return _buildActionCard(action);
      },
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    final dueDate = DateTime.parse(action['due_date']);
    final isOverdue = dueDate.isBefore(DateTime.now());
    final statusColor = _getStatusColor(action['status']);
    final priorityColor = _getPriorityColor(action['priority']);
    final typeIcon = _getTypeIcon(action['type']);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(typeIcon, color: const Color(0xFF1784af), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    action['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3D54),
                    ),
                  ),
                ),
                _buildStatusChip(action['status'], statusColor),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleActionMenu(action, value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    const PopupMenuItem(value: 'complete', child: Text('Marquer comme terminée')),
                    const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              action['description'],
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildPriorityChip(action['priority'], priorityColor),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOverdue ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(dueDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (action['estimated_value'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1784af).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      NumberFormat.currency(locale: 'fr', symbol: '€').format(action['estimated_value']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1784af),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildClientInfo(action),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo(Map<String, dynamic> action) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                action['client_name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3D54),
                ),
              ),
            ],
          ),
          if (action['contact_person'] != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(action['contact_person']),
                if (action['contact_email'] != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(action['contact_email']),
                ],
              ],
            ),
          ],
          if (action['notes'] != null) ...[
            const SizedBox(height: 8),
            Text(
              action['notes'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _getStatusLabel(status),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        _getPriorityLabel(priority),
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleActionMenu(Map<String, dynamic> action, String menuValue) {
    switch (menuValue) {
      case 'edit':
        _showEditActionDialog(action);
        break;
      case 'complete':
        _markAsCompleted(action);
        break;
      case 'delete':
        _deleteAction(action);
        break;
    }
  }

  void _showCreateActionDialog() {
    // Utiliser le StandardDialogs pour créer une action
    dialogs.StandardDialogs.showFormDialog(
      context: context,
      title: 'Nouvelle Action Commerciale',
      fields: [
        const dialogs.FormField(
          key: 'title',
          label: 'Titre',
          type: dialogs.FormFieldType.text,
          required: true,
        ),
        const dialogs.FormField(
          key: 'description',
          label: 'Description',
          type: dialogs.FormFieldType.text,
        ),
        dialogs.FormField(
          key: 'type',
          label: 'Type',
          type: dialogs.FormFieldType.dropdown,
          required: true,
          options: const [
            dialogs.SelectionItem(value: 'call', label: 'Appel téléphonique'),
            dialogs.SelectionItem(value: 'email', label: 'Email'),
            dialogs.SelectionItem(value: 'meeting', label: 'Réunion'),
            dialogs.SelectionItem(value: 'follow_up', label: 'Suivi'),
          ],
        ),
        dialogs.FormField(
          key: 'priority',
          label: 'Priorité',
          type: dialogs.FormFieldType.dropdown,
          required: true,
          options: const [
            dialogs.SelectionItem(value: 'low', label: 'Basse'),
            dialogs.SelectionItem(value: 'medium', label: 'Moyenne'),
            dialogs.SelectionItem(value: 'high', label: 'Haute'),
            dialogs.SelectionItem(value: 'urgent', label: 'Urgente'),
          ],
        ),
        const dialogs.FormField(
          key: 'client_name',
          label: 'Nom du client',
          type: dialogs.FormFieldType.text,
          required: true,
        ),
        const dialogs.FormField(
          key: 'contact_person',
          label: 'Personne de contact',
          type: dialogs.FormFieldType.text,
        ),
        const dialogs.FormField(
          key: 'contact_email',
          label: 'Email de contact',
          type: dialogs.FormFieldType.email,
        ),
        dialogs.FormField(
          key: 'due_date',
          label: 'Date d\'échéance',
          type: dialogs.FormFieldType.date,
          required: true,
          context: context,
        ),
      ],
    ).then((result) {
      if (result != null) {
        // Ici, on ajouterait normalement l'action à la base de données
        context.showSuccess('Action commerciale créée avec succès');
        _loadActions(); // Recharger les données
      }
    });
  }

  void _showEditActionDialog(Map<String, dynamic> action) {
    // Implémenter l'édition
    context.showInfo('Fonctionnalité d\'édition en cours de développement');
  }

  void _markAsCompleted(Map<String, dynamic> action) {
    context.showConfirm(
      'Marquer comme terminée',
      'Êtes-vous sûr de vouloir marquer cette action comme terminée ?',
    ).then((confirmed) {
      if (confirmed == true) {
        // Ici, on mettrait à jour le statut dans la base de données
        context.showSuccess('Action marquée comme terminée');
        _loadActions();
      }
    });
  }

  void _deleteAction(Map<String, dynamic> action) {
    context.showDelete(
      action['title'],
      itemType: 'action commerciale',
    ).then((confirmed) {
      if (confirmed == true) {
        // Ici, on supprimerait l'action de la base de données
        context.showSuccess('Action supprimée avec succès');
        _loadActions();
      }
    });
  }

  // Méthodes utilitaires
  Color _getStatusColor(String status) {
    switch (status) {
      case 'planned': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.blue;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'planned': return 'Planifiée';
      case 'in_progress': return 'En cours';
      case 'completed': return 'Terminée';
      case 'cancelled': return 'Annulée';
      default: return status;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'urgent': return 'URGENT';
      case 'high': return 'Haute';
      case 'medium': return 'Moyenne';
      case 'low': return 'Basse';
      default: return priority;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'call': return Icons.phone;
      case 'email': return Icons.email;
      case 'meeting': return Icons.meeting_room;
      case 'follow_up': return Icons.follow_the_signs;
      default: return Icons.business_center;
    }
  }
}