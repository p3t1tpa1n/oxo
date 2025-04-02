// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/supabase_service.dart';
import 'services/version_service.dart';
import 'services/auth_middleware.dart';

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
import 'pages/timesheet_page.dart';

// lib/main.dart
void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('fr_FR', null);
    
    // Forcer l'orientation portrait sur mobile
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    debugPrint('Initialisation de Supabase...');
    await SupabaseService.initialize();
    debugPrint('Supabase initialisé avec succès');
    debugPrint('État de la session: ${SupabaseService.client.auth.currentSession}');
    debugPrint('État de l\'utilisateur: ${SupabaseService.currentUser}');

    // Initialisation de window_manager uniquement si ce n'est pas le web
    if (!kIsWeb) {
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
    } else {
      // Sur le web, masquer la barre d'URL et de navigation
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    
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
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    setState(() {
      _isInitializing = true;
    });
    
    try {
      debugPrint('Vérification de l\'état de l\'authentification...');
      // Une petite pause pour garantir que l'écran de chargement s'affiche
      await Future.delayed(const Duration(milliseconds: 500));
      
      final session = SupabaseService.client.auth.currentSession;
      debugPrint('Session trouvée: ${session != null}');
      
      if (session == null && mounted) {
        debugPrint('Aucune session active, redirection vers la page de connexion');
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification de la session: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF1E3D54),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "OXO",
                      style: TextStyle(
                        color: Color(0xFF1E3D54),
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Chargement...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Détermine la route initiale en fonction de l'authentification
    Widget home;
    if (!SupabaseService.isAuthenticated) {
      home = const LoginPage();
    } else {
      // Selon le rôle, charger la page appropriée
      final userRole = SupabaseService.currentUserRole;
      if (userRole == UserRole.associe) {
        home = const DashboardPage();
      } else if (userRole == UserRole.partenaire) {
        home = const PartnerDashboardPage();
      } else {
        // En cas de rôle inconnu, charger la page de connexion
        home = const LoginPage();
      }
    }

    return MaterialApp(
      title: 'OXO',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1E3D54),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E3D54),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E3D54),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3D54),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E3D54),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
      builder: (context, child) {
        // Ajout d'un mode plein écran sur web
        if (kIsWeb) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: 1.0,
              padding: EdgeInsets.zero,
            ),
            child: Scaffold(
              backgroundColor: const Color(0xFFF5F5F5),
              body: Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 1200,
                    maxHeight: 800,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child!,
                ),
              ),
            ),
          );
        }
        return child!;
      },
      home: home,
      // Routes pour la navigation
      routes: {
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
        '/timesheet': (context) => const TimesheetPage(),
      },
      // Avant de naviguer, vérifier l'authentification
      navigatorObservers: [
        AuthMiddleware(),
      ],
    );
  }
}