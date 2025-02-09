import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
      _animationController.reset();
      _animationController.forward();
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
            if (widget.onDaySelected != null) {
              widget.onDaySelected!(currentDate);
            }
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
    
    if (widget.isTimesheet && isCurrentMonth) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isCurrentMonth ? onTap : null,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF007AFF)
                  : isToday
                      ? const Color(0xFFE3F2FD)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isWeekend ? Colors.grey.shade300 : const Color(0xFF1784af),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    color: isCurrentMonth
                        ? isSelected
                            ? Colors.white
                            : isWeekend
                                ? const Color(0xFF999999)
                                : const Color(0xFF333333)
                        : const Color(0xFFCCCCCC),
                    fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
                if (!isWeekend) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      '0h',
                      style: TextStyle(
                        fontSize: 9,
                        color: Color(0xFF1784af),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isCurrentMonth ? onTap : null,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF007AFF)
                : isToday
                    ? const Color(0xFFE3F2FD)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Text(
              day.toString(),
              style: TextStyle(
                color: isCurrentMonth
                    ? isSelected
                        ? Colors.white
                        : isWeekend
                            ? const Color(0xFF999999)
                            : const Color(0xFF333333)
                    : const Color(0xFFCCCCCC),
                fontWeight: isToday || isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (widget.showTitle)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_left, color: Color(0xFF007AFF), size: 16),
                          onPressed: _previousMonth,
                          padding: EdgeInsets.zero,
                          splashRadius: 12,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.title != null) ...[
                              Flexible(
                                flex: 1,
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Text(
                                ' - ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.normal,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ],
                            Flexible(
                              flex: 2,
                              child: Text(
                                DateFormat.yMMMM('fr_FR').format(_currentMonth),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF333333),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: IconButton(
                          icon: const Icon(Icons.chevron_right, color: Color(0xFF007AFF), size: 16),
                          onPressed: _nextMonth,
                          padding: EdgeInsets.zero,
                          splashRadius: 12,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                      ),
                      if (!widget.isExpanded)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: IconButton(
                            icon: const Icon(Icons.open_in_full, color: Color(0xFF007AFF), size: 14),
                            onPressed: _toggleExpanded,
                            padding: EdgeInsets.zero,
                            splashRadius: 12,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                            tooltip: 'Agrandir le calendrier',
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Container(
                        height: 24,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _weekDays.map((day) => Expanded(
                            child: Text(
                              day,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF666666),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )).toList(),
                        ),
                      ),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            // Calculer l'espace disponible pour la grille
                            final availableHeight = constraints.maxHeight;
                            final availableWidth = constraints.maxWidth;
                            
                            // Calculer la taille idéale d'une cellule
                            final cellWidth = availableWidth / 7;
                            // Ajuster la hauteur des cellules en fonction de l'espace disponible
                            final cellHeight = availableHeight / 6; // Simplifié pour éviter les calculs qui peuvent causer des erreurs
                            
                            return GridView.count(
                              padding: const EdgeInsets.all(2),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: 7,
                              mainAxisSpacing: 0,
                              crossAxisSpacing: 0,
                              childAspectRatio: cellWidth / cellHeight,
                              children: _buildCalendarDays(),
                            );
                          }
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 