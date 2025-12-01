// ============================================================================
// MOBILE TIMESHEET TAB - OXO TIME SHEETS
// Tab Timesheet iOS avec design moderne
// Utilise STRICTEMENT AppTheme et Cupertino
// ============================================================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../models/timesheet_models.dart';
import '../../../models/mission.dart';
import '../../../services/timesheet_service.dart';
import '../../../services/mission_service.dart';
import '../../../services/supabase_service.dart';
import '../../../utils/device_detector.dart';
import '../../../pages/partner/ios_mobile_rates_page.dart';

class MobileTimesheetTab extends StatefulWidget {
  const MobileTimesheetTab({Key? key}) : super(key: key);

  @override
  State<MobileTimesheetTab> createState() => _MobileTimesheetTabState();
}

class _MobileTimesheetTabState extends State<MobileTimesheetTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  List<CalendarDay> _calendar = [];
  List<Mission> _availableMissions = [];
  MonthlyStats _stats = MonthlyStats.empty();
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  
  // Contrôleurs pour les saisies
  final Map<String, double?> _selectedDays = {};
  final Map<String, String?> _selectedMissions = {};

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
    setState(() => _isLoading = true);
    
    try {
      final partnerId = SupabaseService.currentUser?.id;
      if (partnerId == null) throw Exception('Utilisateur non connecté');

      debugPrint('📱 MobileTimesheetTab: Chargement données pour $partnerId');

      final results = await Future.wait([
        TimesheetService.getMonthCalendarWithEntries(
          partnerId: partnerId,
          year: _selectedMonth.year,
          month: _selectedMonth.month,
        ),
        _loadMissionsWithFallback(partnerId),
        TimesheetService.getOperatorMonthlyStats(
          partnerId: partnerId,
          year: _selectedMonth.year,
          month: _selectedMonth.month,
        ),
      ]);

      final missions = results[1] as List<Mission>;
      debugPrint('📱 MobileTimesheetTab: ${missions.length} missions chargées');
      
      if (missions.isEmpty) {
        debugPrint('⚠️ MobileTimesheetTab: AUCUNE mission disponible !');
      } else {
        for (final m in missions) {
          debugPrint('  - Mission: ${m.title} (ID: ${m.id})');
        }
      }

      setState(() {
        _calendar = results[0] as List<CalendarDay>;
        _availableMissions = missions;
        _stats = results[2] as MonthlyStats;
        _isLoading = false;
      });

      _initializeSelections();
    } catch (e) {
      debugPrint('❌ Erreur chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Charge les missions avec plusieurs fallbacks
  Future<List<Mission>> _loadMissionsWithFallback(String partnerId) async {
    try {
      // Essayer d'abord via le service standard
      var missions = await MissionService.getAvailableMissionsForTimesheet(
        partnerId: partnerId,
        date: _selectedMonth,
      );
      
      if (missions.isNotEmpty) {
        debugPrint('✅ Missions chargées via MissionService: ${missions.length}');
        return missions;
      }

      // Fallback: récupérer directement depuis Supabase
      debugPrint('🔄 Fallback: récupération directe depuis Supabase');
      
      final response = await SupabaseService.client
          .from('missions')
          .select()
          .or('partner_id.eq.$partnerId,assigned_to.eq.$partnerId')
          .inFilter('status', ['in_progress', 'pending', 'accepted'])
          .order('start_date', ascending: false);
      
      debugPrint('📊 Requête directe: ${response.length} missions trouvées');
      
      return (response as List).map((json) {
        return Mission.fromJson(Map<String, dynamic>.from(json));
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement missions: $e');
      
      // Dernier recours: récupérer TOUTES les missions actives
      try {
        debugPrint('🔄 Dernier recours: toutes les missions actives');
        final response = await SupabaseService.client
            .from('missions')
            .select()
            .inFilter('status', ['in_progress', 'pending', 'accepted'])
            .order('start_date', ascending: false)
            .limit(50);
        
        return (response as List).map((json) {
          return Mission.fromJson(Map<String, dynamic>.from(json));
        }).toList();
      } catch (e2) {
        debugPrint('❌ Dernier recours échoué: $e2');
        return [];
      }
    }
  }

  void _initializeSelections() {
    for (var day in _calendar) {
      final key = day.date.toIso8601String();
      if (day.hasEntry && day.entry!.id.isNotEmpty) {
        _selectedDays[key] = day.entry!.days > 0 ? day.entry!.days : null;
        _selectedMissions[key] = day.entry!.clientId; // mission_id
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
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.colors.background,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.colors.surface,
        middle: Text(
          'Timesheet',
          style: AppTheme.typography.h3.copyWith(color: AppTheme.colors.textPrimary),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            _getIconForPlatform(AppIcons.settings, AppIcons.settingsIOS),
            color: AppTheme.colors.primary,
            size: 24,
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pushNamed('/profile');
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Tabs - wrapped in Material for TabBar
            Material(
              color: AppTheme.colors.surface,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.colors.primary,
                unselectedLabelColor: AppTheme.colors.textSecondary,
                indicatorColor: AppTheme.colors.primary,
                tabs: const [
                  Tab(text: 'Saisie du temps'),
                  Tab(text: 'Tarifs'),
                  Tab(text: 'Reporting'),
                ],
              ),
            ),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildTimeEntryTab(),
                  _buildRatesTab(),
                  _buildReportingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeEntryTab() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    return DefaultTextStyle(
      style: TextStyle(
        decoration: TextDecoration.none,
        color: AppTheme.colors.textPrimary,
        fontFamily: AppTheme.typography.bodyMedium.fontFamily,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.spacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mois/Année
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(CupertinoIcons.chevron_left, color: AppTheme.colors.primary),
                      onPressed: () => _changeMonth(-1),
                    ),
                    SizedBox(width: AppTheme.spacing.md),
                    Text(
                      DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth),
                      style: AppTheme.typography.h2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.colors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(width: AppTheme.spacing.md),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(CupertinoIcons.chevron_right, color: AppTheme.colors.primary),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppTheme.spacing.lg),
              // Cartes KPI
              _buildKPICards(),
              SizedBox(height: AppTheme.spacing.lg),
              // Liste des jours
              _buildDaysList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKPICards() {
    return Row(
      children: [
        Expanded(
          child: _buildKPICard(
            icon: CupertinoIcons.alarm,
            value: '${_stats.totalDays.toStringAsFixed(1)} j',
            label: 'Jours totaux',
            color: const Color(0xFF3B82F6), // Bleu
          ),
        ),
        SizedBox(width: AppTheme.spacing.sm),
        Expanded(
          child: _buildKPICard(
            icon: CupertinoIcons.money_euro_circle,
            value: '${_stats.totalAmount.toStringAsFixed(2)} €',
            label: 'Montant total',
            color: const Color(0xFF10B981), // Vert
          ),
        ),
        SizedBox(width: AppTheme.spacing.sm),
        Expanded(
          child: _buildKPICard(
            icon: CupertinoIcons.calendar,
            value: _calendar.where((d) => d.hasEntry && d.entry!.days > 0).length.toStringAsFixed(1),
            label: 'Jours saisis',
            color: const Color(0xFFF59E0B), // Orange
          ),
        ),
        SizedBox(width: AppTheme.spacing.sm),
        Expanded(
          child: _buildKPICard(
            icon: CupertinoIcons.chart_bar_alt_fill,
            value: '${_stats.avgDaysPerEntry.toStringAsFixed(1)} j',
            label: 'Moyenne/entrée',
            color: const Color(0xFF8B5CF6), // Violet
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.spacing.sm,
        vertical: AppTheme.spacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          SizedBox(height: AppTheme.spacing.xs),
          Text(
            value,
            style: AppTheme.typography.h4.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.xs),
          Text(
            label,
            style: AppTheme.typography.bodySmall.copyWith(
              color: AppTheme.colors.textSecondary,
              fontSize: 11,
              decoration: TextDecoration.none,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDaysList() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
        border: Border.all(color: AppTheme.colors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(AppTheme.spacing.md),
            decoration: BoxDecoration(
              color: AppTheme.colors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppTheme.radius.medium),
                topRight: Radius.circular(AppTheme.radius.medium),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Date',
                    style: AppTheme.typography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Jour',
                    style: AppTheme.typography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Mission',
                    style: AppTheme.typography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Jours',
                    style: AppTheme.typography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Rows
          ..._calendar.map((day) => _buildDayRow(day)),
        ],
      ),
    );
  }

  Widget _buildDayRow(CalendarDay day) {
    final key = day.date.toIso8601String();
    final isWeekend = day.isWeekend;
    
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.colors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Date
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd/MM').format(day.date),
              style: AppTheme.typography.bodyMedium.copyWith(
                decoration: TextDecoration.none,
              ),
            ),
          ),
          // Jour
          Expanded(
            flex: 2,
            child: Text(
              day.dayName.substring(0, 3),
              style: AppTheme.typography.bodyMedium.copyWith(
                color: isWeekend ? AppTheme.colors.textSecondary : null,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          // Mission
          Expanded(
            flex: 4,
            child: _buildMissionDropdown(day, key),
          ),
          // Jours
          Expanded(
            flex: 2,
            child: _buildDaysDropdown(day, key),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionDropdown(CalendarDay day, String key) {
    final selectedMissionId = _selectedMissions[key];
    final selectedMission = selectedMissionId != null
        ? _availableMissions.firstWhere(
            (m) => m.id == selectedMissionId,
            orElse: () => Mission(
              id: '',
              title: '',
              startDate: DateTime.now(),
              status: '',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          )
        : null;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.sm,
          vertical: AppTheme.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppTheme.colors.inputBackground,
          borderRadius: BorderRadius.circular(AppTheme.radius.small),
          border: Border.all(color: AppTheme.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                selectedMission?.title ?? 'Mission...',
                style: AppTheme.typography.bodySmall.copyWith(
                  decoration: TextDecoration.none,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: AppTheme.colors.textSecondary,
            ),
          ],
        ),
      ),
      onPressed: () => _showMissionPicker(day, key),
    );
  }

  Widget _buildDaysDropdown(CalendarDay day, String key) {
    final selectedDays = _selectedDays[key];
    
    return CupertinoButton(
      padding: EdgeInsets.zero,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.sm,
          vertical: AppTheme.spacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppTheme.colors.inputBackground,
          borderRadius: BorderRadius.circular(AppTheme.radius.small),
          border: Border.all(color: AppTheme.colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedDays != null ? '${selectedDays.toStringAsFixed(1)}' : '...',
              style: AppTheme.typography.bodySmall.copyWith(
                decoration: TextDecoration.none,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              size: 16,
              color: AppTheme.colors.textSecondary,
            ),
          ],
        ),
      ),
      onPressed: () => _showDaysPicker(day, key),
    );
  }

  void _showMissionPicker(CalendarDay day, String key) {
    debugPrint('📱 Ouverture picker mission - ${_availableMissions.length} missions disponibles');
    
    if (_availableMissions.isEmpty) {
      // Afficher un message si aucune mission n'est disponible
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Aucune mission disponible'),
          content: const Text(
            'Aucune mission ne vous est assignée pour le moment.\n\n'
            'Contactez votre associé pour vous faire assigner une mission.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Recharger'),
              onPressed: () {
                Navigator.pop(context);
                _loadData();
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Sélectionner une mission (${_availableMissions.length})'),
        actions: _availableMissions.map((mission) {
          final subtitle = mission.companyName != null 
              ? ' - ${mission.companyName}' 
              : '';
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedMissions[key] = mission.id;
              });
              Navigator.pop(context);
            },
            child: Column(
              children: [
                Text(
                  mission.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel,
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ),
    );
  }

  void _showDaysPicker(CalendarDay day, String key) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Sélectionner les jours'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedDays[key] = 0.5;
              });
              Navigator.pop(context);
            },
            child: Text('0.5 jour'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedDays[key] = 1.0;
              });
              Navigator.pop(context);
            },
            child: Text('1.0 jour'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
      ),
    );
  }

  Widget _buildRatesTab() {
    return const IOSMobileRatesPage(showHeader: false);
  }

  Widget _buildReportingTab() {
    return Center(
      child: Text(
        'Reporting',
        style: AppTheme.typography.h3.copyWith(
          decoration: TextDecoration.none,
        ),
      ),
    );
  }

  IconData _getIconForPlatform(IconData material, IconData cupertino) {
    return DeviceDetector.shouldUseIOSInterface() ? cupertino : material;
  }
}
