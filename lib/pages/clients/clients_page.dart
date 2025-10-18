import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'tous';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les clients et projets en parallèle
      final futures = await Future.wait([
        SupabaseService.fetchClients(),
        SupabaseService.getCompanyProjects(),
      ]);
      
      setState(() {
        _clients = futures[0];
        _projects = futures[1];
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final searchTerm = _searchController.text.toLowerCase();
    
    List<Map<String, dynamic>> filtered = _clients;
    
    // Filtre par statut (adapter selon les données profiles)
    // Note: Les profiles n'ont pas forcément de statut, on peut filtrer par entreprise ou autre
    
    // Filtre par recherche
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((client) {
        final name = '${client['first_name'] ?? ''} ${client['last_name'] ?? ''}'.toLowerCase();
        final email = (client['email'] ?? '').toLowerCase();
        final company = (client['company_name'] ?? '').toLowerCase();
        
        return name.contains(searchTerm) ||
               email.contains(searchTerm) ||
               company.contains(searchTerm);
      }).toList();
    }
    
    setState(() {
      _filteredClients = filtered;
    });
  }

  void _showClientForm({Map<String, dynamic>? client}) {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(text: client?['first_name'] ?? '');
    final lastNameController = TextEditingController(text: client?['last_name'] ?? '');
    final emailController = TextEditingController(text: client?['email'] ?? '');
    final phoneController = TextEditingController(text: client?['phone'] ?? '');
    final companyController = TextEditingController(text: client?['company_name'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client == null ? 'Ajouter un client' : 'Modifier le client'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'Prénom *',
                          icon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Prénom requis';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom *',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nom requis';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    icon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email requis';
                    }
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    icon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: companyController,
                  decoration: const InputDecoration(
                    labelText: 'Entreprise',
                    icon: Icon(Icons.business),
                  ),
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
                // Note: Pour créer un nouveau client, on devrait créer un nouvel utilisateur
                // Ceci est un placeholder - en réalité il faudrait implémenter la création d'utilisateur
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fonctionnalité en cours de développement'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3D54),
              foregroundColor: Colors.white,
            ),
            child: Text(client == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClient(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le client'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${client['first_name']} ${client['last_name']} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Suppression non autorisée - contactez l\'administrateur'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _viewClientDetails(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${client['first_name']} ${client['last_name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (client['company_name'] != null && client['company_name'].isNotEmpty)
              _buildDetailRow('Entreprise', client['company_name']),
            if (client['email'] != null && client['email'].isNotEmpty)
              _buildDetailRow('Email', client['email']),
            if (client['phone'] != null && client['phone'].isNotEmpty)
              _buildDetailRow('Téléphone', client['phone']),
            _buildDetailRow('Rôle', client['role'] ?? 'Client'),
            if (client['status'] != null)
              _buildDetailRow('Statut', client['status']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showInvoiceForm(client);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3D54),
              foregroundColor: Colors.white,
            ),
            child: const Text('Créer une facture'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showInvoiceForm(Map<String, dynamic> client) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final taxRateController = TextEditingController(text: '20.00');
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));
    DateTime invoiceDate = DateTime.now();
    String status = 'draft';
    String? selectedProjectId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Créer une facture pour ${client['first_name']} ${client['last_name']}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Titre de la facture *',
                      icon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez saisir un titre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      icon: Icon(Icons.description),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: selectedProjectId,
                    decoration: const InputDecoration(
                      labelText: 'Projet (optionnel)',
                      icon: Icon(Icons.folder),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Aucun projet'),
                      ),
                      ..._projects.map((project) => DropdownMenuItem<String?>(
                        value: project['id'].toString(),
                        child: Text(project['name'] ?? 'Projet sans nom'),
                      )),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        selectedProjectId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: amountController,
                          decoration: const InputDecoration(
                            labelText: 'Montant HT (€) *',
                            icon: Icon(Icons.euro),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Montant requis';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null || amount <= 0) {
                              return 'Montant invalide';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: taxRateController,
                          decoration: const InputDecoration(
                            labelText: 'TVA (%)',
                            icon: Icon(Icons.percent),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: invoiceDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                invoiceDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Date facture', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(DateFormat('dd/MM/yyyy').format(invoiceDate)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: dueDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                dueDate = picked;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule, size: 20),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Date échéance', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                    Text(DateFormat('dd/MM/yyyy').format(dueDate)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      icon: Icon(Icons.flag),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'draft', child: Text('Brouillon')),
                      DropdownMenuItem(value: 'sent', child: Text('Envoyée')),
                      DropdownMenuItem(value: 'pending', child: Text('En attente de paiement')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        status = value!;
                      });
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
                  try {
                    final amount = double.parse(amountController.text);
                    final taxRate = double.tryParse(taxRateController.text) ?? 20.0;
                    
                    await SupabaseService.createInvoice(
                      clientUserId: client['user_id'],
                      title: titleController.text,
                      description: descriptionController.text,
                      amount: amount,
                      dueDate: dueDate,
                      projectId: selectedProjectId,
                      taxRate: taxRate,
                      invoiceDate: invoiceDate,
                      status: status,
                    );
                    
                    if (mounted) {
                      Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Facture créée avec succès !'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur lors de la création de la facture: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3D54),
                foregroundColor: Colors.white,
              ),
              child: const Text('Créer la facture'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.of(context).pushNamed('/create-client'),
            tooltip: 'Créer un nouveau client',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun client trouvé',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : _buildClientsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClientForm(),
        backgroundColor: const Color(0xFF1E3D54),
        tooltip: 'Ajouter un client',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un client...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
            ),
            onChanged: (_) => _applyFilters(),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tous', 'tous'),
                const SizedBox(width: 8),
                _buildFilterChip('Actifs', 'actif'),
                const SizedBox(width: 8),
                _buildFilterChip('Inactifs', 'inactif'),
                const SizedBox(width: 8),
                _buildFilterChip('Prospects', 'prospect'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = selected ? value : 'tous';
          _applyFilters();
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF1E3D54).withOpacity(0.2),
      checkmarkColor: const Color(0xFF1E3D54),
      side: BorderSide(
        color: isSelected 
          ? const Color(0xFF1E3D54)
          : Colors.grey.shade300,
      ),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF1E3D54) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildClientsList() {
    return ListView.builder(
      itemCount: _filteredClients.length,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: (client['status'] == 'actif' || client['status'] == null)
                  ? Colors.green.withOpacity(0.3)
                  : client['status'] == 'prospect'
                      ? Colors.blue.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _viewClientDetails(client),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${client['first_name'] ?? ''} ${client['last_name'] ?? ''}'.trim(),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3D54),
                              ),
                            ),
                            if (client['company_name'] != null && client['company_name'].isNotEmpty)
                              Text(
                                client['company_name'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(client['status'] ?? 'actif'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (client['email'] != null && client['email'].isNotEmpty) ...[
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(child: Text(client['email'], style: const TextStyle(fontSize: 14))),
                        const SizedBox(width: 16),
                      ],
                      if (client['phone'] != null && client['phone'].isNotEmpty) ...[
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(client['phone'], style: const TextStyle(fontSize: 14)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Color(0xFF1E3D54)),
                        onPressed: () => _showClientForm(client: client),
                        tooltip: 'Modifier',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      IconButton(
                        icon: const Icon(Icons.receipt, color: Color(0xFF1E3D54)),
                        onPressed: () => _showInvoiceForm(client),
                        tooltip: 'Créer une facture',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteClient(client),
                        tooltip: 'Supprimer',
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    
    switch (status) {
      case 'actif':
        color = Colors.green;
        label = 'Actif';
        break;
      case 'inactif':
        color = Colors.grey;
        label = 'Inactif';
        break;
      case 'prospect':
        color = Colors.blue;
        label = 'Prospect';
        break;
      default:
        color = Colors.green;
        label = 'Actif';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
} 