// lib/pages/associate/associate_page.dart
import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_drawer.dart';

class AssociatePage extends StatelessWidget {
  const AssociatePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> missions = [
      {
        'mission': 'Mission A',
        'dateEstimee': '2025-03-01',
        'facturationMensuelle': '2000€',
        'facturationJournaliere': '100€',
        'superviseur': 'Jean Dupont'
      },
      {
        'mission': 'Mission B',
        'dateEstimee': '2025-04-15',
        'facturationMensuelle': '2500€',
        'facturationJournaliere': '125€',
        'superviseur': 'Marie Durant'
      },
    ];

    return Scaffold(
      appBar: const CustomAppBar(showBackButton: true, title: 'Fiche Associé'),
      drawer: const AppDrawer(),
      body: ListView.builder(
        itemCount: missions.length,
        itemBuilder: (context, index) {
          final mission = missions[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(
                mission['mission'] ?? '',
                style: const TextStyle(color: Color(0xFF122b35)),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date estimée: ${mission['dateEstimee'] ?? ''}', style: const TextStyle(color: Color(0xFF122b35))),
                  Text('Facturation mensuelle: ${mission['facturationMensuelle'] ?? ''}', style: const TextStyle(color: Color(0xFF122b35))),
                  Text('Facturation journalière: ${mission['facturationJournaliere'] ?? ''}', style: const TextStyle(color: Color(0xFF122b35))),
                  Text('Superviseur: ${mission['superviseur'] ?? ''}', style: const TextStyle(color: Color(0xFF122b35))),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}