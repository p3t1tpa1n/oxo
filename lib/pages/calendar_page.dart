import 'package:flutter/material.dart';
import '../models/day_data.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  final List<String> months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  late Future<List<DayData>> dayDataFuture;

  @override
  void initState() {
    super.initState();
    // ✅ Ajout d'un try-catch pour éviter les crashs
    try {
      dayDataFuture = DayData.fetchDayData();
    } catch (e) {
      dayDataFuture = Future.error("Erreur de chargement des données");
    }
  }

  @override
  Widget build(BuildContext context) {
    int daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;
    int firstWeekday = DateTime(selectedYear, selectedMonth, 1).weekday;
    int lastWeekday = DateTime(selectedYear, selectedMonth, daysInMonth).weekday;

    List<int> previousMonthDays = List.generate(firstWeekday - 1, (index) => 0);
    List<int> days = List.generate(daysInMonth, (index) => index + 1);
    List<int> nextMonthDays = List.generate(7 - lastWeekday, (index) => 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Planning Perso"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DropdownButton<String>(
              value: months[(selectedMonth - 1).clamp(0, months.length - 1)], // ✅ Correction pour éviter les erreurs
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedMonth = months.indexOf(newValue) + 1;
                  });
                }
              },
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black),
              underline: Container(),
              items: months.map((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // ✅ Jours de la semaine
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                Text("L", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("M", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("M", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("J", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("V", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("S", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("D", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            // ✅ Grille des jours avec gestion des erreurs
            Expanded(
              child: FutureBuilder<List<DayData>>(
                future: dayDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text("Erreur : ${snapshot.error}"));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("Aucune donnée disponible."));
                  } else {
                    final dayDataList = snapshot.data!;
                    final Map<int, Color> dayColors = {
                      for (var dayData in dayDataList) dayData.day: dayData.color,
                    };

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7, // 7 jours par ligne
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: previousMonthDays.length + days.length + nextMonthDays.length,
                      itemBuilder: (context, index) {
                        if (index < previousMonthDays.length || index >= previousMonthDays.length + days.length) {
                          // ✅ Jours grisés (précédent ou suivant)
                          return Container(
                            decoration: const BoxDecoration(
                              color: Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          );
                        }

                        int day = days[index - previousMonthDays.length];
                        Color dayColor = dayColors[day] ?? Colors.white;

                        return Container(
                          decoration: BoxDecoration(
                            color: dayColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              "$day",
                              style: TextStyle(
                                color: dayColor == Colors.black ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}