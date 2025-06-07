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

class SupabaseService {
  static SupabaseClient? _client;
  static SupabaseClient get client => _client!;
  static UserRole? _currentUserRole;

  // URL et clé par défaut
  static const defaultUrl = 'https://dswirxxbzbyhnxsrzyzi.supabase.co';
  static const defaultKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRzd2lyeHhiemJ5aG54c3J6eXppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDkxMTE0MTksImV4cCI6MjA2NDY4NzQxOX0.eIpOuCszUaldsiIxb9WzQcra34VbImWaRHx5lysPtOg';

  static Future<bool> initialize() async {
    if (_client != null) return true;

    debugPrint('Initialisation de Supabase...');
    
    try {
      String url = defaultUrl;
      String anonKey = defaultKey;
      
      if (kIsWeb) {
        // Pour Vercel et autres déploiements web, récupérer les variables depuis window
        debugPrint('Initialisation en mode web (Vercel)');
        try {
          // Tentative d'utiliser les variables d'environnement injectées via window.ENV
          url = _getWebEnvVar('SUPABASE_URL') ?? defaultUrl;
          anonKey = _getWebEnvVar('SUPABASE_ANON_KEY') ?? defaultKey;
          debugPrint('Variables d\'environnement web récupérées: URL=$url');
        } catch (e) {
          debugPrint('Erreur lors de la récupération des variables d\'environnement web: $e');
          debugPrint('Utilisation des valeurs par défaut');
        }
      } else {
        try {
          await dotenv.load(fileName: '.env');
          url = dotenv.env['SUPABASE_URL'] ?? defaultUrl;
          anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? defaultKey;
        } catch (e) {
          debugPrint('Erreur lors du chargement du fichier .env: $e');
        }
      }
      
      debugPrint('Création du client Supabase avec URL: $url');
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: true, // Forcer le mode debug même en production pour diagnostiquer le problème
      );
      
      _client = Supabase.instance.client;
      
      // Vérifie si une session existe
      final session = _client!.auth.currentSession;
      if (session != null) {
        debugPrint('Session existante trouvée');
        _currentUserRole = await getCurrentUserRole();
      } else {
        debugPrint('Aucune session existante');
      }
      
      return true;
    } catch (e, stackTrace) {
      debugPrint('Erreur lors de l\'initialisation de Supabase: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  static String? _getWebEnvVar(String key) {
    if (!kIsWeb) return null;
    
    try {
      // En mode développement, retourner les valeurs par défaut
      if (kDebugMode) {
        if (key == 'SUPABASE_URL') {
          return defaultUrl;
        } else if (key == 'SUPABASE_ANON_KEY') {
          return defaultKey;
        }
      }
      
      // Tenter d'accéder aux variables d'environnement injectées par Vercel
      debugPrint('Tentative d\'accès à la variable d\'environnement web: $key');
      
      // Si nous sommes sur Vercel, les variables sont accessibles via window.ENV
      // Mais comme nous ne pouvons pas appeler directement js.context['ENV'][key],
      // nous utilisons les valeurs par défaut
      
      debugPrint('Utilisation des valeurs par défaut pour les variables d\'environnement web');
      if (key == 'SUPABASE_URL') {
        return defaultUrl;
      } else if (key == 'SUPABASE_ANON_KEY') {
        return defaultKey;
      }
      
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de la variable web $key: $e');
      return null;
    }
  }

  static UserRole? get currentUserRole => _currentUserRole;

  static User? get currentUser => client.auth.currentUser;

  static Future<UserRole?> getCurrentUserRole() async {
    try {
      if (kDebugMode && _currentUserRole != null) {
        debugPrint('getCurrentUserRole: Mode développement, retour du rôle en cache: $_currentUserRole');
        return _currentUserRole;
      }

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

      // Journalisation de tous les utilisateurs pour diagnostic
      debugPrint('Liste complète des utilisateurs:');
      for (var user in response) {
        debugPrint('User ID: ${user['user_id']}, Role: ${user['user_role']}');
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
      debugPrint('getCurrentUserRole: Rôle trouvé dans la base: "$role"');

      // Traitement spécial pour le rôle "client" car il semble poser problème sur Vercel
      if (role.toLowerCase().contains('client')) {
        debugPrint('getCurrentUserRole: Rôle client détecté par contenu, retournant UserRole.client');
        return UserRole.client;
      }

      // Pour les autres rôles, utilisez la méthode standard
      final userRole = UserRole.fromString(role);
      if (userRole == null) {
        debugPrint('ERREUR: Conversion du rôle a échoué pour: "$role"');
        // Tentative de récupération pour les rôles problématiques
        if (role.contains('asso')) return UserRole.associe;
        if (role.contains('parte')) return UserRole.partenaire;
        if (role.contains('admin')) return UserRole.admin;
      } else {
        debugPrint('getCurrentUserRole: Conversion réussie du rôle: "$role" -> $userRole');
      }
      return userRole;
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
          .update({'role': role.toString()})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Erreur lors de la modification du rôle: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final List<dynamic> response = await client.rpc('get_users');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de tous les utilisateurs: $e');
      return [];
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('Tentative de connexion pour: $email');
      
      if (_client == null) {
        debugPrint('Client Supabase non initialisé');
        await initialize();
        if (_client == null) {
          throw Exception('Impossible d\'initialiser le client Supabase');
        }
      }
      
      debugPrint('Tentative de connexion avec les credentials fournis');
      
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      debugPrint('Réponse de Supabase: ${response.user != null ? 'Succès' : 'Échec'}');
      
      if (response.user != null) {
        _currentUserRole = await getCurrentUserRole();
        debugPrint('Connexion réussie avec le rôle: $_currentUserRole');
        return response;
      } else {
        debugPrint('Connexion échouée: Utilisateur non trouvé');
        throw Exception('Utilisateur non trouvé');
      }
    } catch (e, stackTrace) {
      debugPrint('Erreur lors de la connexion: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('Type d\'erreur: ${e.runtimeType}');
      
      if (e.toString().contains('Invalid login credentials')) {
        throw Exception('Email ou mot de passe incorrect');
      } else if (e.toString().contains('Failed to fetch')) {
        throw Exception('Impossible de se connecter au serveur. Vérifiez votre connexion internet.');
      } else {
        throw Exception('Une erreur est survenue lors de la connexion. Veuillez réessayer.');
      }
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
      // Ajout des métadonnées
      taskData['created_by'] = currentUser?.id;
      taskData['updated_by'] = currentUser?.id;
      
      await client.from('tasks').insert(taskData);
    } catch (e) {
      debugPrint('Erreur lors de l\'insertion de la tâche: $e');
      rethrow;
    }
  }

  static Future<void> updateTask(int taskId, Map<String, dynamic> updates) async {
    try {
      // Ajout de la métadonnée updated_by
      updates['updated_by'] = currentUser?.id;
      
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
      debugPrint('getPartners: Réponse brute: $response');
      
      // Filtrer les partenaires en utilisant 'user_role' (confirmé par le diagnostic)
      final partners = List<Map<String, dynamic>>.from(
        response.where((user) {
          final userRole = user['user_role']; // Utiliser user_role directement
          debugPrint('getPartners: Utilisateur ${user['email']} a le rôle: $userRole');
          return userRole == 'partenaire';
        })
      );

      debugPrint('getPartners: ${partners.length} partenaires trouvés');

      // Adapter les champs pour la compatibilité avec l'interface
      final adaptedPartners = partners.map((partner) => {
        'user_id': partner['user_id'],
        'user_email': partner['email'], // Mapper 'email' vers 'user_email'
        'email': partner['email'],
        'first_name': partner['first_name'],
        'last_name': partner['last_name'],
        'phone': partner['phone'],
        'role': partner['user_role'], // Utiliser user_role
        'status': partner['status'],
        'created_at': partner['created_at'],
        'updated_at': partner['updated_at'],
      }).toList();

      debugPrint('getPartners: Partenaires adaptés: $adaptedPartners');
      return adaptedPartners;
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

  // Méthode pour récupérer les heures travaillées
  static Future<List<Map<String, dynamic>>> fetchTimeEntries(String userId, {DateTime? startDate, DateTime? endDate}) async {
    try {
      var query = client.from('timesheet_entries').select();
      
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

  // Méthodes pour la gestion des clients
  static Future<List<Map<String, dynamic>>> fetchClients() async {
    try {
      // Récupérer les utilisateurs avec le rôle 'client' depuis la table profiles avec leurs informations entreprise
      final response = await client
        .from('user_company_info')
        .select('*')
        .eq('role', 'client')
        .order('first_name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des clients: $e');
      return [];
    }
  }

  static Future<void> insertClient(Map<String, dynamic> clientData) async {
    try {
      await client.from('clients').insert(clientData);
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout du client: $e');
      rethrow;
    }
  }

  static Future<void> updateClient(String clientId, Map<String, dynamic> updates) async {
    try {
      await client.from('clients').update(updates).eq('id', clientId);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du client: $e');
      rethrow;
    }
  }

  static Future<void> deleteClient(String clientId) async {
    try {
      await client.from('clients').delete().eq('id', clientId);
    } catch (e) {
      debugPrint('Erreur lors de la suppression du client: $e');
      rethrow;
    }
  }

  // === GESTION DES FACTURES ===

  /// Récupérer toutes les factures (pour admins/associés)
  static Future<List<Map<String, dynamic>>> getAllInvoices() async {
    try {
      final response = await client
          .from('invoice_details')
          .select('*')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération de toutes les factures: $e');
      return [];
    }
  }

  /// Récupérer les factures d'un client spécifique
  static Future<List<Map<String, dynamic>>> getClientInvoices([String? clientUserId]) async {
    try {
      var query = client.from('invoice_details').select('*');
      
      // Si un clientUserId est fourni, filtrer par ce client
      // Sinon, utiliser l'utilisateur connecté (pour les clients qui consultent leurs propres factures)
      final targetUserId = clientUserId ?? currentUser?.id;
      if (targetUserId != null) {
        query = query.eq('client_user_id', targetUserId);
      }
      
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des factures client: $e');
      return [];
    }
  }

  /// Créer une nouvelle facture
  static Future<Map<String, dynamic>?> createInvoice({
    required String clientUserId,
    required String title,
    required String description,
    required double amount,
    required DateTime dueDate,
    String? projectId,
    double? taxRate,
    DateTime? invoiceDate,
    String status = 'draft',
  }) async {
    try {
      // Récupérer l'entreprise de l'utilisateur connecté (admin/associé)
      debugPrint('Tentative de récupération de l\'entreprise pour l\'utilisateur: ${currentUser?.id}');
      
      final userCompany = await getUserCompany();
      debugPrint('Entreprise récupérée: $userCompany');
      
      if (userCompany == null) {
        // Diagnostic plus détaillé
        debugPrint('❌ Aucune entreprise trouvée pour l\'utilisateur');
        
        // Vérifier si l'utilisateur existe dans profiles
        try {
          final userProfile = await getUserProfile(currentUser!.id);
          debugPrint('Profil utilisateur: $userProfile');
          
          if (userProfile == null) {
            throw Exception('Profil utilisateur non trouvé. Contactez l\'administrateur.');
          }
          
          final userRole = userProfile['user_role'] ?? userProfile['role'];
          final companyId = userProfile['company_id'];
          
          debugPrint('Rôle utilisateur: $userRole, company_id: $companyId');
          
          if (companyId == null || companyId == 0) {
            throw Exception(
              'Utilisateur non assigné à une entreprise.\n\n'
              'Solutions:\n'
              '1. Exécutez le script SQL de diagnostic dans Supabase\n'
              '2. Ou contactez l\'administrateur pour vous assigner à une entreprise\n\n'
              'Votre rôle: $userRole\n'
              'Votre ID: ${currentUser?.id}'
            );
          } else {
            throw Exception('Entreprise trouvée (ID: $companyId) mais vue user_company_info inaccessible');
          }
        } catch (e) {
          throw Exception('Erreur lors du diagnostic utilisateur: $e');
        }
      }
      
      if (userCompany['company_id'] == null) {
        throw Exception(
          'Données d\'entreprise incohérentes.\n'
          'Entreprise: ${userCompany['company_name']}\n'
          'ID: ${userCompany['company_id']}\n'
          'Contactez l\'administrateur.'
        );
      }

      debugPrint('✅ Création de facture pour l\'entreprise: ${userCompany['company_name']} (ID: ${userCompany['company_id']})');

      final invoiceData = {
        'company_id': userCompany['company_id'],
        'client_user_id': clientUserId,
        'title': title,
        'description': description,
        'amount': amount,
        'due_date': dueDate.toIso8601String().split('T')[0], // Format YYYY-MM-DD
        'invoice_date': (invoiceDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'status': status,
        'created_by': currentUser!.id,
      };

      if (projectId != null) {
        invoiceData['project_id'] = projectId;
      }
      if (taxRate != null) {
        invoiceData['tax_rate'] = taxRate;
      }

      debugPrint('Données de la facture à insérer: $invoiceData');

      final response = await client
          .from('invoices')
          .insert(invoiceData)
          .select()
          .single();
      
      debugPrint('✅ Facture créée avec succès: ${response['invoice_number']}');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de la facture: $e');
      rethrow;
    }
  }

  /// Mettre à jour une facture
  static Future<void> updateInvoice(int invoiceId, Map<String, dynamic> updates) async {
    try {
      await client
          .from('invoices')
          .update(updates)
          .eq('id', invoiceId);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de la facture: $e');
      rethrow;
    }
  }

  /// Supprimer une facture
  static Future<void> deleteInvoice(int invoiceId) async {
    try {
      await client
          .from('invoices')
          .delete()
          .eq('id', invoiceId);
    } catch (e) {
      debugPrint('Erreur lors de la suppression de la facture: $e');
      rethrow;
    }
  }

  /// Marquer une facture comme payée
  static Future<void> markInvoiceAsPaid(int invoiceId, {
    String? paymentMethod,
    String? paymentReference,
    DateTime? paymentDate,
  }) async {
    try {
      final updates = {
        'status': 'paid',
        'payment_date': (paymentDate ?? DateTime.now()).toIso8601String().split('T')[0],
      };

      if (paymentMethod != null) {
        updates['payment_method'] = paymentMethod;
      }
      if (paymentReference != null) {
        updates['payment_reference'] = paymentReference;
      }

      await updateInvoice(invoiceId, updates);
    } catch (e) {
      debugPrint('Erreur lors du marquage de la facture comme payée: $e');
      rethrow;
    }
  }

  // Méthode pour créer un nouvel utilisateur
  static Future<void> createUser({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
  }) async {
    try {
      // Créer l'utilisateur dans auth
      final AuthResponse response = await client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Erreur lors de la création de l\'utilisateur');
      }

      // Créer le profil de l'utilisateur
      await client.from('profiles').insert({
        'user_id': response.user!.id,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phone,
        'role': role.toString(),
        'status': 'actif',
      });

      // Envoyer un email de confirmation
      await client.auth.resetPasswordForEmail(
        email,
        redirectTo: defaultUrl,
      );

    } catch (e) {
      debugPrint('Erreur lors de la création de l\'utilisateur: $e');
      rethrow;
    }
  }

  // Méthodes pour la gestion des clients et projets

  /// Méthode de compatibilité pour getClientMapping - remplacée par l'approche entreprise
  static Future<Map<String, dynamic>?> getClientMapping(String userId) async {
    try {
      final userCompany = await getUserCompany();
      if (userCompany != null && userCompany['company_id'] != null) {
        return {
          'client_id': userCompany['company_id'].toString(),
          'user_id': userId,
        };
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du mapping client: $e');
      return null;
    }
  }

  /// Méthode de compatibilité pour getClientProjects - remplacée par l'approche entreprise
  static Future<List<Map<String, dynamic>>> getClientProjects(String clientId) async {
    return await getCompanyProjects();
  }

  /// Méthode de compatibilité pour getClientTasks - remplacée par l'approche entreprise
  static Future<List<Map<String, dynamic>>> getClientTasks(String clientId) async {
    return await getClientActiveTasks();
  }

  /// Méthode de compatibilité pour getClientById - remplacée par l'approche entreprise
  static Future<Map<String, dynamic>?> getClientById(String clientId) async {
    try {
      final userCompany = await getUserCompany();
      if (userCompany != null) {
        return {
          'id': userCompany['company_id'],
          'name': userCompany['company_name'],
          'email': userCompany['company_email'],
        };
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération du client par ID: $e');
      return null;
    }
  }

  // === GESTION DES ENTREPRISES ===

  /// Récupérer toutes les entreprises (pour admins/associés)
  static Future<List<Map<String, dynamic>>> getAllCompanies() async {
    try {
      final response = await client
          .from('companies')
          .select()
          .order('name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des entreprises: $e');
      return [];
    }
  }

  /// Récupérer l'entreprise de l'utilisateur connecté
  static Future<Map<String, dynamic>?> getUserCompany() async {
    try {
      final response = await client
          .from('user_company_info')
          .select()
          .eq('user_id', currentUser!.id)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Erreur lors de la récupération de l\'entreprise utilisateur: $e');
      return null;
    }
  }

  /// Créer une nouvelle entreprise
  static Future<Map<String, dynamic>?> createCompany({
    required String name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? website,
  }) async {
    try {
      final response = await client
          .from('companies')
          .insert({
            'name': name,
            'description': description,
            'address': address,
            'phone': phone,
            'email': email,
            'website': website,
            'status': 'active',
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Erreur lors de la création de l\'entreprise: $e');
      rethrow;
    }
  }

  /// Mettre à jour une entreprise
  static Future<void> updateCompany(int companyId, Map<String, dynamic> updates) async {
    try {
      await client
          .from('companies')
          .update(updates)
          .eq('id', companyId);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour de l\'entreprise: $e');
      rethrow;
    }
  }

  /// Assigner un utilisateur à une entreprise
  static Future<bool> assignUserToCompany(String userId, int companyId) async {
    try {
      final result = await client.rpc('assign_user_to_company', params: {
        'user_id_param': userId,
        'company_id_param': companyId,
      });
      
      return result as bool;
    } catch (e) {
      debugPrint('Erreur lors de l\'assignation à l\'entreprise: $e');
      rethrow;
    }
  }

  // === PROJETS FILTRÉS PAR ENTREPRISE ===

  /// Récupérer les projets de l'entreprise de l'utilisateur connecté
  static Future<List<Map<String, dynamic>>> getCompanyProjects() async {
    try {
      final response = await client
          .from('projects')
          .select('''
            *,
            companies:company_id(name, id),
            tasks:tasks(count)
          ''')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des projets de l\'entreprise: $e');
      return [];
    }
  }

  /// Créer un projet pour l'entreprise de l'utilisateur
  static Future<Map<String, dynamic>?> createProjectForCompany({
    required String name,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Récupérer l'entreprise de l'utilisateur
      final userCompany = await getUserCompany();
      if (userCompany == null || userCompany['company_id'] == null) {
        throw Exception('Utilisateur non assigné à une entreprise');
      }

      final response = await client
          .from('projects')
          .insert({
            'name': name,
            'description': description,
            'status': status ?? 'active',
            'start_date': startDate?.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
            'company_id': userCompany['company_id'],
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Erreur lors de la création du projet: $e');
      rethrow;
    }
  }

  // === TÂCHES FILTRÉES PAR ENTREPRISE ===

  /// Récupérer les tâches des projets de l'entreprise
  static Future<List<Map<String, dynamic>>> getCompanyTasks() async {
    try {
      final response = await client
          .from('tasks')
          .select('''
            *,
            projects:project_id(name, company_id),
            assigned_user:assigned_to(email),
            creator:created_by(email)
          ''')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des tâches de l\'entreprise: $e');
      return [];
    }
  }

  /// Créer une tâche dans un projet de l'entreprise
  static Future<Map<String, dynamic>?> createTaskForCompany({
    required String projectId,
    required String title,
    String? description,
    String? status,
    String? priority,
    DateTime? dueDate,
    String? assignedTo,
  }) async {
    try {
      final response = await client
          .from('tasks')
          .insert({
            'project_id': projectId,
            'title': title,
            'description': description,
            'status': status ?? 'todo',
            'priority': priority ?? 'medium',
            'due_date': dueDate?.toIso8601String(),
            'assigned_to': assignedTo,
            'created_by': currentUser!.id,
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Erreur lors de la création de la tâche: $e');
      rethrow;
    }
  }

  // === MÉTHODES SPÉCIFIQUES CLIENTS ===

  /// Récupérer les statistiques de l'entreprise du client
  static Future<Map<String, dynamic>> getClientCompanyStats() async {
    try {
      final userCompany = await getUserCompany();
      if (userCompany == null || userCompany['company_id'] == null) {
        return {
          'projects_count': 0,
          'tasks_count': 0,
          'completed_tasks_count': 0,
          'company_name': 'Aucune entreprise',
        };
      }

      final projects = await getCompanyProjects();
      final tasks = await getCompanyTasks();
      final completedTasks = tasks.where((task) => task['status'] == 'done').toList();

      return {
        'projects_count': projects.length,
        'tasks_count': tasks.length,
        'completed_tasks_count': completedTasks.length,
        'company_name': userCompany['company_name'] ?? 'Entreprise',
        'company_id': userCompany['company_id'],
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des statistiques: $e');
      return {
        'projects_count': 0,
        'tasks_count': 0,
        'completed_tasks_count': 0,
        'company_name': 'Erreur',
      };
    }
  }

  /// Récupérer les projets récents de l'entreprise du client (limité à 5)
  static Future<List<Map<String, dynamic>>> getClientRecentProjects() async {
    try {
      final projects = await getCompanyProjects();
      return projects.take(5).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des projets récents: $e');
      return [];
    }
  }

  /// Récupérer les tâches assignées au client ou en cours dans son entreprise
  static Future<List<Map<String, dynamic>>> getClientActiveTasks() async {
    try {
      final tasks = await getCompanyTasks();
      
      // Filtrer les tâches actives (non terminées)
      final activeTasks = tasks.where((task) => 
        task['status'] != 'done' && task['status'] != 'completed'
      ).toList();
      
      return activeTasks.take(10).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des tâches actives: $e');
      return [];
    }
  }
} 