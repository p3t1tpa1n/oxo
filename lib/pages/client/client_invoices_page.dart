import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/invoice_service.dart';
import '../../widgets/load_error_view.dart';
import '../../services/company_service.dart';

class ClientInvoicesPage extends StatefulWidget {
  const ClientInvoicesPage({super.key});

  @override
  State<ClientInvoicesPage> createState() => _ClientInvoicesPageState();
}

class _ClientInvoicesPageState extends State<ClientInvoicesPage> {
  bool _isLoading = true;
  bool _loadError = false;
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
      final userCompany = await CompanyService.getUserCompany();
      
      // Charger les factures
      final invoicesData = await InvoiceService.getClientInvoices();
      
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
        _loadError = false;
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des factures: $e');
      if (mounted) {
        setState(() {
          _invoices = [];
          _isLoading = false;
          _loadError = true;
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
      backgroundColor: AppTheme.colors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _loadError
                ? LoadErrorView(
                    message: 'Impossible de charger les factures.',
                    onRetry: _loadData,
                  )
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
        heroTag: 'fab_client_invoices',
        backgroundColor: AppTheme.colors.secondary,
        elevation: 1,
        onPressed: () => Navigator.of(context).pushNamed('/messaging'),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      color: AppTheme.colors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Marque, alignée sur la sidebar principale de l'app
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.colors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'OX',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'OXO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 16, 6),
            child: Text(
              'ESPACE CLIENT',
              style: TextStyle(
                color: Colors.white.withAlpha(102),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
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
          // Carte utilisateur + déconnexion
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 15,
                    backgroundColor: AppTheme.colors.secondaryLight,
                    child: Text(
                      (_clientInfo?['name'] ?? 'E')
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _clientInfo?['name'] ?? 'Entreprise',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Client',
                          style: TextStyle(
                            color: Colors.white.withAlpha(153),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await SupabaseService.signOut();
                      if (mounted) {
                        Navigator.of(context)
                            .pushReplacementNamed('/login');
                      }
                    },
                    icon: Icon(
                      Icons.logout,
                      color: Colors.white.withAlpha(191),
                      size: 18,
                    ),
                    tooltip: 'Déconnexion',
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white.withAlpha(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color:
                  isSelected ? Colors.white.withAlpha(31) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.colors.sidebarAccent
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon,
                    color: Colors.white.withAlpha(isSelected ? 255 : 191),
                    size: 19),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withAlpha(isSelected ? 255 : 204),
                      fontSize: 13.5,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final formattedDate =
        DateFormat('d MMMM yyyy', 'fr_FR').format(DateTime.now());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mes factures', style: AppTheme.typography.h2),
              const SizedBox(height: 4),
              Text(
                '${_clientInfo?['name'] ?? 'Entreprise'} — $formattedDate',
                style: AppTheme.typography.bodySmall,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pushNamed('/profile'),
          icon: Icon(Icons.person_outline, color: AppTheme.colors.primary),
          tooltip: 'Profil',
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
            color: Color(0xFF16283C),
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
                color: AppTheme.colors.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                value: '${_pendingAmount.toStringAsFixed(2)} €',
                label: 'En attente',
                icon: Icons.hourglass_empty_outlined,
                color: AppTheme.colors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                value: '${_paidAmount.toStringAsFixed(2)} €',
                label: 'Payé',
                icon: Icons.check_circle_outline,
                color: AppTheme.colors.success,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppTheme.radius.small),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
                color: Color(0xFF16283C),
              ),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF16283C),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radius.medium),
            border: Border.all(color: AppTheme.colors.border, width: 0.5),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        border: Border.all(color: AppTheme.colors.borderLight, width: 0.5),
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
                    color: Color(0xFF16283C),
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
                  color: Color(0xFF16283C),
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
        return AppTheme.colors.success;
      case 'pending':
        return AppTheme.colors.warning;
      case 'overdue':
        return AppTheme.colors.error;
      default:
        return AppTheme.colors.statusCancelled;
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
        backgroundColor: const Color(0xFF3E5C76),
      ),
    );
  }
}
