// ============================================================================
// MOBILE PARTNER AVAILABILITY TAB - OXO TIME SHEETS
// Tab Disponibilités pour les Partenaires iOS
// Utilise STRICTEMENT AppTheme (pas IOSTheme)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/app_theme.dart';
import '../../../config/app_icons.dart';
import '../../../services/supabase_service.dart';
import '../../../services/notification_service.dart';

class MobilePartnerAvailabilityTab extends StatefulWidget {
  const MobilePartnerAvailabilityTab({Key? key}) : super(key: key);

  @override
  State<MobilePartnerAvailabilityTab> createState() => _MobilePartnerAvailabilityTabState();
}

class _MobilePartnerAvailabilityTabState extends State<MobilePartnerAvailabilityTab> {
  List<Map<String, dynamic>> _availabilities = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadNotificationsCount();
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
      final partnerId = SupabaseService.currentUser?.id;
      if (partnerId == null) throw Exception('Utilisateur non connecté');

      final response = await SupabaseService.client
          .from('partner_availability')
          .select()
          .eq('partner_id', partnerId)
          .gte('date', DateTime(_selectedMonth.year, _selectedMonth.month, 1).toIso8601String())
          .lt('date', DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1).toIso8601String())
          .order('date');

      setState(() {
        _availabilities = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement disponibilités: $e');
      setState(() => _isLoading = false);
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
      backgroundColor: AppTheme.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildMonthSelector(),
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.colors.primary,
                        strokeWidth: 2,
                      ),
                    )
                  : _buildCalendarGrid(),
            ),
          ],
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
            'Disponibilités',
            style: AppTheme.typography.h1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.colors.textPrimary,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/messaging');
            },
            icon: Stack(
              children: [
                Icon(
                  AppIcons.notifications,
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
                      constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.spacing.sm),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pushNamed('/profile');
            },
            icon: Icon(
              AppIcons.settings,
              color: AppTheme.colors.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
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
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      child: Column(
        children: [
          // En-têtes des jours
          Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: AppTheme.typography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.colors.textSecondary,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          ...List.generate(6, (weekIndex) {
            return Padding(
              padding: EdgeInsets.only(bottom: AppTheme.spacing.xs),
              child: Row(
                children: List.generate(7, (dayIndex) {
                  final dayNumber = weekIndex * 7 + dayIndex - (firstWeekday - 2);
                  if (dayNumber < 1 || dayNumber > daysInMonth) {
                    return Expanded(child: Container());
                  }
                  return Expanded(child: _buildDayCell(dayNumber));
                }),
              ),
            );
          }),
          SizedBox(height: AppTheme.spacing.lg),
          _buildLegend(),
          SizedBox(height: AppTheme.spacing.lg),
          _buildUpdateButton(),
        ],
      ),
    );
  }

  Widget _buildDayCell(int day) {
    final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isWeekend = date.weekday == 6 || date.weekday == 7;

    final availability = _availabilities.firstWhere(
      (a) => DateUtils.isSameDay(DateTime.parse(a['date']), date),
      orElse: () => <String, dynamic>{},
    );

    final status = availability['status'] as String?;

    Color bgColor;
    Color textColor = AppTheme.colors.textPrimary;

    if (status == 'available') {
      bgColor = AppTheme.colors.success.withOpacity(0.3);
    } else if (status == 'partial') {
      bgColor = AppTheme.colors.warning.withOpacity(0.3);
    } else if (status == 'unavailable') {
      bgColor = AppTheme.colors.error.withOpacity(0.3);
    } else if (isWeekend) {
      bgColor = AppTheme.colors.background;
      textColor = AppTheme.colors.textSecondary;
    } else {
      bgColor = AppTheme.colors.surface;
    }

    return GestureDetector(
      onTap: () => _showAvailabilityPicker(date, status),
      child: Container(
        margin: const EdgeInsets.all(2),
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday
              ? Border.all(color: AppTheme.colors.primary, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: AppTheme.typography.bodyMedium.copyWith(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: textColor,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: AppTheme.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radius.medium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Légende',
            style: AppTheme.typography.h4.copyWith(
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          SizedBox(height: AppTheme.spacing.sm),
          Row(
            children: [
              _buildLegendItem('Disponible', AppTheme.colors.success),
              SizedBox(width: AppTheme.spacing.md),
              _buildLegendItem('Partiel', AppTheme.colors.warning),
              SizedBox(width: AppTheme.spacing.md),
              _buildLegendItem('Indisponible', AppTheme.colors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: AppTheme.spacing.xs),
        Text(
          label,
          style: AppTheme.typography.bodySmall.copyWith(
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.colors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radius.medium)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      onPressed: _showBulkUpdateDialog,
      icon: const Icon(Icons.calendar_today, color: Colors.white),
      label: Text(
        'Mettre à jour mes disponibilités',
        style: AppTheme.typography.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showAvailabilityPicker(DateTime date, String? currentStatus) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Disponibilité du ${DateFormat('dd/MM/yyyy').format(date)}',
                style: AppTheme.typography.h4,
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.check_circle, color: AppTheme.colors.success),
              title: const Text('Disponible'),
              onTap: () {
                Navigator.pop(context);
                _updateAvailability(date, 'available');
              },
            ),
            ListTile(
              leading: Icon(Icons.remove_circle, color: AppTheme.colors.warning),
              title: const Text('Partiellement disponible'),
              onTap: () {
                Navigator.pop(context);
                _updateAvailability(date, 'partial');
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: AppTheme.colors.error),
              title: const Text('Indisponible'),
              onTap: () {
                Navigator.pop(context);
                _updateAvailability(date, 'unavailable');
              },
            ),
            ListTile(
              title: const Text('Annuler'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateAvailability(DateTime date, String status) async {
    try {
      final partnerId = SupabaseService.currentUser?.id;
      if (partnerId == null) return;

      await SupabaseService.client
          .from('partner_availability')
          .upsert({
            'partner_id': partnerId,
            'date': date.toIso8601String().split('T')[0],
            'status': status,
          }, onConflict: 'partner_id,date');

      await _loadData();
    } catch (e) {
      debugPrint('❌ Erreur mise à jour disponibilité: $e');
    }
  }

  void _showBulkUpdateDialog() {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    String selectedStatus = 'available';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          child: SafeArea(
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300]!,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: Text('Annuler', style: TextStyle(color: AppTheme.colors.textSecondary, fontSize: 16)),
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                      const Text(
                        'Mise à jour en masse',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                      ),
                      TextButton(
                        child: Text('Appliquer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: AppTheme.colors.primary)),
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          await _applyBulkUpdate(startDate, endDate, selectedStatus);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date de début
                        Text('Date de début', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.colors.textSecondary)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setDialogState(() => startDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.colors.inputBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: AppTheme.colors.textSecondary),
                                const SizedBox(width: 10),
                                Text(DateFormat('dd/MM/yyyy').format(startDate)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Date de fin
                        Text('Date de fin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.colors.textSecondary)),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setDialogState(() => endDate = picked);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.colors.inputBackground,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18, color: AppTheme.colors.textSecondary),
                                const SizedBox(width: 10),
                                Text(DateFormat('dd/MM/yyyy').format(endDate)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Statut
                        Text('Disponibilité', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.colors.textSecondary)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _buildStatusButton('available', 'Dispo', selectedStatus, AppTheme.colors.success, (s) => setDialogState(() => selectedStatus = s)),
                            const SizedBox(width: 8),
                            _buildStatusButton('partial', 'Partiel', selectedStatus, AppTheme.colors.warning, (s) => setDialogState(() => selectedStatus = s)),
                            const SizedBox(width: 8),
                            _buildStatusButton('unavailable', 'Indispo', selectedStatus, AppTheme.colors.error, (s) => setDialogState(() => selectedStatus = s)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.colors.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: AppTheme.colors.info, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Cette action mettra à jour ${endDate.difference(startDate).inDays + 1} jours.',
                                  style: TextStyle(fontSize: 13, color: AppTheme.colors.info),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusButton(String value, String label, String currentValue, Color color, Function(String) onSelect) {
    final isSelected = currentValue == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelect(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : AppTheme.colors.inputBackground,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.colors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _applyBulkUpdate(DateTime startDate, DateTime endDate, String status) async {
    try {
      final partnerId = SupabaseService.currentUser?.id;
      if (partnerId == null) return;

      final List<Map<String, dynamic>> updates = [];
      DateTime current = startDate;

      while (!current.isAfter(endDate)) {
        updates.add({
          'partner_id': partnerId,
          'date': current.toIso8601String().split('T')[0],
          'status': status,
        });
        current = current.add(const Duration(days: 1));
      }

      for (final update in updates) {
        await SupabaseService.client
            .from('partner_availability')
            .upsert(update, onConflict: 'partner_id,date');
      }

      await _loadData();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mise à jour réussie'),
            content: Text('${updates.length} jours ont été mis à jour.'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur mise à jour en masse: $e');
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de la mise à jour: $e'),
            actions: [
              TextButton(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      }
    }
  }
}
