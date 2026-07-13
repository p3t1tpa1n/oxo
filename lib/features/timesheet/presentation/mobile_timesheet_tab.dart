// ============================================================================
// MOBILE TIMESHEET TAB - OXO TIME SHEETS
// Tab Timesheet avec design moderne
// Utilise STRICTEMENT AppTheme et Material
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../models/timesheet_models.dart';
import '../../../models/mission.dart';
import '../../../models/user_role.dart';
import '../../../services/timesheet_service.dart';
import '../../../services/mission_service.dart';
import '../../../services/supabase_service.dart';
import '../../../services/company_service.dart';

class MobileTimesheetTab extends StatefulWidget {
  const MobileTimesheetTab({Key? key}) : super(key: key);

  @override
  State<MobileTimesheetTab> createState() => _MobileTimesheetTabState();
}

class _MobileTimesheetTabState extends State<MobileTimesheetTab> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  List<CalendarDay> _calendar = [];
  List<Mission> _availableMissions = [];
  MonthlyStats _stats = MonthlyStats.empty();
  bool _isLoading = true;
  bool _isSaving = false;
  DateTime _selectedMonth = DateTime.now();
  UserRole? _userRole;

  // Contrôleurs pour les saisies
  final Map<String, double?> _selectedDays = {};
  final Map<String, String?> _selectedMissions = {};

  // Suivi des modifications
  final Set<String> _modifiedDays = {};

  // Partenaires: uniquement saisie du temps (pas de tarifs ni reporting)
  bool get _isPartner => _userRole == UserRole.partenaire;
  int get _tabCount => _isPartner ? 1 : 3;

  @override
  void initState() {
    super.initState();
    _initializeWithRole();
  }

  Future<void> _initializeWithRole() async {
    _userRole = SupabaseService.currentUserRole ?? await SupabaseService.getCurrentUserRole();
    debugPrint('📱 MobileTimesheetTab: Rôle = $_userRole, isPartner = $_isPartner');

    _tabController = TabController(length: _tabCount, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
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
        MissionService.getAvailableMissionsForTimesheet(
          partnerId: partnerId,
          date: _selectedMonth,
        ),
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
    // Afficher un chargement si le tabController n'est pas encore initialisé
    if (_tabController == null) {
      return Scaffold(
        backgroundColor: AppTheme.colors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      appBar: AppBar(
        backgroundColor: AppTheme.colors.surface,
        elevation: 0,
        title: Text('Timesheet', style: AppTheme.typography.h3.copyWith(color: AppTheme.colors.textPrimary)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppTheme.colors.primary),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/profile');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isPartner
          ? _buildTimeEntryTab() // Partenaire: uniquement saisie du temps
          : Column(
              children: [
                // Tabs visibles uniquement pour associés/admins
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
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        DefaultTextStyle(
          style: TextStyle(
            decoration: TextDecoration.none,
            color: AppTheme.colors.textPrimary,
            fontFamily: AppTheme.typography.bodyMedium.fontFamily,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Espace pour le bouton
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
                        IconButton(
                          icon: Icon(Icons.chevron_left, color: AppTheme.colors.primary),
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
                        IconButton(
                          icon: Icon(Icons.chevron_right, color: AppTheme.colors.primary),
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
        ),
        // Bouton de sauvegarde flottant
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: _buildSaveButton(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    final hasModifications = _modifiedDays.isNotEmpty;

    return AnimatedOpacity(
      opacity: hasModifications ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveAllEntries,
          style: ElevatedButton.styleFrom(
            backgroundColor: hasModifications
                ? const Color(0xFF10B981) // Vert émeraude
                : Colors.grey[400]!,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isSaving)
                const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              else ...[
                const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  hasModifications
                      ? 'Sauvegarder (${_modifiedDays.length})'
                      : 'Sauvegarder',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
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
            icon: Icons.access_time,
            value: '${_stats.totalDays.toStringAsFixed(1)} j',
            label: 'Jours totaux',
            color: const Color(0xFF3B82F6), // Bleu
          ),
        ),
        SizedBox(width: AppTheme.spacing.sm),
        Expanded(
          child: _buildKPICard(
            icon: Icons.euro,
            value: '${_stats.totalAmount.toStringAsFixed(2)} €',
            label: 'Montant total',
            color: const Color(0xFF10B981), // Vert
          ),
        ),
        SizedBox(width: AppTheme.spacing.sm),
        Expanded(
          child: _buildKPICard(
            icon: Icons.calendar_today,
            value: _calendar.where((d) => d.hasEntry && d.entry!.days > 0).length.toStringAsFixed(1),
            label: 'Jours saisis',
            color: const Color(0xFFF59E0B), // Orange
          ),
        ),
        SizedBox(width: AppTheme.spacing.sm),
        Expanded(
          child: _buildKPICard(
            icon: Icons.bar_chart,
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

    return InkWell(
      onTap: () => _showMissionPicker(day, key),
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
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppTheme.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDaysDropdown(CalendarDay day, String key) {
    final selectedDays = _selectedDays[key];

    return InkWell(
      onTap: () => _showDaysPicker(day, key),
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
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppTheme.colors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showMissionPicker(CalendarDay day, String key) {
    debugPrint('📱 Ouverture picker mission - ${_availableMissions.length} missions disponibles');

    if (_availableMissions.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aucune mission disponible'),
          content: const Text(
            'Aucune mission ne vous est assignée pour le moment.\n\n'
            'Contactez votre associé pour vous faire assigner une mission.',
          ),
          actions: [
            TextButton(
              child: const Text('Recharger'),
              onPressed: () {
                Navigator.pop(context);
                _loadData();
              },
            ),
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Sélectionner une mission (${_availableMissions.length})', style: AppTheme.typography.h4),
            ),
            const Divider(height: 1),
            ..._availableMissions.map((mission) {
              final subtitle = mission.companyName != null
                  ? ' - ${mission.companyName}'
                  : '';
              return ListTile(
                title: Text(mission.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: subtitle.isNotEmpty ? Text(subtitle.substring(3)) : null,
                onTap: () {
                  setState(() {
                    _selectedMissions[key] = mission.id;
                    _modifiedDays.add(key);
                  });
                  Navigator.pop(context);
                },
              );
            }),
            ListTile(title: const Text('Annuler'), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showDaysPicker(CalendarDay day, String key) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Sélectionner les jours', style: AppTheme.typography.h4),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('0.5 jour'),
              onTap: () {
                setState(() {
                  _selectedDays[key] = 0.5;
                  _modifiedDays.add(key);
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('1.0 jour'),
              onTap: () {
                setState(() {
                  _selectedDays[key] = 1.0;
                  _modifiedDays.add(key);
                });
                Navigator.pop(context);
              },
            ),
            ListTile(title: const Text('Annuler'), onTap: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  /// Sauvegarde toutes les entrées modifiées
  Future<void> _saveAllEntries() async {
    if (_modifiedDays.isEmpty) {
      _showQuickSnackBar('Aucune modification à sauvegarder', AppTheme.colors.textSecondary);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final partnerId = SupabaseService.currentUser?.id;
      if (partnerId == null) throw Exception('Utilisateur non connecté');

      debugPrint('💾 Début sauvegarde - Partner: $partnerId');
      debugPrint('💾 Jours modifiés: ${_modifiedDays.length}');

      final userCompany = await CompanyService.getUserCompany();
      final companyId = userCompany?['company_id'];
      debugPrint('💾 Company ID: $companyId');

      int savedCount = 0;
      int errorCount = 0;
      String? lastError;

      for (final key in _modifiedDays.toList()) {
        final missionId = _selectedMissions[key];
        final days = _selectedDays[key];

        debugPrint('💾 Traitement: $key - Mission: $missionId, Jours: $days');

        // Skip si pas de mission ou de jours sélectionnés
        if (missionId == null || days == null) {
          debugPrint('⚠️ Skip - mission ou jours null');
          continue;
        }

        // Trouver la mission pour récupérer le tarif
        final mission = _availableMissions.firstWhere(
          (m) => m.id == missionId,
          orElse: () => Mission(
            id: '',
            title: '',
            startDate: DateTime.now(),
            status: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

        if (mission.id.isEmpty) {
          debugPrint('⚠️ Skip - mission non trouvée');
          continue;
        }

        // Trouver le jour correspondant dans le calendrier
        final day = _calendar.firstWhere(
          (d) => d.date.toIso8601String() == key,
          orElse: () => CalendarDay(
            date: DateTime.now(),
            dayName: '',
            dayNumber: 0,
            isWeekend: false,
            weekNumber: 0,
          ),
        );

        final entryDate = day.date.toIso8601String().split('T')[0];
        final dailyRate = mission.dailyRate ?? 0.0;

        try {
          if (day.hasEntry && day.entry!.id.isNotEmpty) {
            // Mise à jour d'une entrée existante
            debugPrint('📝 UPDATE entry: ${day.entry!.id}');

            await SupabaseService.client
                .from('timesheet_entries')
                .update({
              'mission_id': missionId,
              'days': days,
              'daily_rate': dailyRate,
            }).eq('id', day.entry!.id);

            debugPrint('✅ UPDATE réussi');
          } else {
            // Création d'une nouvelle entrée
            debugPrint('📝 INSERT new entry');

            final insertData = {
              'partner_id': partnerId,
              'mission_id': missionId,
              'entry_date': entryDate,
              'days': days,
              'daily_rate': dailyRate,
              'is_weekend': day.isWeekend,
              'status': 'draft',
            };

            // Ajouter company_id seulement s'il existe
            if (companyId != null) {
              insertData['company_id'] = companyId;
            }

            await SupabaseService.client
                .from('timesheet_entries')
                .insert(insertData);

            debugPrint('✅ INSERT réussi');
          }
          savedCount++;
        } catch (e) {
          debugPrint('❌ Erreur sauvegarde $key: $e');
          lastError = e.toString();
          errorCount++;
        }
      }

      // Effacer les modifications après sauvegarde réussie
      if (savedCount > 0) {
        _modifiedDays.clear();
      }

      // Recharger les données
      await _loadData();

      // Afficher le résultat
      if (errorCount == 0 && savedCount > 0) {
        _showQuickSnackBar('$savedCount entrée(s) sauvegardée(s) ✓', AppTheme.colors.success);
      } else if (errorCount > 0) {
        _showQuickSnackBar('Erreur: $lastError', AppTheme.colors.error);
      } else {
        _showQuickSnackBar('Aucune entrée valide à sauvegarder', AppTheme.colors.warning);
      }

    } catch (e) {
      debugPrint('❌ Erreur sauvegarde globale: $e');
      _showQuickSnackBar('Erreur: $e', AppTheme.colors.error);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showQuickSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Widget _buildRatesTab() {
    return const Center(child: Text('Tarifs'));
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
}
