import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../services/supabase_service.dart';
import '../../widgets/base_page_widget.dart';
import '../../widgets/standard_dialogs.dart' as dialogs;

class AvailabilityPage extends StatefulWidget {
  const AvailabilityPage({super.key});

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  List<Map<String, dynamic>> _availabilities = [];
  bool _isLoading = true;
  String? _error;
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _loadAvailabilities();
  }

  Future<void> _loadAvailabilities() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final startDate = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final endDate = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);
      
      final availabilities = await SupabaseService.getPartnerOwnAvailability(
        startDate: startDate,
        endDate: endDate,
      );
      
      setState(() {
        _availabilities = availabilities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors du chargement des disponibilités: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getAvailabilityForDate(DateTime date) {
    final dateStr = date.toIso8601String().split('T')[0];
    return _availabilities.firstWhere(
      (availability) => availability['date'] == dateStr,
      orElse: () => <String, dynamic>{},
    );
  }

  bool _isAvailableOnDate(DateTime date) {
    final availability = _getAvailabilityForDate(date);
    return availability.isNotEmpty ? availability['is_available'] == true : true;
  }

  Color _getColorForDate(DateTime date) {
    final availability = _getAvailabilityForDate(date);
    if (availability.isEmpty) return Colors.green.shade100; // Par défaut disponible
    
    if (availability['is_available'] == true) {
      switch (availability['availability_type']) {
        case 'full_day':
          return Colors.green.shade200;
        case 'partial_day':
          return Colors.orange.shade200;
        default:
          return Colors.green.shade100;
      }
    } else {
      return Colors.red.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePageWidget(
      title: 'Mes Disponibilités',
      route: '/availability',
      body: _buildAvailabilityContent(),
      isLoading: _isLoading,
      errorMessage: _error,
      hasData: true,
      onRefresh: _loadAvailabilities,
      floatingActionButtons: [
        FloatingActionButton.extended(
          onPressed: _showBulkAvailabilityDialog,
          backgroundColor: const Color(0xFF1784af),
          icon: const Icon(Icons.edit_calendar, color: Colors.white),
          label: const Text('Définir période', style: TextStyle(color: Colors.white)),
        ),
        FloatingActionButton.extended(
          onPressed: _createDefaultAvailabilities,
          backgroundColor: Colors.green,
          icon: const Icon(Icons.auto_fix_high, color: Colors.white),
          label: const Text('Défaut', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildAvailabilityContent() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCalendarSection(),
          const SizedBox(height: 24),
          _buildSelectedDayDetails(),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, color: Color(0xFF1784af)),
                const SizedBox(width: 8),
                const Text(
                  'Calendrier des disponibilités',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showLegendDialog(),
                  icon: const Icon(Icons.help_outline),
                  tooltip: 'Légende',
                ),
              ],
            ),
            const SizedBox(height: 16),
            TableCalendar(
              firstDay: DateTime.now().subtract(const Duration(days: 30)),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getColorForDate(day),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isAvailableOnDate(day) ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: _isAvailableOnDate(day) ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
                selectedBuilder: (context, day, focusedDay) {
                  return Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _getColorForDate(day),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF1784af),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Color(0xFF1784af),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
                _loadAvailabilities();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDayDetails() {
    final availability = _getAvailabilityForDate(_selectedDay);
    final isAvailable = availability.isNotEmpty ? availability['is_available'] == true : true;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.cancel,
                  color: isAvailable ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Détails pour ${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDay)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showEditAvailabilityDialog(_selectedDay, availability),
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1784af),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAvailabilityDetails(availability, isAvailable),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityDetails(Map<String, dynamic> availability, bool isAvailable) {
    if (availability.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('📋 Statut: Disponible (par défaut)'),
          SizedBox(height: 8),
          Text('⏰ Horaires: Journée complète'),
          SizedBox(height: 8),
          Text('📝 Notes: Aucune note spécifique'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📋 Statut: ${isAvailable ? "Disponible" : "Indisponible"}',
          style: TextStyle(
            color: isAvailable ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text('📌 Type: ${_getAvailabilityTypeLabel(availability['availability_type'])}'),
        if (availability['start_time'] != null || availability['end_time'] != null) ...[
          const SizedBox(height: 8),
          Text('⏰ Horaires: ${availability['start_time'] ?? "Non défini"} - ${availability['end_time'] ?? "Non défini"}'),
        ],
        if (availability['unavailability_reason'] != null) ...[
          const SizedBox(height: 8),
          Text('🔍 Raison: ${_getUnavailabilityReasonLabel(availability['unavailability_reason'])}'),
        ],
        if (availability['notes'] != null && availability['notes'].toString().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('📝 Notes: ${availability['notes']}'),
        ],
      ],
    );
  }

  String _getAvailabilityTypeLabel(String? type) {
    switch (type) {
      case 'full_day':
        return 'Journée complète';
      case 'partial_day':
        return 'Journée partielle';
      case 'unavailable':
        return 'Indisponible';
      default:
        return 'Non défini';
    }
  }

  String _getUnavailabilityReasonLabel(String? reason) {
    switch (reason) {
      case 'vacation':
        return 'Congés';
      case 'sick':
        return 'Maladie';
      case 'personal':
        return 'Personnel';
      case 'training':
        return 'Formation';
      case 'other':
        return 'Autre';
      default:
        return reason ?? 'Non spécifié';
    }
  }

  void _showLegendDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Légende du calendrier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(Colors.green.shade200, 'Disponible - Journée complète'),
            _buildLegendItem(Colors.orange.shade200, 'Disponible - Journée partielle'),
            _buildLegendItem(Colors.red.shade200, 'Indisponible'),
            _buildLegendItem(Colors.green.shade100, 'Disponible (par défaut)'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey),
            ),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  void _showEditAvailabilityDialog(DateTime date, Map<String, dynamic> currentAvailability) {
    final isCurrentlyAvailable = currentAvailability.isNotEmpty ? currentAvailability['is_available'] == true : true;
    final currentType = currentAvailability['availability_type'] ?? 'full_day';
    final currentStartTime = currentAvailability['start_time'];
    final currentEndTime = currentAvailability['end_time'];
    final currentNotes = currentAvailability['notes'] ?? '';
    final currentReason = currentAvailability['unavailability_reason'];

    // Préparer les valeurs initiales
    final initialValues = {
      'is_available': isCurrentlyAvailable ? 'true' : 'false',
      'availability_type': currentType,
      'start_time': currentStartTime,
      'end_time': currentEndTime,
      'notes': currentNotes,
      'unavailability_reason': currentReason,
    };

    dialogs.StandardDialogs.showFormDialog(
      context: context,
      title: 'Modifier la disponibilité',
      initialValues: initialValues,
      fields: [
        const dialogs.FormField(
          key: 'is_available',
          label: 'Disponibilité',
          type: dialogs.FormFieldType.dropdown,
          required: true,
          options: [
            dialogs.SelectionItem(value: 'true', label: 'Disponible'),
            dialogs.SelectionItem(value: 'false', label: 'Indisponible'),
          ],
        ),
        const dialogs.FormField(
          key: 'availability_type',
          label: 'Type de disponibilité',
          type: dialogs.FormFieldType.dropdown,
          required: true,
          options: [
            dialogs.SelectionItem(value: 'full_day', label: 'Journée complète'),
            dialogs.SelectionItem(value: 'partial_day', label: 'Journée partielle'),
            dialogs.SelectionItem(value: 'unavailable', label: 'Indisponible'),
          ],
        ),
        const dialogs.FormField(
          key: 'start_time',
          label: 'Heure de début (ex: 09:00)',
          type: dialogs.FormFieldType.text,
        ),
        const dialogs.FormField(
          key: 'end_time',
          label: 'Heure de fin (ex: 17:00)',
          type: dialogs.FormFieldType.text,
        ),
        const dialogs.FormField(
          key: 'unavailability_reason',
          label: 'Raison de l\'indisponibilité',
          type: dialogs.FormFieldType.dropdown,
          options: [
            dialogs.SelectionItem(value: '', label: 'Aucune'),
            dialogs.SelectionItem(value: 'vacation', label: 'Congés'),
            dialogs.SelectionItem(value: 'sick', label: 'Maladie'),
            dialogs.SelectionItem(value: 'personal', label: 'Personnel'),
            dialogs.SelectionItem(value: 'training', label: 'Formation'),
            dialogs.SelectionItem(value: 'other', label: 'Autre'),
          ],
        ),
        const dialogs.FormField(
          key: 'notes',
          label: 'Notes',
          type: dialogs.FormFieldType.text,
        ),
      ],
    ).then((result) async {
      if (result != null) {
        await _saveAvailability(date, result);
      }
    });
  }

  Future<void> _saveAvailability(DateTime date, Map<String, dynamic> data) async {
    try {
      final isAvailable = data['is_available'] == 'true';
      
      TimeOfDay? startTime;
      TimeOfDay? endTime;
      
      if (data['start_time'] != null && data['start_time'].toString().isNotEmpty) {
        final startParts = data['start_time'].toString().split(':');
        if (startParts.length >= 2) {
          startTime = TimeOfDay(
            hour: int.tryParse(startParts[0]) ?? 9,
            minute: int.tryParse(startParts[1]) ?? 0,
          );
        }
      }
      
      if (data['end_time'] != null && data['end_time'].toString().isNotEmpty) {
        final endParts = data['end_time'].toString().split(':');
        if (endParts.length >= 2) {
          endTime = TimeOfDay(
            hour: int.tryParse(endParts[0]) ?? 17,
            minute: int.tryParse(endParts[1]) ?? 0,
          );
        }
      }

      final result = await SupabaseService.setPartnerAvailability(
        date: date,
        isAvailable: isAvailable,
        availabilityType: data['availability_type'] ?? 'full_day',
        startTime: startTime,
        endTime: endTime,
        notes: data['notes']?.isNotEmpty == true ? data['notes'] : null,
        unavailabilityReason: data['unavailability_reason']?.isNotEmpty == true ? data['unavailability_reason'] : null,
      );

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disponibilité mise à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAvailabilities();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBulkAvailabilityDialog() {
    dialogs.StandardDialogs.showFormDialog(
      context: context,
      title: 'Définir une période',
      fields: [
        const dialogs.FormField(
          key: 'is_available',
          label: 'Disponibilité',
          type: dialogs.FormFieldType.dropdown,
          required: true,
          options: [
            dialogs.SelectionItem(value: 'true', label: 'Disponible'),
            dialogs.SelectionItem(value: 'false', label: 'Indisponible'),
          ],
        ),
        const dialogs.FormField(
          key: 'availability_type',
          label: 'Type de disponibilité',
          type: dialogs.FormFieldType.dropdown,
          required: true,
          options: [
            dialogs.SelectionItem(value: 'full_day', label: 'Journée complète'),
            dialogs.SelectionItem(value: 'partial_day', label: 'Journée partielle'),
            dialogs.SelectionItem(value: 'unavailable', label: 'Indisponible'),
          ],
        ),
        dialogs.FormField(
          key: 'start_date',
          label: 'Date de début',
          type: dialogs.FormFieldType.date,
          required: true,
          context: context,
        ),
        dialogs.FormField(
          key: 'end_date',
          label: 'Date de fin',
          type: dialogs.FormFieldType.date,
          required: true,
          context: context,
        ),
        const dialogs.FormField(
          key: 'notes',
          label: 'Notes',
          type: dialogs.FormFieldType.text,
        ),
      ],
    ).then((result) async {
      if (result != null) {
        await _saveBulkAvailability(result);
      }
    });
  }

  Future<void> _saveBulkAvailability(Map<String, dynamic> data) async {
    try {
      final startDate = DateTime.tryParse(data['start_date'].toString());
      final endDate = DateTime.tryParse(data['end_date'].toString());
      
      if (startDate == null || endDate == null) {
        throw Exception('Dates invalides');
      }

      final isAvailable = data['is_available'] == 'true';
      
      final success = await SupabaseService.setPartnerAvailabilityBulk(
        startDate: startDate,
        endDate: endDate,
        isAvailable: isAvailable,
        availabilityType: data['availability_type'] ?? 'full_day',
        notes: data['notes']?.isNotEmpty == true ? data['notes'] : null,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Période définie avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAvailabilities();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la définition de la période'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createDefaultAvailabilities() async {
    try {
      final success = await SupabaseService.createDefaultAvailabilityForPartner();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disponibilités par défaut créées'),
            backgroundColor: Colors.green,
          ),
        );
        _loadAvailabilities();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la création des disponibilités par défaut'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
} 