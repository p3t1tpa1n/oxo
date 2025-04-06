import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';
import '../models/user_role.dart';
import 'package:js/js.dart' as js;

class SupabaseService {
  static SupabaseClient? _client;
  static SupabaseClient get client => _client!;
  static UserRole? _currentUserRole;

  static Future<bool> initialize() async {
    if (_client != null) return true;

    debugPrint('Initialisation de Supabase...');
    
    try {
      // Chargement du fichier .env
      debugPrint('Chargement du fichier .env');
      try {
        await dotenv.load(fileName: '.env');
      } catch (e) {
        debugPrint('Avertissement: Impossible de charger le fichier .env: $e');
        // Continuer même si le fichier .env n'est pas trouvé
      }
      
      String? url;
      String? anonKey;
      
      if (kIsWeb) {
        debugPrint('Exécution en mode Web - recherche des variables d\'environnement');
        url = _getEnvVar('SUPABASE_URL');
        anonKey = _getEnvVar('SUPABASE_ANON_KEY');
        
        debugPrint('URL Supabase: ${url != null ? 'Trouvée' : 'Non trouvée'}');
        debugPrint('Clé anonyme: ${anonKey != null ? 'Trouvée' : 'Non trouvée'}');
        
        // En mode web, si les variables ne sont pas trouvées, utiliser des valeurs par défaut pour le développement
        if (kDebugMode && (url == null || anonKey == null)) {
          url = url ?? 'https://msexomjltbhwcutgfmkl.supabase.co';
          anonKey = anonKey ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zZXhvbWpsdGJod2N1dGdmbWtsIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTQ0MzY4MDAsImV4cCI6MjAxMDAxMjgwMH0.QJQd9HOiOqgUP4rkuIgbh4vXH8goaWRU-NDGw7QiLi4';
          debugPrint('Mode développement: Utilisation de valeurs par défaut pour Supabase');
        }
      } else {
        // Mode natif, utiliser directement dotenv
        url = dotenv.env['SUPABASE_URL'];
        anonKey = dotenv.env['SUPABASE_ANON_KEY'];
        
        debugPrint('URL Supabase: $url');
        debugPrint('Clé anonyme: ${anonKey != null ? 'Trouvée' : 'Non trouvée'}');
        
        // En mode natif, si les variables ne sont pas trouvées, utiliser des valeurs par défaut pour le développement
        if (kDebugMode && (url == null || anonKey == null)) {
          url = url ?? 'https://msexomjltbhwcutgfmkl.supabase.co';
          anonKey = anonKey ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zZXhvbWpsdGJod2N1dGdmbWtsIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTQ0MzY4MDAsImV4cCI6MjAxMDAxMjgwMH0.QJQd9HOiOqgUP4rkuIgbh4vXH8goaWRU-NDGw7QiLi4';
          debugPrint('Mode développement: Utilisation de valeurs par défaut pour Supabase');
        }
      }
      
      if (url == null || anonKey == null) {
        debugPrint('ERREUR CRITIQUE: Variables Supabase manquantes');
        return false;
      }
      
      debugPrint('Création du client Supabase avec URL: $url');
      _client = SupabaseClient(url, anonKey);
      
      // Vérifie si une session existe
      final session = _client!.auth.currentSession;
      if (session != null) {
        debugPrint('Session existante trouvée');
      } else {
        debugPrint('Aucune session existante');
      }
      
      return true;
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de Supabase: $e');
      
      // En mode développement, créer un client fictif pour éviter les erreurs
      if (kDebugMode) {
        debugPrint('Mode développement: Création d\'un client Supabase fictif');
        _client = SupabaseClient(
          'https://msexomjltbhwcutgfmkl.supabase.co',
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zZXhvbWpsdGJod2N1dGdmbWtsIiwicm9sZSI6ImFub24iLCJpYXQiOjE2OTQ0MzY4MDAsImV4cCI6MjAxMDAxMjgwMH0.QJQd9HOiOqgUP4rkuIgbh4vXH8goaWRU-NDGw7QiLi4'
        );
        return true;
      }
      
      return false;
    }
  }

  static String? _getEnvVar(String key) {
    // Essayer d'abord le fichier .env
    String? value = dotenv.env[key];
    if (value != null) {
      debugPrint('Variable trouvée dans .env: $key');
      return value;
    }

    if (kIsWeb) {
      // En mode web, essayer de récupérer depuis window.ENV
      try {
        // Cette partie sera gérée par le JavaScript injecté dans index.html
        value = _getWebEnvVar(key);
        if (value != null) {
          debugPrint('Variable trouvée dans window: $key');
          return value;
        }
      } catch (e) {
        debugPrint('Erreur lors de la récupération de la variable web $key: $e');
      }
    }

    debugPrint('Variable non trouvée: $key');
    return null;
  }

  static String? _getWebEnvVar(String key) {
    // Cette méthode sera appelée uniquement en mode web
    if (!kIsWeb) return null;
    
    try {
      // Essaie d'accéder à window.getEnvVar
      final js.JsObject? window = js.context;
      if (window != null && window.hasProperty('getEnvVar')) {
        final value = window.callMethod('getEnvVar', [key]);
        if (value != null && value != 'undefined' && value != '') {
          return value.toString();
        }
      }
      
      // Essaie d'accéder à window.ENV
      if (window != null && window.hasProperty('ENV')) {
        final env = window['ENV'];
        if (env != null && env is js.JsObject && env.hasProperty(key)) {
          final value = env[key];
          if (value != null && value != 'undefined' && value != '') {
            return value.toString();
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la variable web $key: $e');
    }
    
    return null;
  }

  static UserRole? get currentUserRole => _currentUserRole;

  static User? get currentUser {
    return client.auth.currentUser;
  }

  static Future<UserRole?> getCurrentUserRole() async {
    try {
      if (currentUser == null) {
        debugPrint('getCurrentUserRole: Aucun utilisateur connecté');
        return null;
      }

      debugPrint('getCurrentUserRole: Récupération du rôle pour l\'utilisateur ${currentUser!.id}');
      final List<dynamic> response = await client.rpc('get_users');

      debugPrint('getCurrentUserRole: Réponse reçue: $response');

      if (response.isEmpty) {
        debugPrint('getCurrentUserRole: Aucun utilisateur trouvé');
        return null;
      }

      final userProfile = response.firstWhere(
        (user) => user['user_id'] == currentUser!.id,
        orElse: () => null,
      );

      debugPrint('getCurrentUserRole: Profil trouvé: $userProfile');

      if (userProfile == null) {
        debugPrint('getCurrentUserRole: Profil non trouvé pour l\'utilisateur ${currentUser!.id}');
        return null;
      }

      final role = userProfile['user_role'] as String;
      debugPrint('getCurrentUserRole: Rôle trouvé: $role');

      switch (role) {
        case 'associe':
          return UserRole.associe;
        case 'partenaire':
          return UserRole.partenaire;
        case 'admin':
          return UserRole.admin;
        default:
          debugPrint('getCurrentUserRole: Rôle non reconnu: $role');
          return null;
      }
    } catch (e, stackTrace) {
      debugPrint('Erreur lors de la récupération du rôle: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  static Future<void> setUserRole(String userId, UserRole role) async {
    try {
      await client
          .from('profiles')
          .update({'role': role.toString().split('.').last})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Erreur lors de la modification du rôle: $e');
      rethrow;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Tentative de connexion pour: $email');
      
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        _currentUserRole = await getCurrentUserRole();
        debugPrint('Connexion réussie avec le rôle: $_currentUserRole');
      }
      
      return response;
    } catch (e) {
      debugPrint('Erreur lors de la connexion: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      debugPrint('Tentative de déconnexion...');
      await client.auth.signOut();
      _currentUserRole = null;
      debugPrint('Déconnexion réussie');
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
      rethrow;
    }
  }

  static bool get isAuthenticated {
    try {
      // Si le client est null, considérer comme non authentifié
      if (_client == null) return false;
      
      // En mode développement, si le rôle est défini, considérer comme authentifié
      if (kDebugMode && _currentUserRole != null) {
        return true;
      }
      
      final session = client.auth.currentSession;
      final isValid = session != null && !session.isExpired;
      debugPrint('Vérification de l\'authentification: ${isValid ? 'Authentifié' : 'Non authentifié'}');
      return isValid;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'authentification: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchTasks() async {
    try {
      if (kDebugMode) {
        try {
          final response = await client
            .from('tasks')
            .select()
            .order('created_at', ascending: false);
          
          return List<Map<String, dynamic>>.from(response);
        } catch (e) {
          debugPrint('Erreur lors de la récupération des tâches en mode développement: $e');
          
          // Retourner des données fictives pour le développement
          return [
            {
              'id': 1,
              'title': 'Réunion avec client A',
              'description': 'Présentation des nouveaux services',
              'due_date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
              'user_id': 'dev-user-id',
              'status': 'pending',
              'priority': 'high',
              'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
            },
            {
              'id': 2,
              'title': 'Préparation présentation',
              'description': 'Slides pour la conférence',
              'due_date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
              'user_id': 'dev-user-id',
              'status': 'in_progress',
              'priority': 'medium',
              'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
            },
            {
              'id': 3,
              'title': 'Rapport mensuel',
              'description': 'Compilation des résultats du mois',
              'due_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              'user_id': 'dev-user-id',
              'status': 'completed',
              'priority': 'low',
              'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
            },
          ];
        }
      }
      
      final response = await client
        .from('tasks')
        .select()
        .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des tâches: $e');
      return [];
    }
  }

  static Future<void> insertTask(Map<String, dynamic> taskData) async {
    try {
      await client.from('tasks').insert(taskData);
    } catch (e) {
      debugPrint('Erreur lors de l\'insertion de la tâche: $e');
      rethrow;
    }
  }

  static Future<void> updateTask(int taskId, Map<String, dynamic> updates) async {
    try {
      await client.from('tasks').update(updates).eq('id', taskId);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la tâche: $e');
      rethrow;
    }
  }

  static Future<void> deleteTask(int taskId) async {
    try {
      await client.from('tasks').delete().eq('id', taskId);
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la tâche: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final List<dynamic> response = await client.rpc('get_users');
      if (response.isEmpty) {
        return null;
      }
      return response.firstWhere(
        (user) => user['user_id'] == userId,
        orElse: () => null,
      );
    } catch (e) {
      debugPrint('Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getPartners() async {
    try {
      final List<dynamic> response = await client.rpc('get_users');
      return List<Map<String, dynamic>>.from(
        response.where((user) => user['user_role'] == 'partenaire')
      );
    } catch (e) {
      debugPrint('Erreur lors de la récupération des partenaires: $e');
      return [];
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = Version.parse(packageInfo.version);
      
      final response = await http.get(Uri.parse('https://api.github.com/repos/votre-org/votre-repo/releases/latest'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = Version.parse(data['tag_name'].replaceAll('v', ''));
        
        if (latestVersion > currentVersion) {
          _showUpdateDialog();
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des mises à jour: $e');
    }
  }

  void _showUpdateDialog() {
    // ... existing code ...
  }

  Future<void> _downloadAndInstallUpdate() async {
    try {
      final response = await http.get(Uri.parse('https://api.github.com/repos/votre-org/votre-repo/releases/latest'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final downloadUrl = data['assets'][0]['browser_download_url'];
        
        final appDir = await getApplicationDocumentsDirectory();
        final updateFile = File('${appDir.path}/update.apk');
        
        final updateResponse = await http.get(Uri.parse(downloadUrl));
        await updateFile.writeAsBytes(updateResponse.bodyBytes);
        
        // ... existing code ...
      }
    } catch (e) {
      debugPrint('Erreur lors du téléchargement de la mise à jour: $e');
    }
  }

  Future<void> _installUpdate(File updateFile) async {
    try {
      // ... existing code ...
    } catch (e) {
      debugPrint('Erreur lors de l\'installation de la mise à jour: $e');
    }
  }

  // Méthode pour générer des heures fictives pour le développement
  static List<Map<String, dynamic>> getMockTimeEntries() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<Map<String, dynamic>> entries = [];
    
    // Générer des entrées pour les 7 derniers jours
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: i));
      final hours = (i % 3 == 0) ? 8 : (i % 3 == 1) ? 7 : 6;
      
      entries.add({
        'id': i + 1,
        'user_id': 'dev-user-id',
        'date': date.toIso8601String(),
        'hours': hours,
        'description': 'Travail sur projet OXO - Jour ${i+1}',
        'created_at': date.toIso8601String(),
      });
    }
    
    return entries;
  }

  // Méthode pour récupérer les heures travaillées
  static Future<List<Map<String, dynamic>>> fetchTimeEntries(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      if (kDebugMode) {
        try {
          var query = client.from('time_entries').select();
          
          if (userId.isNotEmpty) {
            query = query.eq('user_id', userId);
          }
          
          if (startDate != null) {
            query = query.gte('date', startDate.toIso8601String());
          }
          
          if (endDate != null) {
            query = query.lte('date', endDate.toIso8601String());
          }
          
          final response = await query.order('date', ascending: false);
          return List<Map<String, dynamic>>.from(response);
        } catch (e) {
          debugPrint('Erreur lors de la récupération des heures en mode développement: $e');
          return getMockTimeEntries();
        }
      }
      
      var query = client.from('time_entries').select();
      
      if (userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }
      
      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String());
      }
      
      final response = await query.order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors du chargement des heures: $e');
      return [];
    }
  }

  // Méthode pour générer des événements de calendrier fictifs pour le développement
  static List<Map<String, dynamic>> getMockCalendarEvents() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final List<Map<String, dynamic>> events = [];
    
    // Générer des événements pour les 14 prochains jours
    for (int i = -2; i < 12; i++) {
      final date = today.add(Duration(days: i));
      final uniqueId = 'event-${i + 3}';
      
      // Un événement tous les deux jours environ
      if (i % 2 == 0) {
        events.add({
          'id': uniqueId,
          'title': i % 6 == 0 ? 'Réunion d\'équipe' : 
                  i % 6 == 2 ? 'Rendez-vous client' : 
                  i % 6 == 4 ? 'Point d\'avancement' : 'Atelier projet',
          'start_time': DateTime(date.year, date.month, date.day, 9 + (i % 3) * 2, 0).toIso8601String(),
          'end_time': DateTime(date.year, date.month, date.day, 10 + (i % 3) * 2, 30).toIso8601String(),
          'description': 'Description détaillée pour l\'événement $uniqueId',
          'location': i % 4 == 0 ? 'Bureau principal' : 'Salle de réunion A',
          'user_id': 'dev-user-id',
          'created_at': date.subtract(const Duration(days: 5)).toIso8601String(),
        });
      }
    }
    
    return events;
  }

  // Méthode pour récupérer les événements du calendrier
  static Future<List<Map<String, dynamic>>> fetchCalendarEvents({DateTime? startDate, DateTime? endDate}) async {
    try {
      debugPrint('Chargement des événements du calendrier...');
      
      if (kDebugMode) {
        try {
          var query = client.from('calendar_events').select();
          
          if (startDate != null) {
            query = query.gte('start_time', startDate.toIso8601String());
          }
          
          if (endDate != null) {
            query = query.lte('start_time', endDate.toIso8601String());
          }
          
          final response = await query.order('start_time');
          return List<Map<String, dynamic>>.from(response);
        } catch (e) {
          debugPrint('Erreur lors de la récupération des événements en mode développement: $e');
          return getMockCalendarEvents();
        }
      }
      
      var query = client.from('calendar_events').select();
      
      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }
      
      if (endDate != null) {
        query = query.lte('start_time', endDate.toIso8601String());
      }
      
      final response = await query.order('start_time');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors du chargement des événements du calendrier: $e');
      return [];
    }
  }
} 