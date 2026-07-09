// lib/pages/shared/planning_page.dart
//
// Planning : calendrier mensuel + tâches du jour sélectionné.
// - Sur desktop, la page vit dans le DesktopShell (pas d'AppBar propre).
// - Sur iOS, une AppBar avec retour est affichée si la page est poussée.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../utils/device_detector.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoading = true;
  String? _error;

  static const _weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    if (SupabaseService.currentUser == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = SupabaseService.currentUser!.id;
      final response = await SupabaseService.client
          .from('tasks')
          .select('*, missions:mission_id (title, status)')
          .eq('assigned_to', userId);

      if (mounted) {
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('PlanningPage: erreur de chargement: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Impossible de charger le planning.';
        });
      }
    }
  }

  List<Map<String, dynamic>> _tasksForDay(DateTime day) {
    return _tasks.where((t) {
      final raw = t['due_date'];
      if (raw == null) return false;
      final d = DateTime.tryParse(raw.toString());
      return d != null &&
          d.year == day.year &&
          d.month == day.month &&
          d.day == day.day;
    }).toList();
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _goToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = now;
      _visibleMonth = DateTime(now.year, now.month);
    });
  }

  // ══════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isIOS = DeviceDetector.shouldUseIOSInterface();

    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _buildErrorState()
            : LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth > 900;
                  final calendar = _buildCalendarCard();
                  final dayPanel = _buildDayPanel();
                  if (wide) {
                    return Padding(
                      padding: EdgeInsets.all(AppTheme.spacing.lg),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: calendar),
                          SizedBox(width: AppTheme.spacing.lg),
                          Expanded(flex: 2, child: dayPanel),
                        ],
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(AppTheme.spacing.md),
                    child: Column(
                      children: [
                        calendar,
                        SizedBox(height: AppTheme.spacing.md),
                        dayPanel,
                      ],
                    ),
                  );
                },
              );

    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      appBar: isIOS
          ? AppBar(title: const Text('Planning'))
          : null, // sur desktop, le DesktopShell fournit topbar + retour
      body: SafeArea(child: body),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 48, color: AppTheme.colors.textSecondary),
          SizedBox(height: AppTheme.spacing.md),
          Text(_error!, style: AppTheme.typography.bodyLarge),
          SizedBox(height: AppTheme.spacing.md),
          FilledButton.icon(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // CALENDRIER
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildCalendarCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.lg),
        child: Column(
          children: [
            // Navigation de mois
            Row(
              children: [
                Text(
                  toBeginningOfSentenceCase(
                    DateFormat('MMMM yyyy', 'fr_FR').format(_visibleMonth),
                  )!,
                  style: AppTheme.typography.h3,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _goToday,
                  child: const Text("Aujourd'hui"),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Mois précédent',
                  onPressed: () => _changeMonth(-1),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Mois suivant',
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing.md),

            // En-têtes des jours
            Row(
              children: _weekdays
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: AppTheme.typography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.colors.textSecondary,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            SizedBox(height: AppTheme.spacing.sm),

            // Grille des jours
            ..._buildWeeks(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWeeks() {
    final firstDay = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final leading = firstDay.weekday - 1; // lundi = 0 cases vides
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;

    final weeks = <Widget>[];
    for (var week = 0; week < totalCells / 7; week++) {
      final cells = <Widget>[];
      for (var i = 0; i < 7; i++) {
        final cellIndex = week * 7 + i;
        final dayNumber = cellIndex - leading + 1;
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          cells.add(const Expanded(child: SizedBox()));
          continue;
        }
        final date =
            DateTime(_visibleMonth.year, _visibleMonth.month, dayNumber);
        cells.add(Expanded(child: _buildDayCell(date)));
      }
      weeks.add(Row(children: cells));
    }
    return weeks;
  }

  Widget _buildDayCell(DateTime date) {
    final now = DateTime.now();
    final isToday = date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
    final isSelected = date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day;
    final taskCount = _tasksForDay(date).length;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius.small),
        onTap: () => setState(() => _selectedDate = date),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.colors.primary
                : isToday
                    ? AppTheme.colors.primary.withOpacity(0.08)
                    : null,
            borderRadius: BorderRadius.circular(AppTheme.radius.small),
            border: isToday && !isSelected
                ? Border.all(color: AppTheme.colors.primary, width: 1)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date.day}',
                style: AppTheme.typography.bodyMedium.copyWith(
                  fontWeight: isToday || isSelected
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isSelected
                      ? AppTheme.colors.textOnPrimary
                      : AppTheme.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              // Pastille du nombre de tâches
              if (taskCount > 0)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppTheme.colors.textOnPrimary
                        : AppTheme.colors.secondary,
                  ),
                )
              else
                const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // PANNEAU DU JOUR
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildDayPanel() {
    final tasks = _tasksForDay(_selectedDate);
    final title = toBeginningOfSentenceCase(
      DateFormat('EEEE d MMMM', 'fr_FR').format(_selectedDate),
    )!;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppTheme.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(title, style: AppTheme.typography.h3)),
                Text(
                  '${tasks.length} tâche${tasks.length > 1 ? 's' : ''}',
                  style: AppTheme.typography.bodyMedium.copyWith(
                    color: AppTheme.colors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppTheme.spacing.md),
            if (tasks.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.event_available,
                          size: 40, color: AppTheme.colors.textSecondary),
                      SizedBox(height: AppTheme.spacing.sm),
                      Text(
                        'Aucune tâche prévue ce jour.',
                        style: AppTheme.typography.bodyMedium.copyWith(
                          color: AppTheme.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...tasks.map(_buildTaskTile),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTile(Map<String, dynamic> task) {
    final status = task['status']?.toString();
    final missionTitle =
        (task['missions'] as Map?)?['title']?.toString() ?? 'Sans mission';

    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: AppTheme.colors.background,
        borderRadius: BorderRadius.circular(AppTheme.radius.small),
        border: Border.all(color: AppTheme.colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: _statusColor(status),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: AppTheme.spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task['title']?.toString() ?? 'Sans titre',
                  style: AppTheme.typography.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  missionTitle,
                  style: AppTheme.typography.bodyMedium.copyWith(
                    color: AppTheme.colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusText(status),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _statusColor(status),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'in_progress':
        return const Color(0xFFFF9800);
      case 'done':
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'urgent':
        return const Color(0xFFE53935);
      default:
        return AppTheme.colors.primary;
    }
  }

  String _statusText(String? status) {
    switch (status) {
      case 'pending':
      case 'todo':
        return 'À faire';
      case 'in_progress':
        return 'En cours';
      case 'done':
      case 'completed':
        return 'Terminé';
      case 'urgent':
        return 'Urgent';
      default:
        return 'À faire';
    }
  }
}
