import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/calendar_widget.dart';
import '../../widgets/top_bar.dart';
import '../../widgets/side_menu.dart';

class TimesheetPage extends StatelessWidget {
  const TimesheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const SideMenu(selectedRoute: '/timesheet'),
          Expanded(
            child: Column(
              children: [
                const TopBar(title: 'Feuille de temps'),
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 64,
                          color: Color(0xFF1E3D54),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Fonctionnalité en développement',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3D54),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cette page sera bientôt disponible.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 