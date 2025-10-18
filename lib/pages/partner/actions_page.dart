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
      // Charger les vraies actions commerciales depuis Supabase
      final actions = await SupabaseService.getCommercialActions();
      
      setState(() {
        _actions = actions;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des actions commerciales: $e';
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
            dialogs.SelectionItem(value: 'proposal', label: 'Proposition'),
            dialogs.SelectionItem(value: 'negotiation', label: 'Négociation'),
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
        const dialogs.FormField(
          key: 'contact_phone',
          label: 'Téléphone de contact',
          type: dialogs.FormFieldType.text,
        ),
        const dialogs.FormField(
          key: 'estimated_value',
          label: 'Valeur estimée (€)',
          type: dialogs.FormFieldType.text,
        ),
        dialogs.FormField(
          key: 'due_date',
          label: 'Date d\'échéance',
          type: dialogs.FormFieldType.date,
          required: true,
          context: context,
        ),
        const dialogs.FormField(
          key: 'notes',
          label: 'Notes',
          type: dialogs.FormFieldType.text,
        ),
      ],
    ).then((result) async {
      if (result != null) {
        try {
          // Convertir la valeur estimée en double si fournie
          double? estimatedValue;
          if (result['estimated_value'] != null && result['estimated_value'].toString().isNotEmpty) {
            estimatedValue = double.tryParse(result['estimated_value'].toString().replaceAll(',', '.'));
          }

          // Convertir la date d'échéance
          DateTime? dueDate;
          if (result['due_date'] != null) {
            dueDate = DateTime.tryParse(result['due_date'].toString());
          }

          // Créer l'action commerciale dans Supabase
          final action = await SupabaseService.createCommercialAction(
            title: result['title'],
            description: result['description'] ?? '',
            type: result['type'],
            clientName: result['client_name'],
            priority: result['priority'],
            contactPerson: result['contact_person'],
            contactEmail: result['contact_email'],
            contactPhone: result['contact_phone'],
            estimatedValue: estimatedValue,
            dueDate: dueDate,
            notes: result['notes'],
          );

          if (action != null) {
            if (mounted) {
              context.showSuccess('Action commerciale créée avec succès');
              _loadActions(); // Recharger les données
            }
          } else {
            if (mounted) {
              context.showError('Erreur lors de la création de l\'action commerciale');
            }
          }
        } catch (e) {
          if (mounted) {
            context.showError('Erreur lors de la création: $e');
          }
        }
      }
    });
  }

  void _showEditActionDialog(Map<String, dynamic> action) {
    // Préparer les valeurs par défaut avec les données de l'action existante
    final initialValues = {
      'title': action['title'],
      'description': action['description'],
      'type': action['type'],
      'priority': action['priority'],
      'client_name': action['client_name'],
      'contact_person': action['contact_person'],
      'contact_email': action['contact_email'],
      'contact_phone': action['contact_phone'],
      'estimated_value': action['estimated_value']?.toString(),
      'due_date': action['due_date'],
      'notes': action['notes'],
    };

    dialogs.StandardDialogs.showFormDialog(
      context: context,
      title: 'Modifier l\'Action Commerciale',
      initialValues: initialValues,
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
            dialogs.SelectionItem(value: 'proposal', label: 'Proposition'),
            dialogs.SelectionItem(value: 'negotiation', label: 'Négociation'),
          ],
        ),
        dialogs.FormField(
          key: 'status',
          label: 'Statut',
          type: dialogs.FormFieldType.dropdown,
          required: true,
          options: const [
            dialogs.SelectionItem(value: 'planned', label: 'Planifiée'),
            dialogs.SelectionItem(value: 'in_progress', label: 'En cours'),
            dialogs.SelectionItem(value: 'completed', label: 'Terminée'),
            dialogs.SelectionItem(value: 'cancelled', label: 'Annulée'),
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
        const dialogs.FormField(
          key: 'contact_phone',
          label: 'Téléphone de contact',
          type: dialogs.FormFieldType.text,
        ),
        const dialogs.FormField(
          key: 'estimated_value',
          label: 'Valeur estimée (€)',
          type: dialogs.FormFieldType.text,
        ),
        dialogs.FormField(
          key: 'due_date',
          label: 'Date d\'échéance',
          type: dialogs.FormFieldType.date,
          required: true,
          context: context,
        ),
        const dialogs.FormField(
          key: 'notes',
          label: 'Notes',
          type: dialogs.FormFieldType.text,
        ),
      ],
    ).then((result) async {
      if (result != null) {
        try {
          // Convertir la valeur estimée en double si fournie
          double? estimatedValue;
          if (result['estimated_value'] != null && result['estimated_value'].toString().isNotEmpty) {
            estimatedValue = double.tryParse(result['estimated_value'].toString().replaceAll(',', '.'));
          }

          // Convertir la date d'échéance
          DateTime? dueDate;
          if (result['due_date'] != null) {
            dueDate = DateTime.tryParse(result['due_date'].toString());
          }

          // Mettre à jour l'action commerciale dans Supabase
          final success = await SupabaseService.updateCommercialAction(
            actionId: action['id'],
            title: result['title'],
            description: result['description'],
            type: result['type'],
            status: result['status'],
            priority: result['priority'],
            clientName: result['client_name'],
            contactPerson: result['contact_person'],
            contactEmail: result['contact_email'],
            contactPhone: result['contact_phone'],
            estimatedValue: estimatedValue,
            dueDate: dueDate,
            notes: result['notes'],
          );

          if (success && mounted) {
            context.showSuccess('Action commerciale modifiée avec succès');
            _loadActions(); // Recharger les données
          } else if (mounted) {
            context.showError('Erreur lors de la modification de l\'action commerciale');
          }
        } catch (e) {
          if (mounted) {
            context.showError('Erreur lors de la modification: $e');
          }
        }
      }
    });
  }

  void _markAsCompleted(Map<String, dynamic> action) {
    context.showConfirm(
      'Marquer comme terminée',
      'Êtes-vous sûr de vouloir marquer cette action comme terminée ?',
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final success = await SupabaseService.completeCommercialAction(
            actionId: action['id'],
          );
          
          if (success && mounted) {
            context.showSuccess('Action marquée comme terminée');
            _loadActions();
          } else if (mounted) {
            context.showError('Erreur lors de la mise à jour de l\'action');
          }
        } catch (e) {
          if (mounted) {
            context.showError('Erreur lors de la mise à jour: $e');
          }
        }
      }
    });
  }

  void _deleteAction(Map<String, dynamic> action) {
    context.showDelete(
      action['title'],
      itemType: 'action commerciale',
    ).then((confirmed) async {
      if (confirmed == true) {
        try {
          final success = await SupabaseService.deleteCommercialAction(action['id']);
          
          if (success && mounted) {
            context.showSuccess('Action supprimée avec succès');
            _loadActions();
          } else if (mounted) {
            context.showError('Erreur lors de la suppression de l\'action');
          }
        } catch (e) {
          if (mounted) {
            context.showError('Erreur lors de la suppression: $e');
          }
        }
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