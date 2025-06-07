import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/client.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import 'client_detail_page.dart';
import 'package:uuid/uuid.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'tous';

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clientsData = await SupabaseService.fetchClients();
      final clients = clientsData.map((data) => Client.fromJson(data)).toList();
      
      setState(() {
        _clients = clients;
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
            content: Text('Erreur lors du chargement des clients: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _applyFilters() {
    final searchTerm = _searchController.text.toLowerCase();
    
    List<Client> filtered = _clients;
    
    // Filtre par statut
    if (_filterStatus != 'tous') {
      filtered = filtered.where((client) => client.status == _filterStatus).toList();
    }
    
    // Filtre par recherche
    if (searchTerm.isNotEmpty) {
      filtered = filtered.where((client) => 
        client.name.toLowerCase().contains(searchTerm) ||
        client.company.toLowerCase().contains(searchTerm) ||
        client.email.toLowerCase().contains(searchTerm)
      ).toList();
    }
    
    setState(() {
      _filteredClients = filtered;
    });
  }

  void _showClientForm({Client? client}) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: client?.name ?? '');
    final emailController = TextEditingController(text: client?.email ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final addressController = TextEditingController(text: client?.address ?? '');
    final companyController = TextEditingController(text: client?.company ?? '');
    final notesController = TextEditingController(text: client?.notes ?? '');
    String status = client?.status ?? 'actif';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client == null ? 'Ajouter un client' : 'Modifier le client'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom',
                    icon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez saisir un nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: companyController,
                  decoration: const InputDecoration(
                    labelText: 'Entreprise',
                    icon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    icon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value)) {
                        return 'Veuillez saisir un email valide';
                      }
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    icon: Icon(Icons.location_on),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(
                    labelText: 'Statut',
                    icon: Icon(Icons.flag),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'actif', child: Text('Actif')),
                    DropdownMenuItem(value: 'inactif', child: Text('Inactif')),
                    DropdownMenuItem(value: 'prospect', child: Text('Prospect')),
                  ],
                  onChanged: (value) {
                    status = value!;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    icon: Icon(Icons.note),
                  ),
                  maxLines: 3,
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
              if (_formKey.currentState!.validate()) {
                try {
                  final clientData = {
                    'name': nameController.text,
                    'email': emailController.text,
                    'phone': phoneController.text,
                    'address': addressController.text,
                    'company': companyController.text,
                    'notes': notesController.text,
                    'status': status,
                  };
                  
                  if (client == null) {
                    // Ajouter un nouveau client
                    clientData['id'] = const Uuid().v4();
                    clientData['created_at'] = DateTime.now().toIso8601String();
                    
                    await SupabaseService.insertClient(clientData);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Client ajouté avec succès')),
                      );
                    }
                  } else {
                    // Mettre à jour le client existant
                    await SupabaseService.updateClient(client.id, clientData);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Client mis à jour avec succès')),
                      );
                    }
                  }
                  
                  if (mounted) {
                    Navigator.pop(context);
                    _loadClients();
                  }
                } catch (e) {
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
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3D54),
            ),
            child: Text(client == null ? 'Ajouter' : 'Mettre à jour'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteClient(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le client'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${client.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await SupabaseService.deleteClient(client.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client supprimé avec succès')),
                  );
                  _loadClients();
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur lors de la suppression: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _viewClientDetails(Client client) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClientDetailPage(client: client),
      ),
    ).then((_) => _loadClients());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Clients'),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? const Center(child: Text('Aucun client trouvé'))
                    : _buildClientsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showClientForm(),
        backgroundColor: const Color(0xFF1E3D54),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
              color: client.status == 'actif'
                  ? Colors.green.withOpacity(0.3)
                  : client.status == 'prospect'
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
                              client.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3D54),
                              ),
                            ),
                            if (client.company.isNotEmpty)
                              Text(
                                client.company,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(client.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (client.email.isNotEmpty) ...[
                        const Icon(Icons.email, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(client.email, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 16),
                      ],
                      if (client.phone.isNotEmpty) ...[
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(client.phone, style: const TextStyle(fontSize: 14)),
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
        color = Colors.grey;
        label = 'Inconnu';
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