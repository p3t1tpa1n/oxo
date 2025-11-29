import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_service.dart';

class IOSMobileAvailabilityPage extends StatefulWidget {
  final bool showHeader;
  
  const IOSMobileAvailabilityPage({
    Key? key,
    this.showHeader = true,
  }) : super(key: key);

  @override
  State<IOSMobileAvailabilityPage> createState() => _IOSMobileAvailabilityPageState();
}

class _IOSMobileAvailabilityPageState extends State<IOSMobileAvailabilityPage> with SingleTickerProviderStateMixin {
  // État général
  List<Map<String, dynamic>> _availabilities = [];
  bool _isLoading = true;
  DateTime _currentDate = DateTime.now();
  bool _isMonthView = false; // false = semaine, true = mois
  
  // Pour l'onglet partenaires
  List<Map<String, dynamic>> _partners = [];
  Map<String, dynamic>? _selectedPartner;
  List<Map<String, dynamic>> _partnerAvailabilities = [];
  
  // Tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Commencer au début de la semaine courante
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

  DateTime get _weekStart {
    return _currentDate.subtract(Duration(days: _currentDate.weekday - 1));
  }

  DateTime get _monthStart {
    return DateTime(_currentDate.year, _currentDate.month, 1);
  }

  Future<void> _loadAvailabilities() async {
    setState(() => _isLoading = true);
    
    try {
      DateTime startDate;
      DateTime endDate;
      
      if (_isMonthView) {
        startDate = _monthStart;
        endDate = DateTime(_currentDate.year, _currentDate.month + 1, 0);
      } else {
        startDate = _weekStart;
        endDate = _weekStart.add(const Duration(days: 6));
      }
      
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

  Future<void> _loadPartnerAvailabilities() async {
    if (_selectedPartner == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      DateTime startDate;
      DateTime endDate;
      
      if (_isMonthView) {
        startDate = _monthStart;
        endDate = DateTime(_currentDate.year, _currentDate.month + 1, 0);
      } else {
        startDate = _weekStart;
        endDate = _weekStart.add(const Duration(days: 6));
      }
      
      final partnerId = _selectedPartner!['user_id']?.toString() ?? '';
      
      final response = await SupabaseService.client
          .from('partner_availability')
          .select('*')
          .eq('partner_id', partnerId)
          .gte('date', startDate.toIso8601String().split('T')[0])
          .lte('date', endDate.toIso8601String().split('T')[0])
          .order('date');
      
      if (mounted) {
        setState(() {
          _partnerAvailabilities = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement disponibilités partenaire: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToPreviousPeriod() {
    setState(() {
      if (_isMonthView) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
      } else {
        _currentDate = _currentDate.subtract(const Duration(days: 7));
      }
    });
    if (_tabController.index == 0) {
      _loadAvailabilities();
    } else {
      _loadPartnerAvailabilities();
    }
  }

  void _goToNextPeriod() {
    setState(() {
      if (_isMonthView) {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
      } else {
        _currentDate = _currentDate.add(const Duration(days: 7));
      }
    });
    if (_tabController.index == 0) {
      _loadAvailabilities();
    } else {
      _loadPartnerAvailabilities();
    }
  }

  void _goToToday() {
    setState(() {
      final now = DateTime.now();
      _currentDate = now.subtract(Duration(days: now.weekday - 1));
    });
    if (_tabController.index == 0) {
      _loadAvailabilities();
    } else {
      _loadPartnerAvailabilities();
    }
  }

  void _toggleViewMode() {
    setState(() {
      _isMonthView = !_isMonthView;
    });
    if (_tabController.index == 0) {
      _loadAvailabilities();
    } else {
      _loadPartnerAvailabilities();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si pas de header, afficher directement le contenu avec tabs internes
    if (!widget.showHeader) {
      return Container(
        color: CupertinoColors.systemGroupedBackground,
        child: Column(
          children: [
            // Tabs pour basculer entre "Mes disponibilités" et "Partenaires"
            Material(
              color: CupertinoColors.systemGroupedBackground,
              child: TabBar(
                controller: _tabController,
                labelColor: CupertinoColors.systemBlue,
                unselectedLabelColor: CupertinoColors.secondaryLabel,
                indicatorColor: CupertinoColors.systemBlue,
                onTap: (_) => setState(() {}),
                tabs: const [
                  Tab(text: 'Mes disponibilités'),
                  Tab(text: 'Partenaires'),
                ],
              ),
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
        ),
      );
    }
    
    // Avec header (navigation standalone)
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
          'Disponibilités',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: CupertinoColors.label,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Tabs
            Material(
              color: CupertinoColors.systemGroupedBackground,
              child: TabBar(
                controller: _tabController,
                labelColor: CupertinoColors.systemBlue,
                unselectedLabelColor: CupertinoColors.secondaryLabel,
                indicatorColor: CupertinoColors.systemBlue,
                onTap: (_) => setState(() {}),
                tabs: const [
                  Tab(text: 'Mes disponibilités'),
                  Tab(text: 'Partenaires'),
                ],
              ),
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
        ),
      ),
    );
  }

  // ============================================
  // ONGLET MES DISPONIBILITÉS
  // ============================================
  
  Widget _buildMyAvailabilityTab() {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Navigation et toggle vue
          _buildNavigationHeader(),
          const SizedBox(height: 16),
          // Affichage semaine ou mois
          _buildPeriodInfo(),
          const SizedBox(height: 20),
          // Calendrier
          _isMonthView ? _buildMonthlyCalendar() : _buildWeeklyCalendar(),
          const SizedBox(height: 24),
          // Boutons d'action
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
          // Bouton précédent
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: _goToPreviousPeriod,
            child: const Icon(CupertinoIcons.chevron_left, color: CupertinoColors.systemBlue),
          ),
          
          // Bouton aujourd'hui + toggle mois/semaine
          Row(
            children: [
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
                onPressed: _goToToday,
                child: const Text(
                  "Aujourd'hui",
                  style: TextStyle(
                    color: CupertinoColors.systemBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: _isMonthView ? CupertinoColors.systemBlue : CupertinoColors.systemGrey6,
                borderRadius: BorderRadius.circular(8),
                onPressed: _toggleViewMode,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.calendar,
                      size: 16,
                      color: _isMonthView ? CupertinoColors.white : CupertinoColors.systemBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _isMonthView ? 'Mois' : 'Semaine',
                      style: TextStyle(
                        color: _isMonthView ? CupertinoColors.white : CupertinoColors.systemBlue,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Bouton suivant
          CupertinoButton(
            padding: const EdgeInsets.all(8),
            onPressed: _goToNextPeriod,
            child: const Icon(CupertinoIcons.chevron_right, color: CupertinoColors.systemBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodInfo() {
    final weekDays = List.generate(7, (index) => _weekStart.add(Duration(days: index)));
    final availableDays = weekDays.where((day) {
      final availability = _getAvailabilityForDate(day, _availabilities);
      return availability['is_available'] == true;
    }).length;

    String periodText;
    if (_isMonthView) {
      periodText = DateFormat('MMMM yyyy', 'fr_FR').format(_currentDate);
    } else {
      periodText = 'Semaine du ${DateFormat('d', 'fr_FR').format(_weekStart)} au ${DateFormat('d MMMM', 'fr_FR').format(_weekStart.add(const Duration(days: 6)))}';
    }

    return Column(
      children: [
        Text(
          periodText,
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
            '$availableDays jours disponibles${_isMonthView ? ' cette semaine' : ''}',
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
    final weekDays = List.generate(7, (index) => _weekStart.add(Duration(days: index)));
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          
          const SizedBox(height: 12),
          
          // Grille des jours
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
    
    // Créer une liste de toutes les semaines du mois
    List<List<DateTime?>> weeks = [];
    List<DateTime?> currentWeek = List.filled(7, null);
    
    // Remplir les jours avant le premier jour du mois
    for (int i = 0; i < firstWeekday - 1; i++) {
      currentWeek[i] = null;
    }
    
    // Remplir les jours du mois
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentDate.year, _currentDate.month, day);
      final weekdayIndex = date.weekday - 1;
      currentWeek[weekdayIndex] = date;
      
      if (weekdayIndex == 6) {
        weeks.add(currentWeek);
        currentWeek = List.filled(7, null);
      }
    }
    
    // Ajouter la dernière semaine si non vide
    if (currentWeek.any((d) => d != null)) {
      weeks.add(currentWeek);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // En-têtes des jours
          Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
            )).toList(),
          ),
          
          const SizedBox(height: 8),
          
          // Grille des semaines
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
      backgroundColor = CupertinoColors.systemGrey6;
      icon = const Icon(CupertinoIcons.minus, color: CupertinoColors.systemGrey3, size: 18);
    } else if (availability.isNotEmpty) {
      if (isAvailable) {
        backgroundColor = CupertinoColors.systemGreen;
        icon = const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 18);
      } else {
        backgroundColor = const Color(0xFFFFE5E5);
        icon = const Icon(CupertinoIcons.xmark, color: CupertinoColors.systemRed, size: 18);
      }
    } else {
      backgroundColor = CupertinoColors.systemGrey6;
      icon = const Icon(CupertinoIcons.minus, color: CupertinoColors.systemGrey3, size: 18);
    }

    return GestureDetector(
      onTap: (canEdit && !isPast) ? () => _editDay(day, availability) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 100,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: isToday ? Border.all(color: CupertinoColors.systemBlue, width: 2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isAvailable ? Colors.white : CupertinoColors.label,
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
              child: icon,
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
      backgroundColor = CupertinoColors.systemGrey6;
      textColor = CupertinoColors.systemGrey3;
    } else if (availability.isNotEmpty) {
      if (isAvailable) {
        backgroundColor = CupertinoColors.systemGreen;
        textColor = Colors.white;
      } else {
        backgroundColor = const Color(0xFFFFE5E5);
        textColor = CupertinoColors.systemRed;
      }
    } else {
      backgroundColor = CupertinoColors.systemGrey6;
      textColor = CupertinoColors.label;
    }

    return GestureDetector(
      onTap: (canEdit && !isPast) ? () => _editDay(day, availability) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: CupertinoColors.systemBlue, width: 2) : null,
        ),
        child: Center(
          child: Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Bouton principal
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.systemBlue,
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(vertical: 14),
              onPressed: _showBulkAvailabilityDialog,
              child: const Text(
                'Définir mes disponibilités',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: _createDefaultAvailabilities,
                  child: const Text(
                    'Auto-remplir',
                    style: TextStyle(
                      color: CupertinoColors.label,
                      fontSize: 14,
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  onPressed: _setWeekendUnavailable,
                  child: const Text(
                    'Week-ends occupés',
                    style: TextStyle(
                      color: CupertinoColors.label,
                      fontSize: 14,
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

  // ============================================
  // ONGLET PARTENAIRES
  // ============================================

  Widget _buildPartnersAvailabilityTab() {
    return Column(
      children: [
        const SizedBox(height: 16),
        // Sélecteur de partenaire
        _buildPartnerSelector(),
        const SizedBox(height: 16),
        
        // Contenu selon sélection
        if (_selectedPartner == null)
          _buildNoPartnerSelected()
        else
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Navigation
                  _buildNavigationHeader(),
                  const SizedBox(height: 16),
                  // Info période
                  _buildPartnerPeriodInfo(),
                  const SizedBox(height: 20),
                  // Calendrier
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
            color: CupertinoColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CupertinoColors.systemGrey4),
          ),
          child: Row(
            children: [
              const Icon(CupertinoIcons.person_2_fill, color: CupertinoColors.systemBlue, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedPartner != null 
                    ? '${_selectedPartner!['first_name'] ?? ''} ${_selectedPartner!['last_name'] ?? ''}'.trim()
                    : 'Sélectionner un partenaire',
                  style: TextStyle(
                    fontSize: 16,
                    color: _selectedPartner != null 
                      ? CupertinoColors.label 
                      : CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
              const Icon(CupertinoIcons.chevron_down, color: CupertinoColors.secondaryLabel, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _showPartnerPicker() {
    if (_partners.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Aucun partenaire'),
          content: const Text('Aucun partenaire n\'est disponible.'),
          actions: [
            CupertinoDialogAction(
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
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: const Text('Annuler'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Choisir un partenaire',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 70),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Liste des partenaires
              Expanded(
                child: ListView.builder(
                  itemCount: _partners.length,
                  itemBuilder: (context, index) {
                    final partner = _partners[index];
                    final name = '${partner['first_name'] ?? ''} ${partner['last_name'] ?? ''}'.trim();
                    final email = partner['email'] ?? partner['user_email'] ?? '';
                    final isSelected = _selectedPartner?['user_id'] == partner['user_id'];
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPartner = partner;
                        });
                        Navigator.pop(context);
                        _loadPartnerAvailabilities();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? CupertinoColors.systemBlue.withOpacity(0.1) : null,
                          border: const Border(
                            bottom: BorderSide(color: CupertinoColors.separator),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: CupertinoColors.systemBlue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.systemBlue,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name.isNotEmpty ? name : 'Partenaire',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (email.isNotEmpty)
                                    Text(
                                      email,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: CupertinoColors.secondaryLabel,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(CupertinoIcons.checkmark, color: CupertinoColors.systemBlue),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
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
              Icon(
                CupertinoIcons.person_2,
                size: 64,
                color: CupertinoColors.systemGrey3,
              ),
              const SizedBox(height: 16),
              const Text(
                'Sélectionnez un partenaire',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choisissez un partenaire dans la liste\npour voir ses disponibilités',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: CupertinoColors.tertiaryLabel,
                ),
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
      final availability = _getAvailabilityForDate(day, _partnerAvailabilities);
      return availability['is_available'] == true;
    }).length;

    String periodText;
    if (_isMonthView) {
      periodText = DateFormat('MMMM yyyy', 'fr_FR').format(_currentDate);
    } else {
      periodText = 'Semaine du ${DateFormat('d', 'fr_FR').format(_weekStart)} au ${DateFormat('d MMMM', 'fr_FR').format(_weekStart.add(const Duration(days: 6)))}';
    }

    return Column(
      children: [
        Text(
          name.isNotEmpty ? name : 'Partenaire',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: CupertinoColors.label,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          periodText,
          style: const TextStyle(
            fontSize: 15,
            color: CupertinoColors.secondaryLabel,
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

  Widget _buildPartnerWeeklyCalendar() {
    final weekDays = List.generate(7, (index) => _weekStart.add(Duration(days: index)));
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          
          const SizedBox(height: 12),
          
          // Grille des jours (lecture seule)
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
    
    for (int i = 0; i < firstWeekday - 1; i++) {
      currentWeek[i] = null;
    }
    
    for (int day = 1; day <= lastDayOfMonth.day; day++) {
      final date = DateTime(_currentDate.year, _currentDate.month, day);
      final weekdayIndex = date.weekday - 1;
      currentWeek[weekdayIndex] = date;
      
      if (weekdayIndex == 6) {
        weeks.add(currentWeek);
        currentWeek = List.filled(7, null);
      }
    }
    
    if (currentWeek.any((d) => d != null)) {
      weeks.add(currentWeek);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // En-têtes des jours
          Row(
            children: ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'].map((day) => Expanded(
              child: Center(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.secondaryLabel,
                  ),
                ),
              ),
            )).toList(),
          ),
          
          const SizedBox(height: 8),
          
          // Grille des semaines (lecture seule)
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
  // MÉTHODES EXISTANTES (conservées)
  // ============================================

  void _editDay(DateTime day, Map<String, dynamic> currentAvailability) {
    bool isAvailable = currentAvailability['is_available'] == true;
    String availabilityType = currentAvailability['availability_type'] ?? 'full_day';
    String notes = currentAvailability['notes'] ?? '';
    final notesController = TextEditingController(text: notes);

    showCupertinoModalPopup(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Material(
          color: Colors.transparent,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.55,
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
                  
                  // Header avec date
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: CupertinoColors.secondaryLabel,
                              fontSize: 16,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Text(
                          DateFormat('EEE d MMM', 'fr_FR').format(day),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.label,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          child: Text(
                            'OK',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: CupertinoColors.systemBlue,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _saveAvailability(day, isAvailable, availabilityType, notesController.text);
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
                          // Toggle disponibilité
                          Text(
                            'Statut',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => isAvailable = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isAvailable ? CupertinoColors.systemGreen : CupertinoColors.systemGrey6,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isAvailable ? CupertinoColors.systemGreen : CupertinoColors.systemGrey4,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.checkmark_circle_fill,
                                          size: 18,
                                          color: isAvailable ? CupertinoColors.white : CupertinoColors.secondaryLabel,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Disponible',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: isAvailable ? CupertinoColors.white : CupertinoColors.label,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setDialogState(() => isAvailable = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: !isAvailable ? CupertinoColors.systemRed : CupertinoColors.systemGrey6,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: !isAvailable ? CupertinoColors.systemRed : CupertinoColors.systemGrey4,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.xmark_circle_fill,
                                          size: 18,
                                          color: !isAvailable ? CupertinoColors.white : CupertinoColors.secondaryLabel,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Occupé',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: !isAvailable ? CupertinoColors.white : CupertinoColors.label,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          if (isAvailable) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Durée',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: CupertinoColors.secondaryLabel,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setDialogState(() => availabilityType = 'full_day'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: availabilityType == 'full_day' 
                                          ? CupertinoColors.systemBlue 
                                          : CupertinoColors.systemGrey6,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: availabilityType == 'full_day' 
                                            ? CupertinoColors.systemBlue 
                                            : CupertinoColors.systemGrey4,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Journée',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: availabilityType == 'full_day' 
                                              ? CupertinoColors.white 
                                              : CupertinoColors.label,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setDialogState(() => availabilityType = 'partial_day'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: availabilityType == 'partial_day' 
                                          ? CupertinoColors.systemBlue 
                                          : CupertinoColors.systemGrey6,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: availabilityType == 'partial_day' 
                                            ? CupertinoColors.systemBlue 
                                            : CupertinoColors.systemGrey4,
                                        ),
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Demi-journée',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: availabilityType == 'partial_day' 
                                              ? CupertinoColors.white 
                                              : CupertinoColors.label,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          Text(
                            'Note',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: CupertinoColors.secondaryLabel,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CupertinoTextField(
                            placeholder: 'Ajouter une note...',
                            controller: notesController,
                            maxLines: 2,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: CupertinoColors.systemGrey4),
                            ),
                            style: const TextStyle(fontSize: 15),
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
        daysOfWeek: [6, 7],
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
  Map<String, dynamic> _getAvailabilityForDate(DateTime date, List<Map<String, dynamic>> availabilities) {
    final dateStr = date.toIso8601String().split('T')[0];
    return availabilities.firstWhere(
      (availability) => availability['date'] == dateStr,
      orElse: () => <String, dynamic>{},
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
