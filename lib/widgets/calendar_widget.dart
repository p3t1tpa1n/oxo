import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_service.dart';

class CalendarWidget extends StatefulWidget {
  final bool showTitle;
  final String title;
  final Function(DateTime) onDaySelected;
  final bool isExpanded;
  final Function? onExpandToggle;
  final bool isTimesheet;

  const CalendarWidget({
    super.key,
    required this.showTitle,
    required this.title,
    required this.onDaySelected,
    required this.isExpanded,
    this.onExpandToggle,
    this.isTimesheet = false,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> with SingleTickerProviderStateMixin {
  late DateTime _selectedDate;
  late DateTime _currentMonth;
  final List<String> _weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Map<String, double> _dailyHours = {};

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    if (widget.isTimesheet) {
      _loadMonthlyHours();
    }
  }

  Future<void> _loadMonthlyHours() async {
    try {
      final startOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
      final endOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);

      final response = await SupabaseService.client
          .from('timesheet_entries')
          .select('date, hours')
          .eq('user_id', SupabaseService.currentUser!.id)
          .gte('date', startOfMonth.toIso8601String())
          .lte('date', endOfMonth.toIso8601String());

      final entries = List<Map<String, dynamic>>.from(response);
      final Map<String, double> newDailyHours = {};

      for (var entry in entries) {
        final date = DateTime.parse(entry['date']).toIso8601String().split('T')[0];
        newDailyHours[date] = (newDailyHours[date] ?? 0) + (entry['hours'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _dailyHours = newDailyHours;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des heures: $e');
    }
  }

  @override
  void didUpdateWidget(CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isTimesheet) {
      _loadMonthlyHours();
    }
  }

  void _toggleExpanded() {
    if (widget.onExpandToggle != null) {
      widget.onExpandToggle!();
    }
    if (!widget.isExpanded) {
      _showExpandedCalendar();
    }
  }

  void _showExpandedCalendar() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return Material(
            color: Colors.white,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Calendrier',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                          color: const Color(0xFF333333),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double size = constraints.maxWidth > constraints.maxHeight 
                              ? constraints.maxHeight * 0.9
                              : constraints.maxWidth * 0.9;
                          return SizedBox(
                            width: size,
                            height: size,
                            child: CalendarWidget(
                              showTitle: true,
                              title: 'Calendrier',
                              onDaySelected: widget.onDaySelected,
                              isExpanded: true,
                              onExpandToggle: () => Navigator.of(context).pop(),
                              isTimesheet: widget.isTimesheet,
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
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
      _animationController.reset();
      _animationController.forward();
      if (widget.isTimesheet) {
        _loadMonthlyHours();
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _animationController.reset();
      _animationController.forward();
      if (widget.isTimesheet) {
        _loadMonthlyHours();
      }
    });
  }

  List<Widget> _buildCalendarDays() {
    List<Widget> dayWidgets = [];
    
    // Calcul du premier jour du mois
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    int firstWeekday = firstDay.weekday;
    
    // Jours du mois précédent
    final lastMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    int daysInLastMonth = DateUtils.getDaysInMonth(lastMonth.year, lastMonth.month);
    for (int i = 0; i < firstWeekday - 1; i++) {
      final day = daysInLastMonth - (firstWeekday - 2) + i;
      dayWidgets.add(_buildDayWidget(
        day,
        isCurrentMonth: false,
        date: DateTime(lastMonth.year, lastMonth.month, day),
      ));
    }

    // Jours du mois en cours
    int daysInMonth = DateUtils.getDaysInMonth(_currentMonth.year, _currentMonth.month);
    for (int i = 1; i <= daysInMonth; i++) {
      final currentDate = DateTime(_currentMonth.year, _currentMonth.month, i);
      bool isSelected = currentDate.year == _selectedDate.year &&
          currentDate.month == _selectedDate.month &&
          currentDate.day == _selectedDate.day;
      bool isToday = currentDate.year == DateTime.now().year &&
          currentDate.month == DateTime.now().month &&
          currentDate.day == DateTime.now().day;

      dayWidgets.add(
        _buildDayWidget(
          i,
          isSelected: isSelected,
          isToday: isToday,
          date: currentDate,
          onTap: () {
            setState(() {
              _selectedDate = currentDate;
            });
            widget.onDaySelected(currentDate);
                    },
        ),
      );
    }

    // Jours du mois suivant
    int remainingDays = 35 - dayWidgets.length; // 5 semaines complètes
    final nextMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    for (int i = 1; i <= remainingDays; i++) {
      dayWidgets.add(_buildDayWidget(
        i,
        isCurrentMonth: false,
        date: DateTime(nextMonth.year, nextMonth.month, i),
      ));
    }

    return dayWidgets;
  }

  Widget _buildDayWidget(
    int day, {
    bool isCurrentMonth = true,
    bool isSelected = false,
    bool isToday = false,
    DateTime? date,
    VoidCallback? onTap,
  }) {
    final bool isWeekend = date?.weekday == DateTime.saturday || date?.weekday == DateTime.sunday;
    
    return InkWell(
      onTap: isCurrentMonth ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1E3D54).withOpacity(0.8)
              : isToday
                  ? const Color(0xFF1E3D54).withOpacity(0.1)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: isCurrentMonth && !isSelected
              ? Border.all(
                  color: isToday
                      ? const Color(0xFF1E3D54).withOpacity(0.5)
                      : Colors.transparent,
                  width: 0.5,
                )
              : null,
        ),
        child: Center(
          child: Text(
            day.toString(),
            style: TextStyle(
              color: !isCurrentMonth
                  ? Colors.grey.withOpacity(0.5)
                  : isSelected
                      ? Colors.white
                      : isWeekend
                          ? const Color(0xFF666666)
                          : const Color(0xFF333333),
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Format pour le mois et l'année
    final monthYear = DateFormat('MMMM yyyy', 'fr_FR').format(_currentMonth);
    
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tête du calendrier (mois et contrôles)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: _previousMonth,
                    borderRadius: BorderRadius.circular(15),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.chevron_left, size: 16, color: Color(0xFF1E3D54)),
                    ),
                  ),
                  Text(
                    monthYear,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  InkWell(
                    onTap: _nextMonth,
                    borderRadius: BorderRadius.circular(15),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.chevron_right, size: 16, color: Color(0xFF1E3D54)),
                    ),
                  ),
                ],
              ),
            ),
            
            // Jours de la semaine
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _weekDays.map((day) => Expanded(
                  child: Text(
                    day,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                      fontSize: 9,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )).toList(),
              ),
            ),
            
            // Grille du calendrier
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.2,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: 35, // 5 semaines de 7 jours
              itemBuilder: (context, index) {
                final days = _buildCalendarDays();
                return index < days.length ? days[index] : Container();
              },
            ),
          ],
        ),
      ),
    );
  }
} 