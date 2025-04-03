// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'services/supabase_service.dart';
import 'services/auth_middleware.dart';
import 'pages/auth/login_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/shared/profile_page.dart';
import 'pages/shared/planning_page.dart';
import 'pages/partner/partners_page.dart';
import 'pages/shared/messaging_page.dart';
import 'pages/partner/actions_page.dart';
import 'pages/associate/figures_page.dart';
import 'pages/shared/calendar_page.dart';
import 'pages/dashboard/partner_dashboard_page.dart';
import 'pages/associate/timesheet_page.dart';

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
    bool initSuccess = await SupabaseService.initialize();
    
    if (!initSuccess) {
      debugPrint('AVERTISSEMENT: Échec de l\'initialisation de Supabase, l\'application fonctionnera sans connexion');
    } else {
      debugPrint('Supabase initialisé avec succès');
      debugPrint('État de la session: ${SupabaseService.client.auth.currentSession != null ? 'Active' : 'Inactive'}');
      debugPrint('État de l\'utilisateur: ${SupabaseService.currentUser != null ? 'Connecté' : 'Non connecté'}');
    }

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

    return MaterialApp(
      title: 'Oxo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: const Color(0xFF122b35),
          displayColor: const Color(0xFF122b35),
        ),
      ),
      home: _getHomePage(),
      routes: _getRoutes(),
      navigatorObservers: [AuthMiddleware()],
    );
  }

  Widget _getHomePage() {
    if (!SupabaseService.isAuthenticated) {
      return const LoginPage();
    }

    final userRole = SupabaseService.currentUserRole;
    if (userRole == UserRole.associe) {
      return const DashboardPage();
    } else if (userRole == UserRole.partenaire) {
      return const PartnerDashboardPage();
    }

    return const LoginPage();
  }

  Map<String, WidgetBuilder> _getRoutes() {
    final routes = <String, WidgetBuilder>{
      '/': (context) => _getHomePage(),
      '/login': (context) => const LoginPage(),
    };

    if (SupabaseService.isAuthenticated) {
      final userRole = SupabaseService.currentUserRole;
      if (userRole == UserRole.associe) {
        routes.addAll({
          '/associate': (context) => const DashboardPage(),
          '/figures': (context) => const FiguresPage(),
          '/timesheet': (context) => const TimesheetPage(),
        });
      } else if (userRole == UserRole.partenaire) {
        routes.addAll({
          '/partner': (context) => const PartnerDashboardPage(),
          '/partners': (context) => const PartnersPage(),
          '/actions': (context) => const ActionsPage(),
        });
      }

      // Routes communes
      routes.addAll({
        '/profile': (context) => const ProfilePage(),
        '/planning': (context) => const PlanningPage(),
        '/messaging': (context) => const MessagingPage(),
        '/calendar': (context) => const CalendarPage(),
      });
    }

    return routes;
  }
}