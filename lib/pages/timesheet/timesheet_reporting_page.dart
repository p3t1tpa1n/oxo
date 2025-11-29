// ============================================================================
// ✅ PATCH COMPLET POUR LA PAGE DE REPORTING DU MODULE TIMESHEET
// Corrige définitivement les erreurs "RenderFlex overflowed by ... pixels"
// + Correction des labels (heures → jours)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/timesheet_models.dart';
import '../../services/timesheet_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';

class TimesheetReportingPage extends StatefulWidget {
  const TimesheetReportingPage({super.key});

  @override
  State<TimesheetReportingPage> createState() => _TimesheetReportingPageState();
}

class _TimesheetReportingPageState extends State<TimesheetReportingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ClientReport> _clientReports = [];
  List<PartnerReport> _operatorReports = [];
  List<TimesheetEntry> _allEntries = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCompany = await SupabaseService.getUserCompany();
      final companyId = userCompany?['company_id'] as int?;

      final results = await Future.wait([
        TimesheetService.getClientReport(
          year: _selectedMonth.year,
          month: _selectedMonth.month,
          companyId: companyId,
        ),
        TimesheetService.getPartnerReport(
          year: _selectedMonth.year,
          month: _selectedMonth.month,
          companyId: companyId,
        ),
        TimesheetService.getAllMonthlyEntries(
          year: _selectedMonth.year,
          month: _selectedMonth.month,
          companyId: companyId,
        ),
      ]);

      setState(() {
        _clientReports = results[0] as List<ClientReport>;
        _operatorReports = results[1] as List<PartnerReport>;
        _allEntries = results[2] as List<TimesheetEntry>;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement données: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideMenu(
            userRole: SupabaseService.currentUserRole,
            selectedRoute: '/timesheet/reporting',
          ),
          Expanded(
            child: Column(
              children: [
                const TopBar(title: 'OXO TIME SHEETS - Reporting'),
                _buildHeader(),
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF2A4B63),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xFF2A4B63),
                  tabs: const [
                    Tab(text: 'Par client', icon: Icon(Icons.business)),
                    Tab(text: 'Par partenaire', icon: Icon(Icons.person)),
                    Tab(text: 'Détail des saisies', icon: Icon(Icons.list)),
                  ],
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildClientReportTab(),
                            _buildPartnerReportTab(),
                            _buildEntriesDetailTab(),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 🧱 HEADER ET INDICATEURS
  // ============================================================================

  Widget _buildHeader() {
    final totalDays = TimesheetService.calculateTotalDays(_allEntries);
    final totalAmount = TimesheetService.calculateTotalAmount(_allEntries);

    return Container(
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF2A4B63).withOpacity(0.05),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_left, color: Color(0xFF2A4B63)),
                tooltip: 'Mois précédent',
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2A4B63),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () => _changeMonth(1),
                icon: const Icon(Icons.chevron_right, color: Color(0xFF2A4B63)),
                tooltip: 'Mois suivant',
              ),
              const SizedBox(width: 32),
              ElevatedButton.icon(
                onPressed: _exportToPDF,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _exportToExcel,
                icon: const Icon(Icons.table_chart),
                label: const Text('Export Excel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSummaryCard('Total jours', TimesheetService.formatDays(totalDays), Icons.access_time, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard('Total montant', TimesheetService.formatAmount(totalAmount), Icons.euro, Colors.green)),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard('Clients actifs', '${_clientReports.length}', Icons.business, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _buildSummaryCard('Partenaires actifs', '${_operatorReports.length}', Icons.person, Colors.purple)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 4),
                Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // 📊 ONGLET RAPPORT PAR CLIENT
  // ============================================================================

  Widget _buildClientReportTab() {
    if (_clientReports.isEmpty) {
      return _emptyTable(Icons.business_outlined, 'Aucune donnée pour ce mois');
    }

    const wClient = 260.0;
    const wJours = 140.0;
    const wMontant = 160.0;
    const wNb = 140.0;
    const wTarif = 170.0;

    return _scrollableDataTable(
      columns: const [
        DataColumn(label: _H('Client', wClient)),
        DataColumn(label: _H('Jours totaux', wJours), numeric: true),
        DataColumn(label: _H('Montant total (€)', wMontant), numeric: true),
        DataColumn(label: _H('Nb partenaires', wNb), numeric: true),
        DataColumn(label: _H('Tarif moyen (€/j)', wTarif), numeric: true),
      ],
      rows: _clientReports.map((r) {
        final avgRate = r.totalDays > 0 ? r.totalAmount / r.totalDays : 0;
        return DataRow(cells: [
          DataCell(SizedBox(width: wClient, child: Text(r.clientName, style: const TextStyle(fontWeight: FontWeight.w500)))),
          DataCell(SizedBox(width: wJours, child: Text(r.totalDays.toStringAsFixed(2)))),
          DataCell(SizedBox(width: wMontant, child: Text(r.totalAmount.toStringAsFixed(2)))),
          DataCell(SizedBox(width: wNb, child: Text('${r.partnerCount}'))),
          DataCell(SizedBox(width: wTarif, child: Text(avgRate.toStringAsFixed(2)))),
        ]);
      }).toList(),
    );
  }

  // ============================================================================
  // 👤 ONGLET RAPPORT PAR PARTENAIRE
  // ============================================================================

  Widget _buildPartnerReportTab() {
    if (_operatorReports.isEmpty) {
      return _emptyTable(Icons.person_outlined, 'Aucune donnée pour ce mois');
    }

    const wPartner = 220.0;
    const wEmail = 260.0;
    const wJours = 140.0;
    const wMontant = 160.0;
    const wClients = 120.0;
    const wTarif = 170.0;

    return _scrollableDataTable(
      columns: const [
        DataColumn(label: _H('Partenaire', wPartner)),
        DataColumn(label: _H('Email', wEmail)),
        DataColumn(label: _H('Jours totaux', wJours), numeric: true),
        DataColumn(label: _H('Montant total (€)', wMontant), numeric: true),
        DataColumn(label: _H('Nb clients', wClients), numeric: true),
        DataColumn(label: _H('Tarif moyen (€/j)', wTarif), numeric: true),
      ],
      rows: _operatorReports.map((r) {
        final avgRate = r.totalDays > 0 ? r.totalAmount / r.totalDays : 0;
        return DataRow(cells: [
          DataCell(SizedBox(width: wPartner, child: Text(r.partnerName))),
          DataCell(SizedBox(width: wEmail, child: Text(r.partnerEmail))),
          DataCell(SizedBox(width: wJours, child: Text(r.totalDays.toStringAsFixed(2)))),
          DataCell(SizedBox(width: wMontant, child: Text(r.totalAmount.toStringAsFixed(2)))),
          DataCell(SizedBox(width: wClients, child: Text('${r.clientCount}'))),
          DataCell(SizedBox(width: wTarif, child: Text(avgRate.toStringAsFixed(2)))),
        ]);
      }).toList(),
    );
  }

  // ============================================================================
  // 📋 ONGLET DÉTAIL DES SAISIES
  // ============================================================================

  Widget _buildEntriesDetailTab() {
    if (_allEntries.isEmpty) {
      return _emptyTable(Icons.list_outlined, 'Aucune saisie pour ce mois');
    }

    const wDate = 120.0;
    const wPartner = 220.0;
    const wClient = 240.0;
    const wJours = 120.0;
    const wTarif = 120.0;
    const wMontant = 140.0;
    const wStatut = 140.0;
    const wComment = 320.0;

    return _scrollableDataTable(
      columns: const [
        DataColumn(label: _H('Date', wDate)),
        DataColumn(label: _H('Partenaire', wPartner)),
        DataColumn(label: _H('Client', wClient)),
        DataColumn(label: _H('Jours', wJours), numeric: true),
        DataColumn(label: _H('Tarif (€/j)', wTarif), numeric: true),
        DataColumn(label: _H('Montant (€)', wMontant), numeric: true),
        DataColumn(label: _H('Statut', wStatut)),
        DataColumn(label: _H('Commentaire', wComment)),
      ],
      rows: _allEntries.map((e) {
        return DataRow(cells: [
          DataCell(SizedBox(width: wDate, child: Text(DateFormat('dd/MM/yyyy').format(e.entryDate)))),
          DataCell(SizedBox(width: wPartner, child: Text(e.partnerEmail ?? e.partnerId))),
          DataCell(SizedBox(width: wClient, child: Text(e.clientName ?? e.clientId))),
          DataCell(SizedBox(width: wJours, child: Text(e.days.toStringAsFixed(2)))),
          DataCell(SizedBox(width: wTarif, child: Text(e.dailyRate.toStringAsFixed(2)))),
          DataCell(SizedBox(width: wMontant, child: Text(e.amount.toStringAsFixed(2)))),
          DataCell(SizedBox(
            width: wStatut,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(e.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _getStatusLabel(e.status),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _getStatusColor(e.status)),
              ),
            ),
          )),
          DataCell(SizedBox(width: wComment, child: Text(e.comment ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis))),
        ]);
      }).toList(),
    );
  }

  // ============================================================================
  // 🧱 COMPOSANTS UTILITAIRES
  // ============================================================================

  Widget _scrollableDataTable({required List<DataColumn> columns, required List<DataRow> rows}) {
    return Card(
      elevation: 2,
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 960),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columnSpacing: 16,
              headingRowColor: MaterialStateProperty.all(const Color(0xFF2A4B63).withOpacity(0.1)),
              columns: columns,
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyTable(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 20),
          Text(message, style: TextStyle(fontSize: 20, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'draft':
        return 'Brouillon';
      case 'submitted':
        return 'Soumis';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return status;
    }
  }

  Future<void> _exportToPDF() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Export PDF en cours de développement...'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _exportToExcel() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🚧 Export Excel en cours de développement...'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

// ============================================================================
// 🧱 WIDGET D'EN-TÊTE RÉUTILISABLE (empêche l'overflow)
// ============================================================================

class _H extends StatelessWidget {
  final String text;
  final double width;

  const _H(this.text, this.width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
