// lib/pages/partner/partners_page.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

class PartnersPage extends StatefulWidget {
  const PartnersPage({super.key});

  @override
  State<PartnersPage> createState() => _PartnersPageState();
}

class _PartnersPageState extends State<PartnersPage> {
  List<Map<String, dynamic>> _partners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    try {
      final partners = await SupabaseService.getPartners();
      if (mounted) {
        setState(() {
          _partners = partners;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des partenaires: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Partenaires',
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _partners.isEmpty
              ? const Center(child: Text('Aucun partenaire trouvé'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _partners.length,
                  itemBuilder: (context, index) {
                    final partner = _partners[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF1784af),
                          child: Text(
                            '${partner['first_name']?[0] ?? ''}${partner['last_name']?[0] ?? ''}'.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          '${partner['first_name'] ?? ''} ${partner['last_name'] ?? ''}'.trim(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(partner['email'] ?? ''),
                            if (partner['phone'] != null) ...[
                              const SizedBox(height: 4),
                              Text(partner['phone']),
                            ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.message),
                          onPressed: () {
                            // TODO: Implémenter la messagerie avec le partenaire
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Messagerie en cours de développement')),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}