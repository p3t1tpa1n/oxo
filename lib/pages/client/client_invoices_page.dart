import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class ClientInvoicesPage extends StatefulWidget {
  const ClientInvoicesPage({super.key});

  @override
  State<ClientInvoicesPage> createState() => _ClientInvoicesPageState();
}

class _ClientInvoicesPageState extends State<ClientInvoicesPage> {
  bool _isLoading = true;
  String _selectedMenu = 'invoices';
  List<Map<String, dynamic>> _invoices = [];
  Map<String, dynamic>? _clientInfo;

  double _totalBilled = 0.0;
  double _pendingAmount = 0.0;
  double _paidAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Charger les informations de l'entreprise
      final userCompany = await SupabaseService.getUserCompany();
      
      // Charger les factures
      final invoicesData = await SupabaseService.getClientInvoices();
      
      final invoices = invoicesData.map((data) {
        final amount = (data['total_amount'] ?? data['amount'] ?? 0).toDouble();
        final status = _mapStatus(data['status']);
        return {
          'id': data['invoice_number'] ?? 'INV-${data['id']}',
          'date': DateTime.parse(data['invoice_date']),
          'due_date': DateTime.parse(data['due_date']),
          'amount': amount,
          'status': status,
          'description': data['title'] ?? 'Facture sans titre',
          'mission_name': data['mission_name'] ?? 'Mission non spécifiée',
          'invoice_id': data['id'],
        };
      }).toList();

      // Calculer les totaux
      double total = 0.0;
      double pending = 0.0;
      double paid = 0.0;

      for (var invoice in invoices) {
        final amount = invoice['amount'] as double;
        final status = invoice['status'] as String;
        total += amount;
        if (status == 'pending') {
          pending += amount;
        } else if (status == 'paid') {
          paid += amount;
        }
      }

      if (!mounted) return;
      setState(() {
        _clientInfo = {
          'name': userCompany?['company_name'] ?? 'Entreprise',
          'id': userCompany?['company_id'],
        };
        _invoices = invoices;
        _totalBilled = total;
        _pendingAmount = pending;
        _paidAmount = paid;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des factures: $e');
      if (mounted) {
        setState(() {
          _invoices = [];
          _isLoading = false;
        });
      }
    }
  }

  String _mapStatus(String? dbStatus) {
    switch (dbStatus) {
      case 'paid':
        return 'paid';
      case 'pending':
        return 'pending';
      case 'overdue':
        return 'overdue';
      case 'sent':
        return 'pending';
      case 'draft':
        return 'draft';
      case 'cancelled':
        return 'cancelled';
      default:
        return 'draft';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FA),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSidebar(),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(),
                            const SizedBox(height: 32),
                            _buildBillingSummary(),
                            const SizedBox(height: 32),
                            _buildInvoiceHistory(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E3D54),
        onPressed: () => Navigator.of(context).pushNamed('/messaging'),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF1E3D54),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Espace Client',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSidebarItem(
            icon: Icons.dashboard_outlined,
            label: 'Tableau de bord',
            isSelected: _selectedMenu == 'dashboard',
            onTap: () {
              setState(() => _selectedMenu = 'dashboard');
              Navigator.of(context).pushReplacementNamed('/client_dashboard');
            },
          ),
          _buildSidebarItem(
            icon: Icons.receipt_long_outlined,
            label: 'Factures',
            isSelected: _selectedMenu == 'invoices',
            onTap: () => setState(() => _selectedMenu = 'invoices'),
          ),
          _buildSidebarItem(
            icon: Icons.person_outline,
            label: 'Profil',
            isSelected: _selectedMenu == 'profile',
            onTap: () {
              setState(() => _selectedMenu = 'profile');
              Navigator.of(context).pushNamed('/profile');
            },
          ),
          _buildSidebarItem(
            icon: Icons.chat_bubble_outline,
            label: 'Messages',
            isSelected: _selectedMenu == 'messages',
            onTap: () {
              setState(() => _selectedMenu = 'messages');
              Navigator.of(context).pushNamed('/messaging');
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () async {
                await SupabaseService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              icon: const Icon(Icons.logout, size: 18, color: Colors.white70),
              label: const Text(
                'Déconnexion',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final formattedDate = DateFormat('d MMMM yyyy', 'fr_FR').format(DateTime.now());
    final firstLetter = (_clientInfo?['name'] ?? 'E').substring(0, 1).toUpperCase();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cercle avec initiale
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: Color(0xFF1E3D54),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              firstLetter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mes Factures',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3D54),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Facturation - $formattedDate',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        // Icônes en haut à droite
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/dashboard'),
          icon: const Icon(Icons.home_outlined, color: Color(0xFF1E3D54)),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/profile'),
          icon: const Icon(Icons.settings_outlined, color: Color(0xFF1E3D54)),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/profile'),
          icon: const Icon(Icons.person_outline, color: Color(0xFF1E3D54)),
        ),
      ],
    );
  }

  Widget _buildBillingSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Résumé de facturation',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E3D54),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                value: '${_totalBilled.toStringAsFixed(2)} €',
                label: 'Total facturé',
                icon: Icons.receipt_long_outlined,
                color: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                value: '${_pendingAmount.toStringAsFixed(2)} €',
                label: 'En attente',
                icon: Icons.hourglass_empty_outlined,
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSummaryCard(
                value: '${_paidAmount.toStringAsFixed(2)} €',
                label: 'Payé',
                icon: Icons.check_circle_outline,
                color: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E3D54),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Historique des factures',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3D54),
              ),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3D54),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: _downloadAllInvoices,
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Télécharger tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _invoices.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Aucune facture disponible',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _invoices.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) => _buildInvoiceCard(_invoices[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final date = invoice['date'] as DateTime;
    final amount = invoice['amount'] as double;
    final status = invoice['status'] as String;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice['id'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E3D54),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  invoice['mission_name'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Émise le ${DateFormat('dd/MM/yyyy').format(date)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${amount.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3D54),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusText(status),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return const Color(0xFF10B981);
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'overdue':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Payé';
      case 'pending':
        return 'En attente';
      case 'overdue':
        return 'En retard';
      default:
        return 'Brouillon';
    }
  }

  void _downloadAllInvoices() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Téléchargement de toutes les factures en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
