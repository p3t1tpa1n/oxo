// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import des modèles
import 'models/profile.dart';

// Import des pages
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/profile_page.dart';
import 'pages/associate_page.dart';
import 'pages/planning_page.dart';
import 'pages/partners_page.dart';
import 'pages/messaging_page.dart';
import 'pages/actions_page.dart';
import 'pages/figures_page.dart';
import 'pages/calendar_page.dart'; // Import de la page calendrier

// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Entreprise App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1784af),
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/profile': (context) => ProfilePage(profile: currentProfile!),
        '/associate': (context) => const AssociatePage(),
        '/planning': (context) => const PlanningPage(),
        '/partners': (context) => const PartnersPage(),
        '/messaging': (context) => const MessagingPage(),
        '/actions': (context) => const ActionsPage(),
        '/figures': (context) => const FiguresPage(),
        '/calendar': (context) => const CalendarPage(),
      },
    );
  }
}