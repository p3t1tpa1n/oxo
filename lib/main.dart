// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'services/supabase_service.dart';
import 'services/messaging_service.dart';
import 'services/auth_middleware.dart';
import 'models/user_role.dart';
import 'utils/device_detector.dart';

// Pages génériques
import 'pages/auth/login_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/shared/profile_page.dart';
import 'pages/shared/planning_page.dart';
import 'pages/shared/projects_page.dart';
import 'pages/partner/partners_page.dart';
import 'pages/partner/ios_partners_page.dart';
import 'pages/partner/availability_page.dart';
import 'pages/associate/figures_page.dart';
import 'pages/shared/calendar_page.dart';
import 'pages/dashboard/partner_dashboard_page.dart';
import 'pages/dashboard/client_dashboard_page.dart';
import 'pages/client/client_invoices_page.dart';
import 'pages/associate/timesheet_page.dart';
import 'pages/clients/clients_page.dart';
import 'pages/admin/user_roles_page.dart';
import 'pages/admin/client_requests_page.dart';
import 'pages/partner/actions_page.dart';
import 'pages/messaging/messaging_page.dart' as messaging;
import 'pages/messaging/ios_messaging_page.dart';
import 'pages/projects/ios_project_detail_page.dart';

// Pages iOS spécifiques
import 'pages/auth/ios_login_page.dart';
import 'pages/dashboard/ios_dashboard_page.dart';

// Nouvelles pages iOS UX-Optimisées
import 'pages/associate/ios_mobile_timesheet_page.dart';
import 'pages/admin/ios_mobile_admin_clients_page.dart';
import 'pages/partner/ios_mobile_actions_page.dart';
import 'pages/admin/ios_mobile_client_requests_page.dart';
import 'pages/partner/ios_mobile_availability_page.dart';

// Pages système de missions
import 'pages/partner/ios_mobile_missions_page.dart';
import 'pages/associate/ios_mobile_mission_management_page.dart';

// Pages création de clients
import 'pages/admin/ios_mobile_create_client_page.dart';
import 'pages/admin/create_client_page.dart';

// Pages questionnaire partenaire
import 'pages/partner/ios_partner_questionnaire_page.dart';

// Pages profils partenaires pour associés
import 'pages/associate/ios_partner_profiles_page.dart';
import 'pages/associate/ios_partner_detail_page.dart';
import 'pages/associate/partner_profiles_page.dart';
import 'pages/associate/partner_detail_page.dart';

// Configuration iOS
import 'config/ios_theme.dart';

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
      
      // Initialiser le service de messagerie seulement si Supabase est initialisé
      try {
        debugPrint('Initialisation du service de messagerie...');
        await MessagingService().initialize();
        debugPrint('Service de messagerie initialisé avec succès');
      } catch (e) {
        debugPrint('Erreur lors de l\'initialisation du service de messagerie: $e');
      }
    }

    // Initialisation de window_manager uniquement pour les plateformes desktop
    if (!kIsWeb && !Platform.isIOS && !Platform.isAndroid) {
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
    } else if (kIsWeb) {
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
    _logDeviceInfo(); // Log des informations de détection d'appareil
    _checkInitialRoute();
  }

  /// Détermine si l'application doit utiliser l'interface iOS
  /// - iOS natif → oui
  /// - Web mobile (smartphone/tablette) → oui (interface tactile)
  /// - Web desktop → non (interface macOS)
  bool _isIOS() {
    return DeviceDetector.shouldUseIOSInterface();
  }
  
  /// Informations de debug sur l'appareil détecté
  void _logDeviceInfo() {
    debugPrint('🔍 Détection appareil: ${DeviceDetector.getDeviceInfo()}');
    debugPrint('📱 Interface utilisée: ${_isIOS() ? 'iOS' : 'macOS'}');
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
          backgroundColor: _isIOS() ? IOSTheme.systemGroupedBackground : IOSTheme.darkBlue,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _isIOS() ? IOSTheme.primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(_isIOS() ? 22 : 16),
                    boxShadow: [
                      BoxShadow(
                        color: _isIOS() 
                            ? IOSTheme.primaryBlue.withOpacity(0.3)
                            : Colors.black.withAlpha(26),
                        blurRadius: _isIOS() ? 20 : 10,
                        spreadRadius: _isIOS() ? 0 : 2,
                        offset: _isIOS() ? const Offset(0, 8) : Offset.zero,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      "OXO",
                      style: TextStyle(
                        color: _isIOS() ? Colors.white : IOSTheme.darkBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: _isIOS() ? 28 : 24,
                        fontFamily: _isIOS() ? '.SF Pro Display' : null,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isIOS() ? IOSTheme.primaryBlue : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Chargement...",
                  style: TextStyle(
                    color: _isIOS() ? IOSTheme.labelPrimary : Colors.white,
                    fontSize: 16,
                    fontFamily: _isIOS() ? '.SF Pro Text' : null,
                    decoration: TextDecoration.none,
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
      debugShowCheckedModeBanner: false,
      theme: IOSTheme.materialTheme,
      home: _getHomePage(),
      routes: _getRoutes(),
      navigatorObservers: [AuthMiddleware()],
    );
  }

  Widget _getHomePage() {
    if (!SupabaseService.isAuthenticated) {
      return _isIOS() ? const IOSLoginPage() : const LoginPage();
    }

    final userRole = SupabaseService.currentUserRole;
    debugPrint('Rôle de l\'utilisateur pour la page d\'accueil: $userRole');

    // Sur iOS, utiliser le dashboard iOS unifié avec onglets
    if (_isIOS()) {
      return const IOSDashboardPage();
    }

    // Sur desktop, utiliser la navigation basée sur les rôles
    if (userRole == UserRole.associe) {
      return const DashboardPage();
    } else if (userRole == UserRole.partenaire) {
      return const PartnerDashboardPage();
    } else if (userRole == UserRole.admin) {
      return const DashboardPage();
    } else if (userRole == UserRole.client) {
      return const ClientDashboardPage();
    }

    // Fallback
    return _isIOS() ? const IOSLoginPage() : const LoginPage();
  }

  Map<String, WidgetBuilder> _getRoutes() {
    final routes = <String, WidgetBuilder>{
      // Routes principales avec support iOS
      '/login': (context) => _isIOS() ? const IOSLoginPage() : const LoginPage(),
      '/dashboard': (context) => _isIOS() ? const IOSDashboardPage() : const DashboardPage(),
      '/partner_dashboard': (context) => _isIOS() ? const IOSDashboardPage() : const PartnerDashboardPage(),
      '/client_dashboard': (context) => _isIOS() ? const IOSDashboardPage() : const ClientDashboardPage(),
      
      // Routes fonctionnelles avec adaptation iOS
      '/profile': (context) => const ProfilePage(),
      '/clients': (context) => _isIOS() ? const IOSMobileAdminClientsPage() : const ClientsPage(),
      '/admin/roles': (context) => const UserRolesPage(),
      '/admin/client-requests': (context) => _isIOS() ? const IOSMobileClientRequestsPage() : const ClientRequestsPage(),
      '/messaging': (context) => _isIOS() ? const IOSMessagingPage() : const messaging.MessagingPage(),
      '/settings': (context) => const ProfilePage(),
      '/projects': (context) {
        // final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?; // Variable non utilisée
        return const ProjectsPage();
      },
      '/project_detail': (context) {
        final arguments = ModalRoute.of(context)?.settings.arguments;
        if (arguments != null) {
          return IOSProjectDetailPage(projectId: arguments.toString());
        }
        return const ProjectsPage();
      },
      '/client/projects': (context) => const ClientDashboardPage(),
      '/client/tasks': (context) => const ClientDashboardPage(),
      '/client/invoices': (context) => const ClientInvoicesPage(),
    };

    // Routes spécifiques iOS
    if (_isIOS()) {
      routes.addAll({
        '/ios/login': (context) => const IOSLoginPage(),
        '/ios/dashboard': (context) => const IOSDashboardPage(),
      });
    }

    // Routes complémentaires avec support iOS
    routes.addAll({
      '/associate': (context) => const DashboardPage(),
      '/partner': (context) => const PartnerDashboardPage(),
      '/client': (context) => const ClientDashboardPage(),
      '/planning': (context) => const PlanningPage(),
      '/figures': (context) => const FiguresPage(),
      '/timesheet': (context) => _isIOS() ? const IOSMobileTimesheetPage() : const TimesheetPage(),
      '/partners': (context) => _isIOS() ? const IOSPartnersPage() : const PartnersPage(),
      '/availability': (context) => _isIOS() ? const IOSMobileAvailabilityPage() : const AvailabilityPage(),
      '/actions': (context) => _isIOS() ? const IOSMobileActionsPage() : const ActionsPage(),
      '/missions': (context) => _isIOS() ? const IOSMobileMissionsPage() : const ActionsPage(),
      '/mission-management': (context) => _isIOS() ? const IOSMobileMissionManagementPage() : const ActionsPage(),
      '/create-client': (context) => _isIOS() ? const IOSMobileCreateClientPage() : const CreateClientPage(),
      '/partner-questionnaire': (context) => const IOSPartnerQuestionnairePage(),
      '/partner-profiles': (context) => _isIOS() ? const IOSPartnerProfilesPage() : const PartnerProfilesPage(),
      '/add_user': (context) => const UserRolesPage(),
      '/calendar': (context) => const CalendarPage(),
    });

    return routes;
  }
}