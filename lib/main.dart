// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'services/supabase_service.dart';
import 'services/update_service.dart';
import 'widgets/update_dialog.dart';

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
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr_FR', null);
    
    print('Initialisation de Supabase...'); // Debug
    await SupabaseService.initialize();
    print('Supabase initialisé avec succès'); // Debug

    // Initialisation de window_manager
    await windowManager.ensureInitialized();

    // Configuration de la fenêtre
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      minimumSize: Size(1200, 800),
      center: true,
      backgroundColor: Colors.white,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    
    runApp(const MainApp());
  } catch (e) {
    print('Erreur lors de l\'initialisation: $e'); // Debug
    rethrow;
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final updateInfo = await UpdateService.checkForUpdates();
      if (updateInfo != null && mounted) {
        // Attendre un peu pour que l'application soit complètement chargée
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;

        final shouldUpdate = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => UpdateDialog(
            newVersion: updateInfo['version'],
            description: updateInfo['description'],
            downloadUrl: updateInfo['downloadUrl'],
          ),
        );

        if (shouldUpdate == true) {
          // L'utilisateur a choisi de mettre à jour, l'application se fermera après l'installation
          SystemNavigator.pop();
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des mises à jour: $e');
    }
  }

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