import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

class ClientDetailPage extends StatefulWidget {
  final Client client;

  const ClientDetailPage({super.key, required this.client});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  late Client _client;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _refreshClientData();
  }

  Future<void> _refreshClientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clientData = await SupabaseService.getClientById(_client.id);
      if (clientData != null) {
        setState(() {
          _client = Client.fromJson(clientData);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Détails du client',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildClientHeader(),
                  const SizedBox(height: 24),
                  _buildContactInfo(),
                  const SizedBox(height: 24),
                  _buildClientNotes(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildClientHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF1E3D54),
              child: Text(
                _client.name.isNotEmpty ? _client.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _client.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3D54),
                    ),
                  ),
                  if (_client.company.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _client.company,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _buildStatusBadge(_client.status),
                  const SizedBox(height: 8),
                  Text(
                    'Client depuis ${_formatDate(_client.createdAt)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Coordonnées',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3D54),
              ),
            ),
            const SizedBox(height: 16),
            if (_client.email.isNotEmpty)
              _buildInfoRow(Icons.email, 'Email', _client.email),
            if (_client.phone.isNotEmpty)
              _buildInfoRow(Icons.phone, 'Téléphone', _client.phone),
            if (_client.address.isNotEmpty)
              _buildInfoRow(Icons.location_on, 'Adresse', _client.address),
          ],
        ),
      ),
    );
  }

  Widget _buildClientNotes() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3D54),
              ),
            ),
            const SizedBox(height: 12),
            _client.notes.isNotEmpty
                ? Text(
                    _client.notes,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                    ),
                  )
                : Text(
                    'Aucune note disponible',
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.phone,
          label: 'Appeler',
          onPressed: _client.phone.isNotEmpty ? () {} : null,
          color: Colors.green,
        ),
        _buildActionButton(
          icon: Icons.email,
          label: 'Email',
          onPressed: _client.email.isNotEmpty ? () {} : null,
          color: Colors.blue,
        ),
        _buildActionButton(
          icon: Icons.calendar_today,
          label: 'RDV',
          onPressed: () {},
          color: const Color(0xFF1E3D54),
        ),
        _buildActionButton(
          icon: Icons.edit_note,
          label: 'Modifier',
          onPressed: () {
            Navigator.pop(context);
          },
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
} 