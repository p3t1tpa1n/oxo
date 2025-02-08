// lib/pages/planning_page.dart
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key});

  @override
  _PlanningPageState createState() => _PlanningPageState();
}

class _PlanningPageState extends State<PlanningPage> {
  String selectedMonth = 'Janvier';
  String planningType = 'Global';

  final List<String> months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(showBackButton: true, title: 'Planning Global'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: selectedMonth,
              isExpanded: true,
              items: months.map((String month) {
                return DropdownMenuItem<String>(
                  value: month,
                  child: Text(month, style: const TextStyle(color: Color(0xFF122b35))),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedMonth = value ?? selectedMonth;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Radio<String>(
                value: 'Global',
                groupValue: planningType,
                onChanged: (value) {
                  setState(() {
                    planningType = value ?? planningType;
                  });
                },
              ),
              const Text('Global', style: TextStyle(color: Color(0xFF122b35))),
              Radio<String>(
                value: 'Associé',
                groupValue: planningType,
                onChanged: (value) {
                  setState(() {
                    planningType = value ?? planningType;
                  });
                },
              ),
              const Text('Associé', style: TextStyle(color: Color(0xFF122b35))),
            ],
          ),
          Expanded(
            child: Center(
              child: Text(
                'Affichage du planning $planningType pour le mois de $selectedMonth',
                style: const TextStyle(fontSize: 18, color: Color(0xFF122b35)),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}