import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';

class IOSTimesheetPage extends StatefulWidget {
  const IOSTimesheetPage({Key? key}) : super(key: key);

  @override
  State<IOSTimesheetPage> createState() => _IOSTimesheetPageState();
}

class _IOSTimesheetPageState extends State<IOSTimesheetPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _timesheetEntries = [];
  List<Map<String, dynamic>> _availabilities = [];
  List<Map<String, dynamic>> _partners = [];
  List<Map<String, dynamic>> _topAvailablePartners = [];
  bool _isLoading = true;
  bool _loadingAvailablePartners = false;
  bool _twoWeeksView = false;
  DateTime _selectedAvailabilityDate = DateTime.now();
  String _selectedPartnerId = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadTimesheetEntries(),
        _loadPartners(),
        _loadAvailabilities(),
        _loadTopAvailablePartners(),
      ]);
    } catch (e) {
      debugPrint('Erreur chargement données: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTimesheetEntries() async {
    try {
      final response = await SupabaseService.client
          .from('timesheet_entries')
          .select('*')
          .order('date', ascending: false);

      final allUsers = await SupabaseService.client.rpc('get_users');
      final usersMap = <String, Map<String, dynamic>>{};
      for (var user in allUsers) {
        usersMap[user['user_id']] = user;
      }

      for (var entry in response) {
        final user = usersMap[entry['user_id']];
        entry['user_email'] = user?['email'] ?? 'Utilisateur inconnu';
        entry['user_first_name'] = user?['first_name'] ?? '';
        entry['user_last_name'] = user?['last_name'] ?? '';
      }

      if (mounted) {
        setState(() {
          _timesheetEntries = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement timesheet: $e');
    }
  }

  Future<void> _loadPartners() async {
    try {
      final partners = await SupabaseService.getPartners();
      if (mounted) {
        setState(() {
          _partners = partners;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement partenaires: $e');
    }
  }

  Future<void> _loadAvailabilities() async {
    try {
      DateTime startDate;
      DateTime endDate;
      if (_twoWeeksView) {
        final now = DateTime.now();
        startDate = DateTime(now.year, now.month, now.day);
        endDate = startDate.add(const Duration(days: 13));
      } else {
        startDate = DateTime(_selectedAvailabilityDate.year, _selectedAvailabilityDate.month, 1);
        endDate = DateTime(_selectedAvailabilityDate.year, _selectedAvailabilityDate.month + 1, 0);
      }

      final availabilities = await SupabaseService.getPartnerAvailabilityForPeriod(
        startDate: startDate,
        endDate: endDate,
      );

      if (mounted) {
        setState(() {
          _availabilities = availabilities;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement disponibilités: $e');
    }
  }

  Future<void> _loadTopAvailablePartners() async {
    setState(() => _loadingAvailablePartners = true);
    try {
      final partners = await SupabaseService.getPartnersAvailableAtLeast(periodDays: 14, minAvailableDays: 7);
      if (mounted) setState(() => _topAvailablePartners = partners);
    } catch (e) {
      debugPrint('Erreur chargement partenaires >=7/14: $e');
    } finally {
      if (mounted) setState(() => _loadingAvailablePartners = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      navigationBar: IOSNavigationBar(
        title: "Timesheet & Disponibilités",
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: IOSTheme.primaryBlue),
        ),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _loadData,
            child: const Icon(CupertinoIcons.refresh, color: IOSTheme.primaryBlue),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: IOSTheme.systemBackground,
            child: CupertinoSegmentedControl<int>(
              children: const {
                0: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Timesheet'),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('Disponibilités'),
                ),
              },
              onValueChanged: (value) {
                _tabController.animateTo(value);
              },
              groupValue: _tabController.index,
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTimesheetTab(),
                      _buildAvailabilityTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesheetTab() {
    final filteredEntries = _selectedPartnerId == 'all' 
        ? _timesheetEntries 
        : _timesheetEntries.where((e) => e['user_id'] == _selectedPartnerId).toList();

    return Column(
      children: [
        // Statistiques
        Container(
          padding: const EdgeInsets.all(16),
          color: IOSTheme.systemGroupedBackground,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Entrées',
                  '${filteredEntries.length}',
                  CupertinoIcons.doc_text,
                  IOSTheme.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Heures',
                  '${_getTotalHours(filteredEntries).toStringAsFixed(1)}h',
                  CupertinoIcons.clock,
                  IOSTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Partenaires',
                  '${filteredEntries.map((e) => e['user_id']).toSet().length}',
                  CupertinoIcons.person_2,
                  IOSTheme.warningColor,
                ),
              ),
            ],
          ),
        ),
        
        // Filtre partenaire
        Container(
          padding: const EdgeInsets.all(16),
          color: IOSTheme.systemBackground,
          child: IOSListSection(
            children: [
              IOSListTile(
                leading: const Icon(CupertinoIcons.person_circle, color: IOSTheme.primaryBlue),
                title: const Text('Filtrer par partenaire'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedPartnerId == 'all' ? 'Tous' : _getPartnerName(_selectedPartnerId),
                      style: IOSTheme.footnote.copyWith(color: IOSTheme.systemGray),
                    ),
                    const SizedBox(width: 8),
                    const Icon(CupertinoIcons.chevron_right, size: 16, color: IOSTheme.systemGray),
                  ],
                ),
                onTap: _showPartnerPicker,
              ),
            ],
          ),
        ),
        
        // Liste des entrées
        Expanded(
          child: filteredEntries.isEmpty
              ? _buildEmptyState(
                  CupertinoIcons.clock,
                  'Aucune entrée timesheet',
                  'Les entrées apparaîtront ici',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredEntries.length,
                  itemBuilder: (context, index) {
                    return _buildTimesheetEntryCard(filteredEntries[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityTab() {
    return Column(
      children: [
        // Contrôles
        Container(
          padding: const EdgeInsets.all(16),
          color: IOSTheme.systemGroupedBackground,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: () async {
                        setState(() => _twoWeeksView = !_twoWeeksView);
                        await _loadAvailabilities();
                      },
                      child: Text(_twoWeeksView ? 'Vue mois' : '2 prochaines semaines'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton.filled(
                      onPressed: _loadingAvailablePartners ? null : _showTopAvailablePartnersDialog,
                      child: Text(_loadingAvailablePartners ? 'Chargement...' : 'Dispo ≥ 7/14'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_twoWeeksView) _buildMonthSelector(),
            ],
          ),
        ),
        
        // Liste des disponibilités
        Expanded(
          child: _availabilities.isEmpty
              ? _buildEmptyState(
                  CupertinoIcons.calendar,
                  'Aucune disponibilité',
                  'Les disponibilités apparaîtront ici',
                )
              : _buildAvailabilityList(),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _selectedAvailabilityDate = DateTime(
                  _selectedAvailabilityDate.year,
                  _selectedAvailabilityDate.month - 1,
                );
              });
              _loadAvailabilities();
            },
            child: const Icon(CupertinoIcons.chevron_left, color: IOSTheme.primaryBlue),
          ),
          Text(
            DateFormat('MMMM yyyy', 'fr_FR').format(_selectedAvailabilityDate),
            style: IOSTheme.body.copyWith(fontWeight: FontWeight.w600),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              setState(() {
                _selectedAvailabilityDate = DateTime(
                  _selectedAvailabilityDate.year,
                  _selectedAvailabilityDate.month + 1,
                );
              });
              _loadAvailabilities();
            },
            child: const Icon(CupertinoIcons.chevron_right, color: IOSTheme.primaryBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityList() {
    final Map<String, List<Map<String, dynamic>>> groupedAvailabilities = {};
    for (var availability in _availabilities) {
      final date = availability['date'];
      groupedAvailabilities.putIfAbsent(date, () => []).add(availability);
    }

    final sortedDates = groupedAvailabilities.keys.toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayAvailabilities = groupedAvailabilities[date]!;
        final parsedDate = DateTime.parse(date);
        return _buildDayAvailabilityCard(parsedDate, dayAvailabilities);
      },
    );
  }

  Widget _buildDayAvailabilityCard(DateTime date, List<Map<String, dynamic>> dayAvailabilities) {
    final availablePartners = dayAvailabilities.where((a) => a['is_available'] == true).toList();
    final unavailablePartners = dayAvailabilities.where((a) => a['is_available'] == false).toList();

    return IOSListSection(
      title: DateFormat('EEEE d MMMM', 'fr_FR').format(date),
      children: [
        if (availablePartners.isNotEmpty) ...[
          IOSListTile(
            leading: const Icon(CupertinoIcons.checkmark_circle_fill, color: IOSTheme.successColor),
            title: Text('${availablePartners.length} disponible(s)'),
            subtitle: Text(
              availablePartners.map((p) => p['partner_name'] ?? 'Inconnu').join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (unavailablePartners.isNotEmpty) ...[
          IOSListTile(
            leading: const Icon(CupertinoIcons.xmark_circle_fill, color: IOSTheme.errorColor),
            title: Text('${unavailablePartners.length} indisponible(s)'),
            subtitle: Text(
              unavailablePartners.map((p) => p['partner_name'] ?? 'Inconnu').join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTimesheetEntryCard(Map<String, dynamic> entry) {
    final status = entry['status'] ?? 'pending';
    final hours = (entry['hours'] ?? 0.0).toDouble();
    final date = DateTime.tryParse(entry['date'] ?? '') ?? DateTime.now();
    final userEmail = entry['user_email'] ?? 'Utilisateur inconnu';

    return IOSListSection(
      children: [
        IOSListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getStatusColor(status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${hours.toStringAsFixed(1)}h',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          title: Text(userEmail.split('@').first),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(DateFormat('dd/MM/yyyy').format(date)),
              Text(_getStatusLabel(status)),
            ],
          ),
          trailing: status == 'pending' 
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _updateEntryStatus(entry['id'], 'approved'),
                      child: const Icon(CupertinoIcons.check_mark, color: IOSTheme.successColor),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => _updateEntryStatus(entry['id'], 'rejected'),
                      child: const Icon(CupertinoIcons.xmark, color: IOSTheme.errorColor),
                    ),
                  ],
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: IOSTheme.cardDecoration,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: IOSTheme.title3.copyWith(color: color),
          ),
          Text(
            title,
            style: IOSTheme.caption1,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: IOSTheme.systemGray3),
          const SizedBox(height: 16),
          Text(title, style: IOSTheme.title2),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: IOSTheme.body.copyWith(color: IOSTheme.labelSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showPartnerPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Sélectionner un partenaire'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedPartnerId = 'all');
              Navigator.pop(context);
            },
            child: const Text('Tous les partenaires'),
          ),
          ..._partners.map((partner) => CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedPartnerId = partner['user_id']);
              Navigator.pop(context);
            },
            child: Text(_getPartnerDisplayName(partner)),
          )),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ),
    );
  }

  void _showTopAvailablePartnersDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Partenaires disponibles ≥ 7/14 jours'),
        content: SizedBox(
          height: 300,
          child: _topAvailablePartners.isEmpty
              ? const Center(child: Text('Aucun partenaire satisfait ce critère'))
              : ListView.builder(
                  itemCount: _topAvailablePartners.length,
                  itemBuilder: (context, index) {
                    final p = _topAvailablePartners[index];
                    final name = p['partner_name'] ?? 'Partenaire';
                    final available = p['available_days'] ?? 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(child: Text(name)),
                          Text('$available/14 j', style: IOSTheme.footnote),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Fermer'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _updateEntryStatus(dynamic entryId, String newStatus) async {
    try {
      await SupabaseService.client
          .from('timesheet_entries')
          .update({'status': newStatus})
          .eq('id', entryId);
      
      _loadTimesheetEntries();
      
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Succès'),
            content: Text('Statut mis à jour: ${_getStatusLabel(newStatus)}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }

  double _getTotalHours(List<Map<String, dynamic>> entries) {
    return entries.fold(0.0, (sum, entry) => sum + (entry['hours'] ?? 0.0).toDouble());
  }

  String _getPartnerName(String partnerId) {
    final partner = _partners.firstWhere(
      (p) => p['user_id'] == partnerId,
      orElse: () => <String, dynamic>{},
    );
    return _getPartnerDisplayName(partner);
  }

  String _getPartnerDisplayName(Map<String, dynamic> partner) {
    final firstName = partner['first_name'];
    final lastName = partner['last_name'];
    
    if (firstName != null && lastName != null && firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    }
    
    final email = partner['email'] ?? partner['user_email'];
    if (email != null && email.isNotEmpty) {
      return email.split('@').first;
    }
    
    return 'Partenaire';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved': return IOSTheme.successColor;
      case 'rejected': return IOSTheme.errorColor;
      case 'pending': return IOSTheme.warningColor;
      default: return IOSTheme.systemGray;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'approved': return 'Approuvé';
      case 'rejected': return 'Rejeté';
      case 'pending': return 'En attente';
      default: return status;
    }
  }
}


