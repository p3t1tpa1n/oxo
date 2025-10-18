import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class IOSMobileAvailabilityPage extends StatefulWidget {
  const IOSMobileAvailabilityPage({Key? key}) : super(key: key);

  @override
  State<IOSMobileAvailabilityPage> createState() => _IOSMobileAvailabilityPageState();
}

class _IOSMobileAvailabilityPageState extends State<IOSMobileAvailabilityPage> {
  List<Map<String, dynamic>> _availabilities = [];
  bool _isLoading = true;
  DateTime _currentWeekStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Commencer au début de la semaine courante
    final now = DateTime.now();
    _currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    _loadAvailabilities();
  }

  Future<void> _loadAvailabilities() async {
    setState(() => _isLoading = true);
    
    try {
      // Charger la semaine courante
      final startDate = _currentWeekStart;
      final endDate = _currentWeekStart.add(const Duration(days: 6));
      
      final availabilities = await SupabaseService.getPartnerOwnAvailability(
        startDate: startDate,
        endDate: endDate,
      );
      
      if (mounted) {
        setState(() {
          _availabilities = availabilities;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement disponibilités: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.chevron_left, color: CupertinoColors.systemBlue),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _showQuickActions,
          child: const Text('Ajouter', style: TextStyle(color: CupertinoColors.systemBlue)),
        ),
        middle: const Text(
          'Mes disponibilités',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
      ),
      child: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildWeekHeader(),
                  const SizedBox(height: 30),
                  _buildWeeklyCalendar(),
                  const Spacer(),
                  _buildActionButtons(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildWeekHeader() {
    final weekDays = List.generate(7, (index) => _currentWeekStart.add(Duration(days: index)));
    final availableDays = weekDays.where((day) {
      final availability = _getAvailabilityForDate(day);
      return availability['is_available'] == true;
    }).length;

    return Column(
      children: [
        Text(
          'Semaine du ${DateFormat('d', 'fr_FR').format(_currentWeekStart)} au ${DateFormat('d MMMM', 'fr_FR').format(_currentWeekStart.add(const Duration(days: 6)))}',
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$availableDays jours disponibles',
            style: const TextStyle(
              fontSize: 15,
              color: CupertinoColors.secondaryLabel,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyCalendar() {
    final weekDays = List.generate(7, (index) => _currentWeekStart.add(Duration(days: index)));
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // En-têtes des jours
          Row(
            children: weekDays.map((day) => Expanded(
              child: Center(
                child: Text(
                  DateFormat('EEE', 'fr_FR').format(day),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
            )).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Grille des jours
          Row(
            children: weekDays.map((day) => Expanded(
              child: _buildDayCard(day),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DateTime day) {
    final availability = _getAvailabilityForDate(day);
    final isAvailable = availability['is_available'] == true;
    final isToday = _isToday(day);
    final isPast = day.isBefore(DateTime.now().subtract(const Duration(days: 1)));
    
    Color backgroundColor;
    Widget icon;
    
    if (isPast) {
      backgroundColor = CupertinoColors.systemGrey6;
      icon = const Icon(CupertinoIcons.minus, color: CupertinoColors.systemGrey3, size: 20);
    } else if (availability.isNotEmpty) {
      if (isAvailable) {
        backgroundColor = CupertinoColors.systemGreen;
        icon = const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 20);
      } else {
        backgroundColor = const Color(0xFFFFE5E5); // Rose clair
        icon = const Icon(CupertinoIcons.xmark, color: CupertinoColors.systemRed, size: 20);
      }
    } else {
      backgroundColor = CupertinoColors.systemGrey6;
      icon = const Icon(CupertinoIcons.minus, color: CupertinoColors.systemGrey3, size: 20);
    }

    return GestureDetector(
      onTap: isPast ? null : () => _editDay(day, availability),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 120,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: isToday ? Border.all(color: CupertinoColors.systemBlue, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isAvailable ? Colors.white : CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isAvailable ? Colors.white.withOpacity(0.3) : backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: icon,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Bouton principal
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.systemBlue,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(vertical: 16),
              onPressed: _showBulkAvailabilityDialog,
              child: const Text(
                'Définir mes disponibilités',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Boutons secondaires
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _createDefaultAvailabilities,
                  child: const Text(
                    'Auto-remplir',
                    style: TextStyle(
                      color: CupertinoColors.label,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CupertinoButton(
                  color: CupertinoColors.systemGrey5,
                  borderRadius: BorderRadius.circular(12),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  onPressed: _setWeekendUnavailable,
                  child: const Text(
                    'Week-ends occupés',
                    style: TextStyle(
                      color: CupertinoColors.label,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _editDay(DateTime day, Map<String, dynamic> currentAvailability) {
    bool isAvailable = currentAvailability['is_available'] == true;
    String availabilityType = currentAvailability['availability_type'] ?? 'full_day';
    String notes = currentAvailability['notes'] ?? '';

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    DateFormat('EEEE d MMMM', 'fr_FR').format(day),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Disponibilité',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        
                        CupertinoSegmentedControl<bool>(
                          children: const {
                            true: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Disponible'),
                            ),
                            false: Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Occupé'),
                            ),
                          },
                          onValueChanged: (value) => setDialogState(() => isAvailable = value),
                          groupValue: isAvailable,
                        ),
                        
                        if (isAvailable) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Type de disponibilité',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 16),
                          CupertinoSegmentedControl<String>(
                            children: const {
                              'full_day': Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('Journée complète'),
                              ),
                              'partial_day': Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text('Partielle'),
                              ),
                            },
                            onValueChanged: (value) => setDialogState(() => availabilityType = value),
                            groupValue: availabilityType,
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        const Text(
                          'Note (optionnelle)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        CupertinoTextField(
                          placeholder: 'Ex: Réunion client, formation...',
                          controller: TextEditingController(text: notes),
                          onChanged: (value) => notes = value,
                          maxLines: 2,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        
                        const Spacer(),
                        
                        SizedBox(
                          width: double.infinity,
                          child: CupertinoButton(
                            color: CupertinoColors.systemBlue,
                            borderRadius: BorderRadius.circular(12),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            onPressed: () {
                              Navigator.pop(context);
                              _saveAvailability(day, isAvailable, availabilityType, notes);
                            },
                            child: const Text(
                              'Sauvegarder',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
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

  void _showQuickActions() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Actions rapides'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showBulkAvailabilityDialog();
            },
            child: const Text('Définir une période'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _createDefaultAvailabilities();
            },
            child: const Text('Créer disponibilités par défaut'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _setWeekendUnavailable();
            },
            child: const Text('Marquer week-ends occupés'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
      ),
    );
  }

  void _showBulkAvailabilityDialog() {
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 7));
    bool isAvailable = true;

    showCupertinoDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => CupertinoAlertDialog(
          title: const Text('Définir une période'),
          content: SizedBox(
            height: 150,
            child: Column(
              children: [
                const SizedBox(height: 16),
                CupertinoSegmentedControl<bool>(
                  children: const {
                    true: Text('Disponible'),
                    false: Text('Occupé'),
                  },
                  onValueChanged: (value) => setDialogState(() => isAvailable = value),
                  groupValue: isAvailable,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        color: CupertinoColors.systemGrey6,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        onPressed: () async {
                          final date = await _showDatePicker(startDate);
                          if (date != null) setDialogState(() => startDate = date);
                        },
                        child: Text(
                          DateFormat('dd/MM').format(startDate),
                          style: const TextStyle(color: CupertinoColors.label),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('à', style: TextStyle(color: CupertinoColors.label)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton(
                        color: CupertinoColors.systemGrey6,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        onPressed: () async {
                          final date = await _showDatePicker(endDate);
                          if (date != null) setDialogState(() => endDate = date);
                        },
                        child: Text(
                          DateFormat('dd/MM').format(endDate),
                          style: const TextStyle(color: CupertinoColors.label),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Annuler'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('Sauvegarder'),
              onPressed: () {
                Navigator.pop(context);
                _saveBulkAvailability(startDate, endDate, isAvailable);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Actions de sauvegarde avec feedback
  Future<void> _saveAvailability(DateTime day, bool isAvailable, String type, String notes) async {
    try {
      await SupabaseService.setPartnerAvailability(
        date: day,
        isAvailable: isAvailable,
        availabilityType: type,
        notes: notes.isNotEmpty ? notes : null,
      );
      
      _loadAvailabilities();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${DateFormat('dd/MM').format(day)} mis à jour'),
            backgroundColor: CupertinoColors.systemBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erreur'),
            content: Text('Impossible de sauvegarder la disponibilité.\n\nErreur: $e'),
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

  Future<void> _saveBulkAvailability(DateTime startDate, DateTime endDate, bool isAvailable) async {
    try {
      await SupabaseService.setPartnerAvailabilityBulk(
        startDate: startDate,
        endDate: endDate,
        isAvailable: isAvailable,
        availabilityType: isAvailable ? 'full_day' : 'unavailable',
      );
      
      _loadAvailabilities();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Période ${DateFormat('dd/MM').format(startDate)}-${DateFormat('dd/MM').format(endDate)} définie'),
            backgroundColor: CupertinoColors.systemBlue,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erreur'),
            content: Text('Erreur lors de la définition de la période: $e'),
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

  Future<void> _createDefaultAvailabilities() async {
    try {
      await SupabaseService.createDefaultAvailabilityForPartner();
      _loadAvailabilities();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Disponibilités par défaut créées'),
            backgroundColor: CupertinoColors.systemGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
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

  Future<void> _setWeekendUnavailable() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = startDate.add(const Duration(days: 30));
    
    try {
      await SupabaseService.setPartnerAvailabilityBulk(
        startDate: startDate,
        endDate: endDate,
        isAvailable: false,
        availabilityType: 'unavailable',
        daysOfWeek: [6, 7], // Samedi et dimanche
        notes: 'Week-end',
      );
      
      _loadAvailabilities();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Week-ends marqués occupés'),
            backgroundColor: CupertinoColors.systemOrange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur week-ends: $e');
    }
  }

  Future<DateTime?> _showDatePicker(DateTime initialDate) async {
    DateTime? selectedDate;
    
    await showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: SafeArea(
          top: false,
          child: CupertinoDatePicker(
            initialDateTime: initialDate,
            mode: CupertinoDatePickerMode.date,
            onDateTimeChanged: (date) => selectedDate = date,
          ),
        ),
      ),
    );
    
    return selectedDate;
  }

  // Méthodes utilitaires
  Map<String, dynamic> _getAvailabilityForDate(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    return _availabilities.firstWhere(
      (availability) => availability['date'] == dateStr,
      orElse: () => <String, dynamic>{},
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}