import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_role.dart';
import '../../services/supabase_service.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';
import '../../widgets/messaging_button.dart';

class ClientInvoicesPage extends StatefulWidget {
  const ClientInvoicesPage({super.key});

  @override
  State<ClientInvoicesPage> createState() => _ClientInvoicesPageState();
}

class _ClientInvoicesPageState extends State<ClientInvoicesPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _invoices = [];

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Récupérer les vraies factures depuis Supabase
      final invoicesData = await SupabaseService.getClientInvoices();
      
      // Convertir les données pour l'affichage
      final invoices = invoicesData.map((data) => {
        'id': data['invoice_number'] ?? 'INV-${data['id']}',
        'date': DateTime.parse(data['invoice_date']),
        'due_date': DateTime.parse(data['due_date']),
        'amount': (data['total_amount'] ?? data['amount']).toDouble(),
        'status': _mapStatus(data['status']),
        'description': data['title'] ?? 'Facture sans titre',
        'project_name': data['project_name'] ?? 'Projet non spécifié',
        'invoice_id': data['id'], // ID réel pour les actions
      }).toList();

      setState(() {
        _invoices = invoices;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des factures: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des factures: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // En cas d'erreur, afficher un message plus informatif
      setState(() {
        _invoices = [];
      });
    } finally {
      if (mounted) {
        setState(() {
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
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 1000,
            minHeight: 800,
          ),
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Expanded(child: TopBar(title: 'Mes Factures')),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (screenWidth > 700) 
                      SideMenu(
                        userRole: UserRole.client,
                        selectedRoute: '/client/invoices',
                      ),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildInvoicesContent(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const MessagingFloatingButton(),
    );
  }

  Widget _buildInvoicesContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildInvoicesList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final totalAmount = _invoices.fold<double>(0, (sum, invoice) => sum + invoice['amount']);
    final pendingAmount = _invoices
        .where((invoice) => invoice['status'] == 'pending')
        .fold<double>(0, (sum, invoice) => sum + invoice['amount']);
    final paidAmount = _invoices
        .where((invoice) => invoice['status'] == 'paid')
        .fold<double>(0, (sum, invoice) => sum + invoice['amount']);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé de facturation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3D54),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildSummaryCard(
                  'Total facturé',
                  '${totalAmount.toStringAsFixed(2)} €',
                  Icons.receipt_long,
                  Colors.blue,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'En attente',
                  '${pendingAmount.toStringAsFixed(2)} €',
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
                const SizedBox(width: 16),
                _buildSummaryCard(
                  'Payé',
                  '${paidAmount.toStringAsFixed(2)} €',
                  Icons.check_circle,
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoicesList() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Historique des factures',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3D54),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    _downloadAllInvoices();
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Télécharger tout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3D54),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_invoices.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'Aucune facture disponible',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _invoices.length,
                itemBuilder: (context, index) {
                  final invoice = _invoices[index];
                  return _buildInvoiceCard(invoice);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final date = invoice['date'] as DateTime;
    final dueDate = invoice['due_date'] as DateTime;
    final amount = invoice['amount'] as double;
    final status = invoice['status'] as String;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice['id'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3D54),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice['project_name'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    '${amount.toStringAsFixed(2)} €',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3D54),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(status).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            invoice['description'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Émise le ${DateFormat('dd/MM/yyyy').format(date)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Échéance ${DateFormat('dd/MM/yyyy').format(dueDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _isOverdue(dueDate, status) ? Colors.red : Colors.grey[600],
                      fontWeight: _isOverdue(dueDate, status) ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_red_eye, color: Color(0xFF1E3D54)),
                    onPressed: () => _viewInvoice(invoice),
                    tooltip: 'Voir la facture',
                  ),
                  IconButton(
                    icon: const Icon(Icons.download, color: Color(0xFF1E3D54)),
                    onPressed: () => _downloadInvoice(invoice),
                    tooltip: 'Télécharger',
                  ),
                  if (status == 'pending')
                    IconButton(
                      icon: const Icon(Icons.payment, color: Colors.green),
                      onPressed: () => _payInvoice(invoice),
                      tooltip: 'Payer en ligne',
                    ),
                ],
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
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'paid':
        return 'Payée';
      case 'pending':
        return 'En attente';
      case 'overdue':
        return 'En retard';
      case 'draft':
        return 'Brouillon';
      default:
        return status;
    }
  }

  bool _isOverdue(DateTime dueDate, String status) {
    return status == 'pending' && dueDate.isBefore(DateTime.now());
  }

  void _viewInvoice(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Facture ${invoice['id']}'),
        content: const Text('Fonctionnalité de visualisation en cours de développement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _downloadInvoice(Map<String, dynamic> invoice) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Téléchargement de la facture ${invoice['id']} en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _downloadAllInvoices() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Téléchargement de toutes les factures en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _payInvoice(Map<String, dynamic> invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Paiement - Facture ${invoice['id']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Montant à payer: ${invoice['amount'].toStringAsFixed(2)} €'),
            const SizedBox(height: 16),
            const Text('Choisissez votre mode de paiement:'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _processPayment(invoice, 'card');
              },
              icon: const Icon(Icons.credit_card),
              label: const Text('Carte bancaire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3D54),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _processPayment(invoice, 'bank_transfer');
              },
              icon: const Icon(Icons.account_balance),
              label: const Text('Virement bancaire'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _processPayment(Map<String, dynamic> invoice, String method) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Redirection vers le paiement sécurisé pour la facture ${invoice['id']}...'
        ),
        backgroundColor: Colors.green,
      ),
    );
  }
} 