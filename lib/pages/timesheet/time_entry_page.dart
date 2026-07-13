// ============================================================================
// PAGE DE SAISIE DU TEMPS - Pour les partenaires
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/timesheet_models.dart';
import '../../models/mission.dart';
import '../../services/timesheet_service.dart';
import '../../services/mission_service.dart';
import '../../services/supabase_service.dart';
import '../../services/company_service.dart';

class TimeEntryPage extends StatefulWidget {
  const TimeEntryPage({super.key});

  @override
  State<TimeEntryPage> createState() => _TimeEntryPageState();
}

class _TimeEntryPageState extends State<TimeEntryPage> {
  List<CalendarDay> _calendar = [];
  List<Mission> _availableMissions = []; // Remplace _authorizedClients
  MonthlyStats _stats = MonthlyStats.empty();
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  
  // Contrôleurs pour les saisies en cours d'édition
  final Map<String, double?> _selectedDays = {}; // 0.5 ou 1.0
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, String?> _selectedMissions = {}; // Remplace _selectedClients
  
  // Suivi des modifications non sauvegardées
  final Set<String> _modifiedRows = {};
  final Map<String, bool> _savingRows = {}; // Animation de sauvegarde
  final Map<String, bool> _savedRows = {}; // Animation de succès

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    // Nettoyer les contrôleurs
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final partnerId = SupabaseService.currentUser?.id;
      if (partnerId == null) throw Exception('Utilisateur non connecté');

      // Charger en parallèle
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

      setState(() {
        _calendar = results[0] as List<CalendarDay>;
        _availableMissions = results[1] as List<Mission>;
        _stats = results[2] as MonthlyStats;
        _isLoading = false;
      });
      
      debugPrint('📊 ${_availableMissions.length} missions disponibles pour la saisie');
      if (_availableMissions.isEmpty) {
        debugPrint('⚠️ Aucune mission disponible ! Vérifiez que le partenaire a des missions assignées.');
      } else {
        debugPrint('📋 Première mission: ${_availableMissions.first.title} (ID: ${_availableMissions.first.id})');
      }

      // Initialiser les contrôleurs pour chaque jour
      _initializeControllers();
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

  void _initializeControllers() {
    for (var day in _calendar) {
      final key = day.date.toIso8601String();
      
      if (day.hasEntry && day.entry!.id.isNotEmpty) {
        _selectedDays[key] = day.entry!.days > 0 ? day.entry!.days : null;
        _commentControllers[key] = TextEditingController(
          text: day.entry!.comment ?? '',
        );
        // Ne présélectionner la mission que si elle figure dans la liste
        // (sinon le DropdownButton lève une assertion "exactly one item").
        final entryMissionId = day.entry!.missionId;
        _selectedMissions[key] = (entryMissionId != null &&
                _availableMissions.any((m) => m.id == entryMissionId))
            ? entryMissionId
            : null;
      } else {
        _selectedDays[key] = null;
        _commentControllers[key] = TextEditingController();
        _selectedMissions[key] = null;
      }
    }
  }

  Future<void> _changeMonth(int delta) async {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + delta);
    });
    await _loadData();
  }

  Future<void> _saveEntry(CalendarDay day) async {
    final key = day.date.toIso8601String();
    final days = _selectedDays[key];
    final missionId = _selectedMissions[key];
    final comment = _commentControllers[key]?.text.trim();

    // Validation
    if (days == null) {
      _showQuickSnackBar('Sélectionnez une durée', const Color(0xFFB07B2E));
      return;
    }

    if (missionId == null || missionId.isEmpty) {
      _showQuickSnackBar('Sélectionnez une mission', const Color(0xFFB07B2E));
      return;
    }

    // Animation de sauvegarde
    setState(() {
      _savingRows[key] = true;
    });

    try {
      final partnerId = SupabaseService.currentUser?.id;
      if (partnerId == null) throw Exception('Utilisateur non connecté');

      // Récupérer le daily_rate de la mission sélectionnée
      final selectedMission = _availableMissions.firstWhere(
        (m) => m.id == missionId,
        orElse: () => throw Exception('Mission non trouvée'),
      );

      if (day.hasEntry && day.entry!.id.isNotEmpty) {
        // Mise à jour - Pour l'instant on met à jour via l'ancienne méthode
        // TODO: Créer une nouvelle méthode dans TimesheetService pour mission_id
        await SupabaseService.client
            .from('timesheet_entries')
            .update({
          'mission_id': missionId,
          'days': days,
          'comment': comment,
          'daily_rate': selectedMission.dailyRate,
        })
            .eq('id', day.entry!.id);
      } else {
        // Création
        final userCompany = await CompanyService.getUserCompany();
        await SupabaseService.client
            .from('timesheet_entries')
            .insert({
          'partner_id': partnerId,
          'mission_id': missionId,
          'entry_date': day.date.toIso8601String().split('T')[0],
          'days': days,
          'comment': comment,
          'daily_rate': selectedMission.dailyRate,
          'status': 'draft',
          'company_id': userCompany?['company_id'],
        });
      }

      // Animation de succès
      setState(() {
        _savingRows[key] = false;
        _savedRows[key] = true;
        _modifiedRows.remove(key);
      });

      // Micro snackbar
      _showQuickSnackBar('${DateFormat('dd/MM').format(day.date)} enregistré', const Color(0xFF2E7D5B));

      // Supprimer l'animation après 2 secondes
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _savedRows.remove(key);
          });
        }
      });

      // Recharger les données
      await _loadData();
    } catch (e) {
      setState(() {
        _savingRows[key] = false;
      });
      _showQuickSnackBar('Erreur: $e', Colors.red);
    }
  }

  void _showQuickSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 300,
      ),
    );
  }

  void _markRowAsModified(String key) {
    setState(() {
      _modifiedRows.add(key);
      _savedRows.remove(key);
    });
  }

  Future<void> _deleteEntry(CalendarDay day) async {
    if (!day.hasEntry || day.entry!.id.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la saisie'),
        content: Text('Supprimer la saisie du ${DateFormat('dd/MM/yyyy').format(day.date)} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await TimesheetService.deleteEntry(day.entry!.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saisie supprimée'), backgroundColor: const Color(0xFF2E7D5B)),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _submitMonth() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soumettre le mois'),
        content: Text(
          'Soumettre toutes les saisies du mois de ${DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth)} ?\n\n'
          'Les saisies soumises ne pourront plus être modifiées.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16283C)),
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final partnerId = SupabaseService.currentUser?.id;
      if (partnerId == null) throw Exception('Utilisateur non connecté');

      await TimesheetService.submitMonth(
        partnerId: partnerId,
        year: _selectedMonth.year,
        month: _selectedMonth.month,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mois soumis'), backgroundColor: const Color(0xFF2E7D5B)),
        );
      }

      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStats(),
          const SizedBox(height: 24),
          Expanded(child: _buildTimesheetTable()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Calculer les statistiques de saisie
    final workingDays = _calendar.where((d) => !d.isWeekend).length;
    final enteredDays = _calendar.where((d) => d.hasEntry && d.entry!.days > 0).length;
    final progressPercentage = workingDays > 0 ? (enteredDays / workingDays * 100).round() : 0;
    final totalDaysEntered = _calendar.where((d) => d.hasEntry).fold(0.0, (sum, d) => sum + (d.entry?.days ?? 0));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => _changeMonth(-1),
                  icon: const Icon(Icons.chevron_left, color: Color(0xFF16283C)),
                  tooltip: 'Mois précédent',
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    DateFormat('MMMM yyyy', 'fr_FR').format(_selectedMonth),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF16283C),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => _changeMonth(1),
                  icon: const Icon(Icons.chevron_right, color: Color(0xFF16283C)),
                  tooltip: 'Mois suivant',
                ),
                const SizedBox(width: 32),
                ElevatedButton.icon(
                  onPressed: _submitMonth,
                  icon: const Icon(Icons.send),
                  label: const Text('Soumettre le mois'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16283C),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Barre de progression
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF16283C).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$enteredDays / $workingDays jours saisis ($progressPercentage%)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16283C),
                        ),
                      ),
                      Text(
                        'Total: ${totalDaysEntered.toStringAsFixed(1)} jours',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16283C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressPercentage < 50
                            ? const Color(0xFFB07B2E)
                            : progressPercentage < 80
                                ? const Color(0xFF3E5C76)
                                : const Color(0xFF2E7D5B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Jours totaux', TimesheetService.formatDays(_stats.totalDays), Icons.access_time, const Color(0xFF3E5C76))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Montant total', TimesheetService.formatAmount(_stats.totalAmount), Icons.euro, const Color(0xFF2E7D5B))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Jours saisis', '${_stats.totalDays}', Icons.calendar_today, const Color(0xFFB07B2E))),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Moyenne/entrée', TimesheetService.formatDays(_stats.avgDaysPerEntry), Icons.trending_up, const Color(0xFF5B5F97))),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCE1E8), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A2530),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesheetTable() {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 1300),
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columnSpacing: 12,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 64,
              headingRowHeight: 48,
              headingRowColor: MaterialStateProperty.all(const Color(0xFF16283C).withOpacity(0.1)),
              columns: const [
                DataColumn(label: _HeaderCell('Date', 80)),
                DataColumn(label: _HeaderCell('Jour', 70)),
                DataColumn(label: _HeaderCell('Mission', 240)),
                DataColumn(label: _HeaderCell('Jours', 140)),
                DataColumn(label: _HeaderCell('Comment', 200)),
                DataColumn(label: _HeaderCell('Tar €/j', 80)),
                DataColumn(label: _HeaderCell('Mt €', 90)),
                DataColumn(label: _HeaderCell('Act.', 100)),
              ],
              rows: _calendar.map((day) => _buildTableRow(day)).toList(),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildTableRow(CalendarDay day) {
    final key = day.date.toIso8601String();
    final isEditable = !day.hasEntry || day.entry!.status == 'draft';
    // Sécurité : ne jamais passer au dropdown une valeur absente des items
    final rawSelectedMissionId = _selectedMissions[key];
    final selectedMissionId = (rawSelectedMissionId != null &&
            _availableMissions.any((m) => m.id == rawSelectedMissionId))
        ? rawSelectedMissionId
        : null;
    
    // Récupérer le tarif depuis la mission sélectionnée
    final dailyRate = selectedMissionId != null
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
          ).dailyRate ?? 0.0
        : (day.hasEntry ? day.entry!.dailyRate : 0.0);
    
    final days = _selectedDays[key] ?? (day.hasEntry ? day.entry!.days : 0.0);
    final amount = days * dailyRate;

    // Déterminer la couleur de fond
    final isToday = DateUtils.isSameDay(day.date, DateTime.now());
    final isModified = _modifiedRows.contains(key);
    final isSaved = _savedRows[key] == true;
    final isSaving = _savingRows[key] == true;

    Color? rowColor;
    if (isSaved) {
      rowColor = Colors.green[50];
    } else if (isModified) {
      rowColor = Colors.blue[50];
    } else if (isToday) {
      rowColor = const Color(0xFF16283C).withOpacity(0.08);
    } else if (day.isWeekend) {
      rowColor = Colors.grey[200];
    }

    return DataRow(
      color: MaterialStateProperty.all(rowColor),
      cells: [
        // Date
        DataCell(SizedBox(
          width: 80,
          child: Text(DateFormat('dd/MM').format(day.date), maxLines: 1),
        )),
        // Jour
        DataCell(SizedBox(
          width: 70,
          child: Text(
            day.dayName.substring(0, 3), // Lu, Ma, Me, etc.
            style: TextStyle(color: day.isWeekend ? Colors.grey[600] : null),
            maxLines: 1,
          ),
        )),
        // Mission (remplace Client)
        DataCell(
          isEditable
              ? SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                      value: selectedMissionId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      isDense: true,
                    ),
                      hint: const Text('Mission...', style: TextStyle(fontSize: 11)),
                      isExpanded: true,
                    items: _availableMissions.isEmpty
                        ? [
                            const DropdownMenuItem(
                              value: null,
                              enabled: false,
                              child: Text('Aucune mission disponible', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ),
                          ]
                        : _availableMissions.map((mission) {
                            return DropdownMenuItem<String>(
                          value: mission.id,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                mission.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              if (mission.companyName != null)
                                Text(
                                  '${mission.companyName}${mission.groupName != null ? " (${mission.groupName})" : ""}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    onChanged: _availableMissions.isEmpty
                        ? null
                        : (value) {
                        setState(() {
                          _selectedMissions[key] = value;
                          _markRowAsModified(key);
                              debugPrint('✅ Mission sélectionnée: $value pour la date $key');
                        });
                      },
                  ),
                )
              : SizedBox(
                  width: 240,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        day.entry?.clientName ?? '-', // Temporairement, sera mission title
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
        ),
        // Jours (dropdown)
        DataCell(
          SizedBox(
            width: 140,
            child: isEditable
                ? DropdownButtonFormField<double>(
                    value: _selectedDays[key],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      isDense: true,
                    ),
                    hint: const Text('...', style: TextStyle(fontSize: 12)),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 0.5,
                        child: Text('0.5j', style: TextStyle(fontSize: 12)),
                      ),
                      DropdownMenuItem(
                        value: 1.0,
                        child: Text('1.0j', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDays[key] = value;
                        _markRowAsModified(key);
                      });
                    },
                  )
                : Text(
                    day.hasEntry ? '${day.entry!.days}j' : '-',
                    maxLines: 1,
                    style: const TextStyle(fontSize: 13),
                  ),
          ),
        ),
        // Commentaire
        DataCell(
          SizedBox(
            width: 200,
            child: isEditable
                ? TextField(
                    controller: _commentControllers[key],
                    maxLines: 1,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      hintText: 'Note...',
                      hintStyle: TextStyle(fontSize: 11),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      _markRowAsModified(key);
                    },
                  )
                : Tooltip(
                    message: day.entry?.comment ?? '-',
                    child: Text(
                      day.entry?.comment ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
          ),
        ),
        // Tarif
        DataCell(SizedBox(
          width: 80,
          child: Text(
            dailyRate > 0 ? dailyRate.toStringAsFixed(0) : '-',
            maxLines: 1,
            style: const TextStyle(fontSize: 13),
          ),
        )),
        // Montant
        DataCell(SizedBox(
          width: 90,
          child: Text(
            amount > 0 ? amount.toStringAsFixed(0) : '-',
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        )),
        // Actions
        DataCell(
          SizedBox(
            width: 100,
            child: isEditable
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton de sauvegarde avec états visuels
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isSaved
                              ? const Color(0xFF2E7D5B).withOpacity(0.1)
                              : isModified
                                  ? const Color(0xFF3E5C76).withOpacity(0.1)
                                  : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: IconButton(
                          icon: Icon(
                            isSaving
                                ? Icons.hourglass_empty
                                : isSaved
                                    ? Icons.check_circle
                                    : isModified
                                        ? Icons.save
                                        : Icons.save_outlined,
                            size: 18,
                          ),
                          onPressed: isSaving ? null : () => _saveEntry(day),
                          tooltip: isSaving
                              ? 'Sauvegarde...'
                              : isSaved
                                  ? 'Enregistré ✓'
                                  : isModified
                                      ? 'Enregistrer (modifié)'
                                      : 'Enregistrer',
                          color: isSaved
                              ? const Color(0xFF2E7D5B)
                              : isModified
                                  ? const Color(0xFF3E5C76)
                                  : Colors.grey,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                      if (day.hasEntry && day.entry!.id.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18),
                          onPressed: () => _deleteEntry(day),
                          tooltip: 'Supprimer',
                          color: Colors.red,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: _getStatusColor(day.entry?.status ?? 'draft').withOpacity(0.1),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      _getStatusLabel(day.entry?.status ?? 'draft'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _getStatusColor(day.entry?.status ?? 'draft'),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return const Color(0xFF3E5C76);
      case 'approved':
        return const Color(0xFF2E7D5B);
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
}

// ============================================================================
// Widget helper pour les en-têtes de colonnes (évite les overflows)
// ============================================================================
class _HeaderCell extends StatelessWidget {
  final String text;
  final double width;

  const _HeaderCell(this.text, this.width);

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

