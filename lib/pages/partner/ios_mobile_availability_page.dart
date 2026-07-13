import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/app_theme.dart';
import '../../services/supabase_service.dart';
import '../../services/availability_service.dart';

class IOSMobileAvailabilityPage extends StatefulWidget {
  final bool showHeader;

  const IOSMobileAvailabilityPage({
    Key? key,
    this.showHeader = true,
  }) : super(key: key);

  @override
  State<IOSMobileAvailabilityPage> createState() => _IOSMobileAvailabilityPageState();
}

class _IOSMobileAvailabilityPageState extends State<IOSMobileAvailabilityPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _availabilities = [];
  bool _isLoading = true;
  DateTime _currentDate = DateTime.now();
  bool _isMonthView = false;

  List<Map<String, dynamic>> _partners = [];
  Map<String, dynamic>? _selectedPartner;
  List<Map<String, dynamic>> _partnerAvailabilities = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final now = DateTime.now();
    _currentDate = now.subtract(Duration(days: now.weekday - 1));
    _loadAvailabilities();
    _loadPartners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  DateTime get _weekStart =>
      _currentDate.subtract(Duration(days: _currentDate.weekday - 1));

  DateTime get _monthStart =>
      DateTime(_currentDate.year, _currentDate.month, 1);

  Future<void> _loadAvailabilities() async {
    setState(() => _isLoading = true);
    try {
      final startDate = _isMonthView
          ? _monthStart
          : _weekStart;
      final endDate = _isMonthView
          ? DateTime(_currentDate.year, _currentDate.month + 1, 0)
          : _weekStart.add(const Duration(days: 6));

      final availabilities = await AvailabilityService.getPartnerOwnAvailability(
        startDate: startDate,
        endDate: endDate,
      );
      if (mounted) setState(() { _availabilities = availabilities; _isLoading = false; });
    } catch (e) {
      debugPrint('Erreur chargement disponibilités: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPartners() async {
    try {
      final partners = await SupabaseService.getPartners();
      if (mounted) setState(() { _partners = partners; });
    } catch (e) {
      debugPrint('Erreur chargement partenaires: $e');
    }
  }

  Future<void> _loadPartnerAvailabilities() async {
    if (_selectedPartner == null) return;
    setState(() => _isLoading = true);
    try {
      final startDate = _isMonthView ? _monthStart : _weekStart;
      final endDate = _isMonthView
          ? DateTime(_currentDate.year, _currentDate.month + 1, 0)
          : _weekStart.add(const Duration(days: 6));
      final partnerId = _selectedPartner!['user_id']?.toString() ?? '';
      final response = await SupabaseService.client
          .from('partner_availability')
          .select('*')
          .eq('partner_id', partnerId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date');
      if (mounted) setState(() { _partnerAvailabilities = List<Map<String, dynamic>>.from(response); _isLoading = false; });
    } catch (e) {
      debugPrint('Erreur chargement disponibilités partenaire: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToPreviousPeriod() {
    setState(() {
      _currentDate = _isMonthView
          ? DateTime(_currentDate.year, _currentDate.month - 1, 1)
          : _currentDate.subtract(const Duration(days: 7));
    });
    _tabController.index == 0 ? _loadAvailabilities() : _loadPartnerAvailabilities();
  }

  void _goToNextPeriod() {
    setState(() {
      _currentDate = _isMonthView
          ? DateTime(_currentDate.year, _currentDate.month + 1, 1)
          : _currentDate.add(const Duration(days: 7));
    });
    _tabController.index == 0 ? _loadAvailabilities() : _loadPartnerAvailabilities();
  }

  void _goToToday() {
    setState(() {
      final now = DateTime.now();
      _currentDate = now.subtract(Duration(days: now.weekday - 1));
    });
    _tabController.index == 0 ? _loadAvailabilities() : _loadPartnerAvailabilities();
  }

  void _toggleViewMode() {
    setState(() { _isMonthView = !_isMonthView; });
    _tabController.index == 0 ? _loadAvailabilities() : _loadPartnerAvailabilities();
  }

  Widget _buildTabs() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppTheme.colors.primary,
          unselectedLabelColor: AppTheme.colors.textSecondary,
          indicatorColor: AppTheme.colors.primary,
          onTap: (_) => setState(() {}),
          tabs: const [
            Tab(text: 'Mes disponibilités'),
            Tab(text: 'Partenaires'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMyAvailabilityTab(),
              _buildPartnersAvailabilityTab(),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showHeader) {
      return Container(
        color: AppTheme.colors.background,
        child: _buildTabs(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.colors.background,
      appBar: AppBar(
        title: const Text('Disponibilités'),
        backgroundColor: AppTheme.colors.surface,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _showQuickActions,
            child: Text('Ajouter', style: TextStyle(color: AppTheme.colors.primary)),
          ),
        ],
      ),
      body: _buildTabs(),
    );
  }

  // ============================================
  // ONGLET MES DISPONIBILITÉS
  // ============================================

  Widget _buildMyAvailabilityTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppTheme.colors.primary, strokeWidth: 2));
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildNavigationHeader(),
          const SizedBox(height: 16),
          _buildPeriodInfo(),
          const SizedBox(height: 20),
          _isMonthView ? _buildMonthlyCalendar() : _buildWeeklyCalendar(),
          const SizedBox(height: 24),
          _buildActionButtons(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavigationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _goToPreviousPeriod,
            icon: Icon(Icons.chevron_left, color: AppTheme.colors.primary),
          ),
          Row(
            children: [
              _navButton("Aujourd'hui", _goToToday, false),
              const SizedBox(width: 8),
              _navButton(
                _isMonthView ? 'Mois' : 'Semaine',
                _toggleViewMode,
                _isMonthView,
                icon: Icons.calendar_today,
              ),
            ],
          ),
          IconButton(
            onPressed: _goToNextPeriod,
            icon: Icon(Icons.chevron_right, color: AppTheme.colors.primary),
          ),
        ],
      ),
    );
  }

  Widget _navButton(String label, VoidCallback onTap, bool active, {IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppTheme.colors.primary : AppTheme.colors.inputBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: active ? Colors.white : AppTheme.colors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppTheme.colors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodInfo() {
    final weekDays = List.generate(7, (index) => _weekStart.add(Duration(days: index)));
    final availableDays = weekDays.where((day) {
      return _getAvailabilityForDate(day, _availabilities)['is_available'] == true;
    }).length;

    final periodText = _isMonthView
        ? DateFormat('MMMM yyyy', 'fr_FR').format(_currentDate)
        : 'Semaine du ${DateFormat('d', 'fr_FR').format(_weekStart)} au ${DateFormat('d MMMM', 'fr_FR').format(_weekStart.add(const Duration(days: 6)))}';

    return Column(
      children: [
        Text(periodText, style: AppTheme.typography.h4.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.colors.inputBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$availableDays jours disponibles',
            style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendar() {
    final weekDays = List.generate(7, (index) => _weekStart.add(Duration(days: index)));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: weekDays.map((day) => Expanded(
              child: Center(
                child: Text(
                  DateFormat('EEE', 'fr_FR').format(day),
                  style: AppTheme.typography.caption.copyWith(color: AppTheme.colors.textSecondary),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: weekDays.map((day) => Expanded(
              child: _buildDayCard(day, _availabilities, canEdit: true),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;

    List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(7, null);

    for (int i = 0; i < firstWeekday - 1; i++) { currentWeek[i] = null; }

    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentDate.year, _currentDate.month, day);
      final weekdayIndex = date.weekday - 1;
      currentWeek[weekdayIndex] = date;
      if (weekdayIndex == 6) { weeks.add(currentWeek); currentWeek = List.filled(7, null); }
    }
    if (currentWeek.any((d) => d != null)) weeks.add(currentWeek);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((day) => Expanded(
              child: Center(child: Text(day, style: AppTheme.typography.caption.copyWith(color: AppTheme.colors.textSecondary))),
            )).toList(),
          ),
          const SizedBox(height: 8),
          ...weeks.map((week) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: week.map((day) => Expanded(
                child: day != null
                    ? _buildMonthDayCard(day, _availabilities, canEdit: true)
                    : const SizedBox(height: 48),
              )).toList(),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDayCard(DateTime day, List<Map<String, dynamic>> availabilities, {bool canEdit = false}) {
    final availability = _getAvailabilityForDate(day, availabilities);
    final isAvailable = availability['is_available'] == true;
    final isToday = _isToday(day);
    final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    Color backgroundColor;
    Widget icon;

    if (isPast) {
      backgroundColor = AppTheme.colors.inputBackground;
      icon = Icon(Icons.remove, color: AppTheme.colors.textSecondary, size: 18);
    } else if (availability.isNotEmpty) {
      if (isAvailable) {
        backgroundColor = AppTheme.colors.success;
        icon = const Icon(Icons.check, color: Colors.white, size: 18);
      } else {
        backgroundColor = AppTheme.colors.error.withOpacity(0.15);
        icon = Icon(Icons.close, color: AppTheme.colors.error, size: 18);
      }
    } else {
      backgroundColor = AppTheme.colors.inputBackground;
      icon = Icon(Icons.remove, color: AppTheme.colors.textSecondary, size: 18);
    }

    return GestureDetector(
      onTap: (canEdit && !isPast) ? () => _editDay(day, availability) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 100,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday ? Border.all(color: AppTheme.colors.primary, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isAvailable ? Colors.white : AppTheme.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: isAvailable ? Colors.white.withOpacity(0.3) : backgroundColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(child: icon),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthDayCard(DateTime day, List<Map<String, dynamic>> availabilities, {bool canEdit = false}) {
    final availability = _getAvailabilityForDate(day, availabilities);
    final isAvailable = availability['is_available'] == true;
    final isToday = _isToday(day);
    final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    Color backgroundColor;
    Color textColor;

    if (isPast) {
      backgroundColor = AppTheme.colors.inputBackground;
      textColor = AppTheme.colors.textSecondary;
    } else if (availability.isNotEmpty) {
      if (isAvailable) {
        backgroundColor = AppTheme.colors.success;
        textColor = Colors.white;
      } else {
        backgroundColor = AppTheme.colors.error.withOpacity(0.15);
        textColor = AppTheme.colors.error;
      }
    } else {
      backgroundColor = AppTheme.colors.inputBackground;
      textColor = AppTheme.colors.textPrimary;
    }

    return GestureDetector(
      onTap: (canEdit && !isPast) ? () => _editDay(day, availability) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: AppTheme.colors.primary, width: 2) : null,
        ),
        child: Center(
          child: Text('${day.day}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _showBulkAvailabilityDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Définir mes disponibilités', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _createDefaultAvailabilities,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Auto-remplir', style: TextStyle(color: AppTheme.colors.textPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _setWeekendUnavailable,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Week-ends occupés', style: TextStyle(color: AppTheme.colors.textPrimary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // ONGLET PARTENAIRES
  // ============================================

  Widget _buildPartnersAvailabilityTab() {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildPartnerSelector(),
        const SizedBox(height: 16),
        if (_selectedPartner == null)
          _buildNoPartnerSelected()
        else
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildNavigationHeader(),
                  const SizedBox(height: 16),
                  _buildPartnerPeriodInfo(),
                  const SizedBox(height: 20),
                  _isMonthView
                      ? _buildPartnerMonthlyCalendar()
                      : _buildPartnerWeeklyCalendar(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPartnerSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _showPartnerPicker,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppTheme.colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.colors.border),
          ),
          child: Row(
            children: [
              Icon(Icons.people, color: AppTheme.colors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedPartner != null
                      ? '${_selectedPartner!['first_name'] ?? ''} ${_selectedPartner!['last_name'] ?? ''}'.trim()
                      : 'Sélectionner un partenaire',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedPartner != null ? AppTheme.colors.textPrimary : AppTheme.colors.textSecondary,
                  ),
                ),
              ),
              Icon(Icons.keyboard_arrow_down, color: AppTheme.colors.textSecondary, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showPartnerPicker() {
    if (_partners.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Aucun partenaire'),
          content: const Text('Aucun partenaire n\'est disponible.'),
          actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(child: const Text('Annuler'), onPressed: () => Navigator.pop(context)),
                  Text('Choisir un partenaire', style: AppTheme.typography.h4),
                  const SizedBox(width: 70),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _partners.length,
                itemBuilder: (context, index) {
                  final partner = _partners[index];
                  final name = '${partner['first_name'] ?? ''} ${partner['last_name'] ?? ''}'.trim();
                  final email = partner['email'] ?? partner['user_email'] ?? '';
                  final isSelected = _selectedPartner?['user_id'] == partner['user_id'];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.colors.primary.withOpacity(0.2),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(color: AppTheme.colors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                    title: Text(name.isNotEmpty ? name : 'Partenaire'),
                    subtitle: email.isNotEmpty ? Text(email) : null,
                    trailing: isSelected ? Icon(Icons.check, color: AppTheme.colors.primary) : null,
                    selected: isSelected,
                    onTap: () {
                      setState(() { _selectedPartner = partner; });
                      Navigator.pop(context);
                      _loadPartnerAvailabilities();
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPartnerSelected() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, size: 64, color: AppTheme.colors.textSecondary),
              const SizedBox(height: 16),
              Text('Sélectionnez un partenaire', style: AppTheme.typography.h3.copyWith(color: AppTheme.colors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                'Choisissez un partenaire dans la liste\npour voir ses disponibilités',
                textAlign: TextAlign.center,
                style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPartnerPeriodInfo() {
    final name = '${_selectedPartner?['first_name'] ?? ''} ${_selectedPartner?['last_name'] ?? ''}'.trim();
    final weekDays = List.generate(7, (index) => _weekStart.add(Duration(days: index)));
    final availableDays = weekDays.where((day) {
      return _getAvailabilityForDate(day, _partnerAvailabilities)['is_available'] == true;
    }).length;

    final periodText = _isMonthView
        ? DateFormat('MMMM yyyy', 'fr_FR').format(_currentDate)
        : 'Semaine du ${DateFormat('d', 'fr_FR').format(_weekStart)} au ${DateFormat('d MMMM', 'fr_FR').format(_weekStart.add(const Duration(days: 6)))}';

    return Column(
      children: [
        Text(name.isNotEmpty ? name : 'Partenaire', style: AppTheme.typography.h3),
        const SizedBox(height: 8),
        Text(periodText, style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: AppTheme.colors.inputBackground, borderRadius: BorderRadius.circular(20)),
          child: Text('$availableDays jours disponibles', style: AppTheme.typography.bodyMedium.copyWith(color: AppTheme.colors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildPartnerWeeklyCalendar() {
    final weekDays = List.generate(7, (index) => _weekStart.add(Duration(days: index)));
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: weekDays.map((day) => Expanded(
              child: Center(child: Text(DateFormat('EEE', 'fr_FR').format(day), style: AppTheme.typography.caption.copyWith(color: AppTheme.colors.textSecondary))),
            )).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: weekDays.map((day) => Expanded(
              child: _buildDayCard(day, _partnerAvailabilities, canEdit: false),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerMonthlyCalendar() {
    final firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    final lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;

    List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(7, null);
    for (int i = 0; i < firstWeekday - 1; i++) { currentWeek[i] = null; }
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentDate.year, _currentDate.month, day);
      final weekdayIndex = date.weekday - 1;
      currentWeek[weekdayIndex] = date;
      if (weekdayIndex == 6) { weeks.add(currentWeek); currentWeek = List.filled(7, null); }
    }
    if (currentWeek.any((d) => d != null)) weeks.add(currentWeek);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((day) => Expanded(
              child: Center(child: Text(day, style: AppTheme.typography.caption.copyWith(color: AppTheme.colors.textSecondary))),
            )).toList(),
          ),
          const SizedBox(height: 8),
          ...weeks.map((week) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: week.map((day) => Expanded(
                child: day != null
                    ? _buildMonthDayCard(day, _partnerAvailabilities, canEdit: false)
                    : const SizedBox(height: 48),
              )).toList(),
            ),
          )),
        ],
      ),
    );
  }

  // ============================================
  // DIALOGS & ACTIONS
  // ============================================

  void _editDay(DateTime day, Map<String, dynamic> currentAvailability) {
    bool isAvailable = currentAvailability['is_available'] == true;
    String availabilityType = currentAvailability['availability_type'] ?? 'full_day';
    final notesController = TextEditingController(text: currentAvailability['notes'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: Text('Annuler', style: TextStyle(color: AppTheme.colors.textSecondary)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(DateFormat('EEE d MMM', 'fr_FR').format(day), style: AppTheme.typography.h4),
                      TextButton(
                        child: Text('OK', style: TextStyle(color: AppTheme.colors.primary, fontWeight: FontWeight.w600)),
                        onPressed: () {
                          Navigator.pop(context);
                          _saveAvailability(day, isAvailable, availabilityType, notesController.text);
                        },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Statut', style: AppTheme.typography.caption.copyWith(color: AppTheme.colors.textSecondary, letterSpacing: 0.5)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildToggleButton('Disponible', Icons.check_circle, true, isAvailable, () => setDialogState(() => isAvailable = true), AppTheme.colors.success)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildToggleButton('Occupé', Icons.cancel, false, !isAvailable, () => setDialogState(() => isAvailable = false), AppTheme.colors.error)),
                        ],
                      ),
                      if (isAvailable) ...[
                        const SizedBox(height: 24),
                        Text('Durée', style: AppTheme.typography.caption.copyWith(color: AppTheme.colors.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _buildTypeButton('Journée', 'full_day', availabilityType, () => setDialogState(() => availabilityType = 'full_day'))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTypeButton('Demi-journée', 'partial_day', availabilityType, () => setDialogState(() => availabilityType = 'partial_day'))),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text('Note', style: AppTheme.typography.caption.copyWith(color: AppTheme.colors.textSecondary, letterSpacing: 0.5)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ajouter une note...',
                          filled: true,
                          fillColor: AppTheme.colors.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: AppTheme.colors.border),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(String label, IconData icon, bool value, bool active, VoidCallback onTap, Color activeColor) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: active ? activeColor : AppTheme.colors.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? activeColor : AppTheme.colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? Colors.white : AppTheme.colors.textSecondary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: active ? Colors.white : AppTheme.colors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String value, String current, VoidCallback onTap) {
    final active = current == value;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppTheme.colors.primary : AppTheme.colors.inputBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppTheme.colors.primary : AppTheme.colors.border),
        ),
        child: Center(
          child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: active ? Colors.white : AppTheme.colors.textPrimary)),
        ),
      ),
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Définir une période'),
              onTap: () { Navigator.pop(context); _showBulkAvailabilityDialog(); },
            ),
            ListTile(
              title: const Text('Créer disponibilités par défaut'),
              onTap: () { Navigator.pop(context); _createDefaultAvailabilities(); },
            ),
            ListTile(
              title: const Text('Marquer week-ends occupés'),
              onTap: () { Navigator.pop(context); _setWeekendUnavailable(); },
            ),
            ListTile(
              title: Text('Annuler', style: TextStyle(color: AppTheme.colors.textSecondary)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showBulkAvailabilityDialog() {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    bool isAvailable = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(child: const Text('Annuler'), onPressed: () => Navigator.pop(context)),
                      Text('Définir une période', style: AppTheme.typography.h4),
                      TextButton(
                        child: Text('Sauvegarder', style: TextStyle(color: AppTheme.colors.primary, fontWeight: FontWeight.w600)),
                        onPressed: () { Navigator.pop(context); _saveBulkAvailability(startDate, endDate, isAvailable); },
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildTypeButton('Disponible', 'available', isAvailable ? 'available' : 'busy', () => setDialogState(() => isAvailable = true))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTypeButton('Occupé', 'busy', isAvailable ? 'available' : 'busy', () => setDialogState(() => isAvailable = false))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final date = await showDatePicker(context: context, initialDate: startDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (date != null) setDialogState(() => startDate = date);
                              },
                              child: Text(DateFormat('dd/MM').format(startDate)),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('à', style: AppTheme.typography.bodyMedium),
                          ),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                final date = await showDatePicker(context: context, initialDate: endDate, firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (date != null) setDialogState(() => endDate = date);
                              },
                              child: Text(DateFormat('dd/MM').format(endDate)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAvailability(DateTime day, bool isAvailable, String type, String notes) async {
    try {
      await AvailabilityService.setPartnerAvailability(
        date: day,
        isAvailable: isAvailable,
        availabilityType: type,
        notes: notes.isNotEmpty ? notes : null,
      );
      _loadAvailabilities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${DateFormat('dd/MM').format(day)} mis à jour'),
          backgroundColor: AppTheme.colors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Impossible de sauvegarder la disponibilité.\n\nErreur: $e'),
            actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
          ),
        );
      }
    }
  }

  Future<void> _saveBulkAvailability(DateTime startDate, DateTime endDate, bool isAvailable) async {
    try {
      await AvailabilityService.setPartnerAvailabilityBulk(
        startDate: startDate,
        endDate: endDate,
        isAvailable: isAvailable,
        availabilityType: isAvailable ? 'full_day' : 'unavailable',
      );
      _loadAvailabilities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Période ${DateFormat('dd/MM').format(startDate)}-${DateFormat('dd/MM').format(endDate)} définie'),
          backgroundColor: AppTheme.colors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        ));
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de la définition de la période: $e'),
            actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
          ),
        );
      }
    }
  }

  Future<void> _createDefaultAvailabilities() async {
    try {
      await AvailabilityService.createDefaultAvailabilityForPartner();
      _loadAvailabilities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Disponibilités par défaut créées'),
          backgroundColor: AppTheme.colors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        ));
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur: $e'),
            actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.pop(context))],
          ),
        );
      }
    }
  }

  Future<void> _setWeekendUnavailable() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = startDate.add(const Duration(days: 30));
    try {
      await AvailabilityService.setPartnerAvailabilityBulk(
        startDate: startDate,
        endDate: endDate,
        isAvailable: false,
        availabilityType: 'unavailable',
        daysOfWeek: [6, 7],
        notes: 'Week-end',
      );
      _loadAvailabilities();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Week-ends marqués occupés'),
          backgroundColor: AppTheme.colors.warning,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
        ));
      }
    } catch (e) {
      debugPrint('Erreur week-ends: $e');
    }
  }

  // Utilitaires
  Map<String, dynamic> _getAvailabilityForDate(DateTime date, List<Map<String, dynamic>> availabilities) {
    final dateStr = date.toIso8601String().split('T')[0];
    return availabilities.firstWhere(
      (a) => a['date'] == dateStr,
      orElse: () => <String, dynamic>{},
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
