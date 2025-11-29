// ============================================================================
// MOBILE CLIENT INVOICES TAB - OXO TIME SHEETS
// Tab Factures pour les Clients iOS
// Utilise STRICTEMENT AppTheme (pas IOSTheme)
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/device_detector.dart';

class MobileClientInvoicesTab extends StatefulWidget {
  const MobileClientInvoicesTab({Key? key}) : super(key: key);

  @override
  State<MobileClientInvoicesTab> createState() => _MobileClientInvoicesTabState();
}

class _MobileClientInvoicesTabState extends State<MobileClientInvoicesTab> {
  List<Map<String, dynamic>> _invoices = [];
  bool _isLoading = true;
  String _selectedFilter = 'tous';
  int _unreadCount = 0;
  
  // Stats
  double _totalPending = 0;
  double _totalPaid = 0;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await SupabaseService.getUnreadNotificationsCount();
      if (mounted) {
        setState(() => _unreadCount = count);
      }
    } catch (e) {
      debugPrint('Erreur chargement notifications: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Récupérer les factures du client
      final userCompany = await SupabaseService.getUserCompany();
      if (userCompany == null) throw Exception('Entreprise non trouvée');

      final response = await SupabaseService.client
          .from('invoices')
          .select()
          .eq('client_id', userCompany['company_id'])
          .order('created_at', ascending: false);

      final invoices = List<Map<String, dynamic>>.from(response);
      
      // Calculer les stats
      double pending = 0;
      double paid = 0;
      int pendingCount = 0;
      
      for (final invoice in invoices) {
        final amount = (invoice['amount'] ?? 0).toDouble();
        final status = invoice['status'] ?? '';
        
        if (status == 'paid') {
          paid += amount;
        } else {
          pending += amount;
          pendingCount++;
        }
      }

      setState(() {
        _invoices = invoices;
        _totalPending = pending;
        _totalPaid = paid;
        _pendingCount = pendingCount;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement factures: $e');
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredInvoices {
    if (_selectedFilter == 'tous') return _invoices;
    return _invoices.where((i) {
      final status = i['status'] ?? '';
      return status == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.colors.background,
      child: DefaultTextStyle(
        style: TextStyle(
          decoration: TextDecoration.none,
          color: AppTheme.colors.textPrimary,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildStatsCards(),
              _buildFilterButtons(),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CupertinoActivityIndicator(
                          color: AppTheme.colors.primary,
                        ),
                      )
                    : _filteredInvoices.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppTheme.colors.primary,
                            child: ListView.builder(
                              padding: EdgeInsets.all(AppTheme.spacing.md),
                              itemCount: _filteredInvoices.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: EdgeInsets.only(bottom: AppTheme.spacing.sm),
                                  child: _buildInvoiceCard(_filteredInvoices[index]),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.md,
        vertical: AppTheme.spacing.sm,
      ),
      color: AppTheme.colors.surface,
      child: Row(
        children: [
          Text(
            'Factures',
            style: AppTheme.typography.h1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.colors.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/messaging');
            },
            child: Stack(
              children: [
                Icon(
                  _getIconForPlatform(AppIcons.notifications, AppIcons.notificationsIOS),
                  color: AppTheme.colors.textPrimary,
                  size: 24,
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme.colors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/profile');
            },
            child: Icon(
              _getIconForPlatform(AppIcons.settings, AppIcons.settingsIOS),
              color: AppTheme.colors.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'En attente',
              formatter.format(_totalPending),
              '$_pendingCount factures',
              AppTheme.colors.warning,
              CupertinoIcons.clock,
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Expanded(
            child: _buildStatCard(
              'Payées',
              formatter.format(_totalPaid),
              '${_invoices.length - _pendingCount} factures',
              AppTheme.colors.success,
              CupertinoIcons.checkmark_circle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: AppTheme.spacing.xs),
              Text(
                title,
                style: AppTheme.typography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Text(
            value,
            style: AppTheme.typography.h3.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              decoration: TextDecoration.none,
            ),
          ),
          Text(
            subtitle,
            style: AppTheme.typography.caption.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButtons() {
    return Container(
      height: 48,
      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md),
        children: [
          _buildFilterButton('Toutes', 'tous'),
          SizedBox(width: AppTheme.spacing.sm),
          _buildFilterButton('En attente', 'pending'),
          SizedBox(width: AppTheme.spacing.sm),
          _buildFilterButton('Payées', 'paid'),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.md,
          vertical: AppTheme.spacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.colors.primary : AppTheme.colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTheme.typography.bodyMedium.copyWith(
              color: isSelected ? Colors.white : AppTheme.colors.textPrimary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.doc_text,
            size: 64,
            color: AppTheme.colors.textSecondary,
          ),
          SizedBox(height: AppTheme.spacing.md),
          Text(
            'Aucune facture',
            style: AppTheme.typography.h3.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Text(
            'Vos factures apparaîtront ici',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final status = invoice['status'] ?? 'pending';
    final isPaid = status == 'paid';
    final amount = (invoice['amount'] ?? 0).toDouble();
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    
    String dateStr = '';
    try {
      final date = invoice['created_at'];
      if (date != null) {
        final parsedDate = DateTime.parse(date);
        dateStr = DateFormat('dd/MM/yyyy').format(parsedDate);
      }
    } catch (e) {
      debugPrint('Erreur format date: $e');
    }

    String dueDate = '';
    try {
      final date = invoice['due_date'];
      if (date != null) {
        final parsedDate = DateTime.parse(date);
        dueDate = DateFormat('dd/MM/yyyy').format(parsedDate);
      }
    } catch (e) {
      debugPrint('Erreur format date échéance: $e');
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInvoiceDetails(invoice),
          borderRadius: BorderRadius.circular(AppTheme.radius.medium),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(AppTheme.spacing.sm),
                      decoration: BoxDecoration(
                        color: (isPaid ? AppTheme.colors.success : AppTheme.colors.warning).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppTheme.radius.small),
                      ),
                      child: Icon(
                        isPaid ? CupertinoIcons.checkmark_circle : CupertinoIcons.clock,
                        color: isPaid ? AppTheme.colors.success : AppTheme.colors.warning,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invoice['invoice_number'] ?? 'Facture',
                            style: AppTheme.typography.h4.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.colors.textPrimary,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          Text(
                            invoice['description'] ?? 'Sans description',
                            style: AppTheme.typography.bodySmall.copyWith(
                              color: AppTheme.colors.textSecondary,
                              decoration: TextDecoration.none,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatter.format(amount),
                          style: AppTheme.typography.h4.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.colors.textPrimary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (isPaid ? AppTheme.colors.success : AppTheme.colors.warning).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppTheme.radius.small),
                          ),
                          child: Text(
                            isPaid ? 'Payée' : 'En attente',
                            style: AppTheme.typography.caption.copyWith(
                              color: isPaid ? AppTheme.colors.success : AppTheme.colors.warning,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.spacing.sm),
                Row(
                  children: [
                    if (dateStr.isNotEmpty) ...[
                      Icon(
                        CupertinoIcons.calendar,
                        size: 14,
                        color: AppTheme.colors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Émise le $dateStr',
                        style: AppTheme.typography.caption.copyWith(
                          color: AppTheme.colors.textSecondary,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                    if (dueDate.isNotEmpty && !isPaid) ...[
                      SizedBox(width: AppTheme.spacing.md),
                      Icon(
                        CupertinoIcons.clock,
                        size: 14,
                        color: AppTheme.colors.warning,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Échéance $dueDate',
                        style: AppTheme.typography.caption.copyWith(
                          color: AppTheme.colors.warning,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInvoiceDetails(Map<String, dynamic> invoice) {
    final formatter = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final amount = (invoice['amount'] ?? 0).toDouble();
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(invoice['invoice_number'] ?? 'Facture'),
        message: Text('Montant: ${formatter.format(amount)}'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Télécharger la facture
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.arrow_down_doc),
                SizedBox(width: 8),
                Text('Télécharger'),
              ],
            ),
          ),
          if (invoice['status'] != 'paid')
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Marquer comme payée
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(CupertinoIcons.checkmark_circle),
                  SizedBox(width: 8),
                  Text('Signaler comme payée'),
                ],
              ),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ),
    );
  }

  IconData _getIconForPlatform(IconData material, IconData cupertino) {
    return DeviceDetector.shouldUseIOSInterface() ? cupertino : material;
  }
}

