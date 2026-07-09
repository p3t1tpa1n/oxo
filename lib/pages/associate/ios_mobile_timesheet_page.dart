import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/ios_theme.dart';
import '../../widgets/ios_widgets.dart';
import '../../services/supabase_service.dart';
import '../../services/availability_service.dart';

class IOSMobileTimesheetPage extends StatefulWidget {
  const IOSMobileTimesheetPage({Key? key}) : super(key: key);

  @override
  State<IOSMobileTimesheetPage> createState() => _IOSMobileTimesheetPageState();
}

class _IOSMobileTimesheetPageState extends State<IOSMobileTimesheetPage> {
  List<Map<String, dynamic>> _timesheetEntries = [];
  List<Map<String, dynamic>> _availabilities = [];
  bool _isLoading = true;
  String _selectedFilter = 'pending';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.wait([
        _loadTimesheetEntries(),
        _loadTodayAvailabilities(),
      ]);
    } catch (e) {
      debugPrint('Erreur chargement: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTimesheetEntries() async {
    try {
      final response = await SupabaseService.client
          .from('timesheet_entries')
          .select('*')
          .order('date', ascending: false)
          .limit(50);

      final allUsers = await SupabaseService.client.rpc('get_users');
      final usersMap = <String, Map<String, dynamic>>{};
      for (var user in allUsers) {
        usersMap[user['user_id']] = user;
      }

      for (var entry in response) {
        final user = usersMap[entry['user_id']];
        entry['user_name'] = '${user?['first_name'] ?? ''} ${user?['last_name'] ?? ''}'.trim();
        entry['user_email'] = user?['email'] ?? 'Utilisateur inconnu';
      }

      if (mounted) {
        setState(() {
          _timesheetEntries = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      debugPrint('Erreur timesheet: $e');
    }
  }

  Future<void> _loadTodayAvailabilities() async {
    try {
      final availabilities = await AvailabilityService.getAvailablePartnersForDate(DateTime.now());
      if (mounted) setState(() => _availabilities = availabilities);
    } catch (e) {
      debugPrint('Erreur disponibilités: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return IOSScaffold(
      // 🧭 RÈGLE 2: Navigation intuitive - Retour toujours visible et prévisible
      navigationBar: IOSNavigationBar(
        title: "Temps de travail", // 🎯 RÈGLE 1: Titre clair et simple
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Icon(CupertinoIcons.back, color: IOSTheme.primaryBlue),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator()) // ⚡ RÈGLE 4: Feedback visuel de chargement
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  // 📊 RÈGLE 7: Hiérarchisation - Stats importantes en premier
                  SliverToBoxAdapter(child: _buildTodayOverview()),
                  
                  // 🎯 RÈGLE 1: Un seul contrôle principal - Filtres simples
                  SliverToBoxAdapter(child: _buildSimpleFilters()),
                  
                  // Liste principale avec espacement généreux
                  SliverPadding(
                    padding: const EdgeInsets.all(20), // 🎯 RÈGLE 1: Espace blanc généreux
                    sliver: _buildTimesheetList(),
                  ),
                ],
              ),
            ),
    );
  }

  // 🎯 RÈGLE 1: Clarté avant tout - Vue d'ensemble simple et claire
  Widget _buildTodayOverview() {
    final today = DateTime.now();
    final todayEntries = _timesheetEntries.where((entry) {
      final entryDate = DateTime.tryParse(entry['date'] ?? '');
      return entryDate != null && 
             entryDate.year == today.year && 
             entryDate.month == today.month && 
             entryDate.day == today.day;
    }).toList();

    final todayHours = todayEntries.fold(0.0, (sum, entry) => sum + (entry['hours'] ?? 0.0));
    final pendingCount = _timesheetEntries.where((e) => e['status'] == 'pending').length;

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: IOSTheme.primaryBlue,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: IOSTheme.primaryBlue.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📊 RÈGLE 7: Hiérarchie claire avec la date
          Text(
            DateFormat('EEEE d MMMM', 'fr_FR').format(today),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // 📊 RÈGLE 7: Informations importantes mises en avant
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  '${todayHours.toStringAsFixed(1)}h',
                  'Aujourd\'hui',
                  CupertinoIcons.time,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  '$pendingCount',
                  'En attente',
                  CupertinoIcons.bell,
                ),
              ),
            ],
          ),
          
          // 👤 RÈGLE 5: Info utile pour l'utilisateur
          if (_availabilities.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.person_2_fill, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_availabilities.length} partenaire(s) disponible(s)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // 🎯 RÈGLE 1: Contrôles simples et clairs
  Widget _buildSimpleFilters() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: IOSTheme.systemGray6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoSegmentedControl<String>(
        children: const {
          'pending': Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), // 📱 RÈGLE 3: Touch targets suffisants
            child: Text('En attente'),
          ),
          'approved': Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text('Validées'),
          ),
          'all': Padding(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text('Toutes'),
          ),
        },
        onValueChanged: (value) {
          setState(() {
            _selectedFilter = value;
          });
        },
        groupValue: _selectedFilter,
      ),
    );
  }

  Widget _buildTimesheetList() {
    final filteredEntries = _getFilteredEntries();
    
    if (filteredEntries.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final entry = filteredEntries[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16), // 🎯 RÈGLE 1: Espacement généreux
            child: _buildTimesheetCard(entry),
          );
        },
        childCount: filteredEntries.length,
      ),
    );
  }

  // 📊 RÈGLE 7: Hiérarchisation visuelle claire
  Widget _buildTimesheetCard(Map<String, dynamic> entry) {
    final status = entry['status'] ?? 'pending';
    final hours = (entry['hours'] ?? 0.0).toDouble();
    final date = DateTime.tryParse(entry['date'] ?? '') ?? DateTime.now();
    final userName = entry['user_name'] ?? entry['user_email']?.split('@').first ?? 'Utilisateur';
    final description = entry['description'] ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: IOSTheme.systemBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📊 RÈGLE 7: Info principale en premier
          Row(
            children: [
              // Badge visuel avec heures
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hours.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'heures',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Infos principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📊 RÈGLE 7: Nom en premier (plus important)
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: IOSTheme.labelPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Date en secondaire
                    Text(
                      DateFormat('EEEE d MMMM', 'fr_FR').format(date),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: IOSTheme.labelSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 🔒 RÈGLE 6: Status avec couleur ET texte (pas que couleur)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getStatusLabel(status),
                  style: TextStyle(
                    color: _getStatusColor(status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          // Description si présente
          if (description.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: IOSTheme.systemGray6,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: IOSTheme.labelSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          
          // 👤 RÈGLE 5: Actions uniquement si nécessaires
          if (status == 'pending') ...[
            const SizedBox(height: 20),
            Row(
              children: [
                // 📱 RÈGLE 3: Touch targets suffisants (44x44 minimum)
                Expanded(
                  child: CupertinoButton(
                    color: IOSTheme.successColor,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 14), // 📱 RÈGLE 3
                    onPressed: () => _updateEntryStatus(entry['id'], 'approved'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.checkmark, size: 18),
                        SizedBox(width: 8),
                        Text('Valider', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CupertinoButton(
                    color: IOSTheme.errorColor,
                    borderRadius: BorderRadius.circular(12),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    onPressed: () => _updateEntryStatus(entry['id'], 'rejected'),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.xmark, size: 18),
                        SizedBox(width: 8),
                        Text('Refuser', style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // 🎯 RÈGLE 1: État vide clair et encourageant
  Widget _buildEmptyState() {
    String title;
    String subtitle;
    IconData icon;
    
    switch (_selectedFilter) {
      case 'pending':
        title = 'Aucune entrée en attente';
        subtitle = 'Toutes les heures sont validées !';
        icon = CupertinoIcons.checkmark_circle;
        break;
      case 'approved':
        title = 'Aucune entrée validée';
        subtitle = 'Les heures validées apparaîtront ici';
        icon = CupertinoIcons.time;
        break;
      default:
        title = 'Aucune entrée';
        subtitle = 'Les heures soumises par l\'équipe apparaîtront ici';
        icon = CupertinoIcons.clock;
    }

    return Center(
      child: SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🎯 RÈGLE 1: Icône simple et claire
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: IOSTheme.systemGray6,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              icon,
              size: 40,
              color: IOSTheme.systemGray3,
            ),
          ),
            const SizedBox(height: 20),
          
          // 📊 RÈGLE 7: Titre principal mis en avant
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: IOSTheme.labelPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Explication secondaire
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 16,
              color: IOSTheme.labelSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        ),
      ),
    );
  }

  // ⚡ RÈGLE 4: Feedback rapide et clair
  Future<void> _updateEntryStatus(dynamic entryId, String newStatus) async {
    try {
      await SupabaseService.client
          .from('timesheet_entries')
          .update({'status': newStatus})
          .eq('id', entryId);
      
      _loadTimesheetEntries();
      
      // ⚡ RÈGLE 4: Feedback immédiat avec couleur ET texte
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  newStatus == 'approved' ? CupertinoIcons.checkmark_circle : CupertinoIcons.xmark_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  'Entrée ${_getStatusLabel(newStatus).toLowerCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: _getStatusColor(newStatus),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(20),
            duration: const Duration(seconds: 3), // ⚡ RÈGLE 4: Durée appropriée
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // ⚡ RÈGLE 4: Feedback d'erreur clair
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Erreur'),
            content: Text('Impossible de mettre à jour l\'entrée.\n\nErreur: $e'),
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

  // Méthodes utilitaires
  List<Map<String, dynamic>> _getFilteredEntries() {
    if (_selectedFilter == 'all') return _timesheetEntries;
    return _timesheetEntries.where((entry) => entry['status'] == _selectedFilter).toList();
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
      case 'approved': return 'Validée';
      case 'rejected': return 'Refusée';
      case 'pending': return 'En attente';
      default: return status;
    }
  }
}