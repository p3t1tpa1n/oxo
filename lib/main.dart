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
import 'pages/partner_dashboard_page.dart';  // Import de la page de tableau de bord

// lib/main.dart
void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr_FR', null);
    
    debugPrint('Initialisation de Supabase...');
    await SupabaseService.initialize();
    debugPrint('Supabase initialisé avec succès');
    debugPrint('État de la session: ${SupabaseService.client.auth.currentSession}');
    debugPrint('État de l\'utilisateur: ${SupabaseService.currentUser}');

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
    debugPrint('Erreur critique lors de l\'initialisation: $e');
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
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    try {
      debugPrint('Vérification de l\'état de l\'authentification...');
      final session = SupabaseService.client.auth.currentSession;
      debugPrint('Session trouvée: ${session != null}');
      
      if (session == null && mounted) {
        debugPrint('Aucune session active, redirection vers la page de connexion');
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la session: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OXO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3D54),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3D54),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/': (context) => const DashboardPage(),
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const PartnerDashboardPage(),
        '/profile': (context) => const ProfilePage(),
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