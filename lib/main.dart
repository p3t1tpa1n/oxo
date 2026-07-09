// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:io' show Platform;
import 'package:intl/date_symbol_data_local.dart';
import 'package:window_manager/window_manager.dart';
import 'services/supabase_service.dart';
import 'services/messaging_service.dart';
import 'services/auth_middleware.dart';
import 'utils/device_detector.dart';
import 'models/user_role.dart';

// Pages génériques
import 'pages/auth/login_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/shared/profile_page.dart';
import 'pages/shared/planning_page.dart';
import 'pages/shared/projects_page.dart';
import 'pages/shared/partners_clients_page.dart';
import 'pages/partner/partners_page.dart';
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
import 'pages/projects/ios_project_detail_page.dart';

// Pages iOS spécifiques
import 'pages/auth/ios_login_page.dart';

// Nouvelle architecture iOS professionnelle
import 'app/shells/mobile_shell_professional.dart';
import 'app/shells/desktop_shell.dart';

// Pages système de missions
import 'pages/partner/proposed_missions_page.dart';

// Pages module OXO TIME SHEETS
import 'pages/timesheet/time_entry_page.dart';
import 'pages/timesheet/timesheet_settings_page.dart';
import 'pages/timesheet/timesheet_reporting_page.dart';

// Pages création de clients
import 'pages/admin/ios_mobile_create_client_page.dart';
import 'pages/admin/create_client_page.dart';

// Pages questionnaire partenaire
import 'pages/partner/ios_partner_questionnaire_page.dart';

// Pages profils partenaires pour associés
import 'pages/associate/partner_profiles_page.dart';

// Configuration
import 'config/app_theme.dart';

// lib/main.dart
void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // Couper les logs de diagnostic en production
    if (kReleaseMode) {
      debugPrint = (String? message, {int? wrapWidth}) {};
    }
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
      // La session est déjà restaurée par SupabaseService.initialize() dans main(),
      // la vérification est donc immédiate — pas de délai artificiel.
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
          backgroundColor: _isIOS() ? AppTheme.colors.background : AppTheme.colors.primary,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _isIOS() ? AppTheme.colors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.radius.medium),
                    boxShadow: AppTheme.shadows.medium,
                  ),
                  child: Center(
                    child: Text(
                      "OXO",
                      style: AppTheme.typography.h1.copyWith(
                        color: _isIOS() ? AppTheme.colors.textOnPrimary : AppTheme.colors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isIOS() ? AppTheme.colors.primary : Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Chargement...",
                  style: AppTheme.typography.bodyLarge.copyWith(
                    color: _isIOS() ? AppTheme.colors.textPrimary : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'OXO Time Sheets',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.materialTheme,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      locale: const Locale('fr', 'FR'),
      home: _getHomePage(),
      routes: _getRoutes(),
      navigatorObservers: [AuthMiddleware()],
    );
  }

  Widget _getHomePage() { 
    if (!SupabaseService.isAuthenticated) {
      return _isIOS() ? const IOSLoginPage() : const LoginPage();
    }

    // Sur iOS, utiliser le nouveau MobileShellProfessional
    if (_isIOS()) {
      return const MobileShellProfessional();
    }

    // Sur desktop, rediriger selon le rôle de l'utilisateur
    final userRole = SupabaseService.currentUserRole;
    
    if (userRole == UserRole.client) {
      return const ClientDashboardPage();
    }

    // Pour les autres rôles, rediriger vers la page Missions par défaut
    return DesktopShell(
      currentRoute: '/missions',
      child: const ProjectsPage(),
    );
  }

  /// Sur desktop, toute section vit dans le DesktopShell (sidebar + topbar) ;
  /// sur iOS le widget est rendu tel quel (le shell mobile gère sa navigation).
  Widget _wrapDesktop(String route, Widget child) {
    if (_isIOS()) return child;
    return DesktopShell(currentRoute: route, child: child);
  }

  Map<String, WidgetBuilder> _getRoutes() {
    final routes = <String, WidgetBuilder>{
      // Routes principales avec support iOS
      '/login': (context) => _isIOS() ? const IOSLoginPage() : const LoginPage(),
      '/dashboard': (context) => _isIOS() 
        ? const MobileShellProfessional() 
        : DesktopShell(
            currentRoute: '/dashboard',
            child: const DashboardPage(),
          ),
      '/partner_dashboard': (context) => _isIOS() 
        ? const MobileShellProfessional() 
        : DesktopShell(
            currentRoute: '/partner_dashboard',
            child: const PartnerDashboardPage(),
          ),
      '/client_dashboard': (context) => _isIOS() 
        ? const MobileShellProfessional() 
        : const ClientDashboardPage(),
      
      // Routes fonctionnelles avec adaptation iOS
      '/profile': (context) => _wrapDesktop('/profile', const ProfilePage()),
      '/clients': (context) => _isIOS()
        ? const MobileShellProfessional(initialTab: 'clients')
        : _wrapDesktop('/clients', const ClientsPage()),
      '/admin/roles': (context) =>
        _wrapDesktop('/admin/roles', const UserRolesPage()),
      '/admin/client-requests': (context) => _isIOS()
        ? const MobileShellProfessional(initialTab: 'requests')
        : _wrapDesktop('/admin/client-requests', const ClientRequestsPage()),
      '/messaging': (context) => _isIOS()
        ? const MobileShellProfessional(initialTab: 'messages')
        : _wrapDesktop('/messaging', const messaging.MessagingPage()),
      '/partner/proposed-missions': (context) => const ProposedMissionsPage(),
      '/settings': (context) => const ProfilePage(),
      '/projects': (context) {
        // final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?; // Variable non utilisée
        return _isIOS() 
          ? const ProjectsPage()
          : DesktopShell(
              currentRoute: '/missions',
              child: const ProjectsPage(),
            );
      },
      '/project_detail': (context) {
        final arguments = ModalRoute.of(context)?.settings.arguments;
        if (arguments != null) {
          return IOSProjectDetailPage(projectId: arguments.toString());
        }
        return const ProjectsPage();
      },
      '/mission_detail': (context) {
        final arguments = ModalRoute.of(context)?.settings.arguments;
        if (arguments != null) {
          return IOSProjectDetailPage(projectId: arguments.toString());
        }
        return _isIOS() 
          ? const MobileShellProfessional() 
          : DesktopShell(
              currentRoute: '/missions',
              child: const ProjectsPage(),
            );
      },
      '/client/projects': (context) => const ClientDashboardPage(),
      '/client/tasks': (context) => const ClientDashboardPage(),
      '/client/invoices': (context) => const ClientInvoicesPage(),
    };

    // Routes spécifiques iOS
    if (_isIOS()) {
      routes.addAll({
        '/ios/login': (context) => const IOSLoginPage(),
        '/ios/dashboard': (context) => const MobileShellProfessional(),
      });
    }

    // Routes complémentaires avec support iOS
    routes.addAll({
      '/associate': (context) => _wrapDesktop('/dashboard', const DashboardPage()),
      '/partner': (context) => _wrapDesktop('/dashboard', const PartnerDashboardPage()),
      '/client': (context) => const ClientDashboardPage(),
      '/planning': (context) => _wrapDesktop('/planning', const PlanningPage()),
      '/figures': (context) => _wrapDesktop('/figures', const FiguresPage()),
      '/timesheet': (context) => _isIOS()
        ? const MobileShellProfessional(initialTab: 'timesheet')
        : _wrapDesktop('/timesheet', const TimesheetPage()),

      // Routes module OXO TIME SHEETS
      '/timesheet/entry': (context) =>
        _wrapDesktop('/timesheet/entry', const TimeEntryPage()),
      '/timesheet/settings': (context) =>
        _wrapDesktop('/timesheet/settings', const TimesheetSettingsPage()),
      '/timesheet/reporting': (context) =>
        _wrapDesktop('/timesheet/reporting', const TimesheetReportingPage()),
      
      '/partners': (context) => _isIOS()
        ? const MobileShellProfessional(initialTab: 'clients')
        : _wrapDesktop('/partners', const PartnersPage()),
      '/availability': (context) => _isIOS()
        ? const MobileShellProfessional(initialTab: 'availability')
        : _wrapDesktop('/availability', const AvailabilityPage()),
      '/actions': (context) => _isIOS()
        ? const MobileShellProfessional(initialTab: 'reporting')
        : DesktopShell(
            currentRoute: '/actions',
            child: const ActionsPage(),
          ),
      '/missions': (context) => _isIOS()
        ? const MobileShellProfessional(initialTab: 'missions')
        : DesktopShell(
            currentRoute: '/missions',
            child: const ProjectsPage(),
          ),
      '/mission-management': (context) => _isIOS()
        ? const MobileShellProfessional(initialTab: 'missions')
        : DesktopShell(
            currentRoute: '/mission-management',
            child: const ProjectsPage(),
          ),
      '/create-client': (context) => _isIOS()
        ? const IOSMobileCreateClientPage()
        : _wrapDesktop('/clients', const CreateClientPage()),
      '/partner-questionnaire': (context) => const IOSPartnerQuestionnairePage(),
      '/partner-profiles': (context) => _isIOS()
        ? const MobileShellProfessional(initialTab: 'clients')
        : _wrapDesktop('/partner-profiles', const PartnerProfilesPage()),
      '/partners-clients': (context) =>
        _wrapDesktop('/partners-clients', const PartnersClientsPage()),
      '/add_user': (context) => _wrapDesktop('/admin/roles', const UserRolesPage()),
      '/calendar': (context) => _wrapDesktop('/planning', const CalendarPage()),
    });

    return routes;
  }
}