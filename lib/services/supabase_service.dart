import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/user_role.dart';
import 'company_service.dart';
import 'notification_service.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static SupabaseClient get client => _client!;
  static UserRole? _currentUserRole;

  // Configuration injectée au build : flutter run/build --dart-define-from-file=.env
  // (ou --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...)
  static const _envUrl = String.fromEnvironment('SUPABASE_URL');
  static const _envAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static Future<bool> initialize() async {
    if (_client != null) return true;

    debugPrint('Initialisation de Supabase...');

    try {
      const url = _envUrl;
      const anonKey = _envAnonKey;

      if (url.isEmpty || anonKey.isEmpty) {
        throw StateError(
          'Configuration Supabase manquante. Lancer avec '
          '--dart-define-from-file=.env (le fichier .env doit définir '
          'SUPABASE_URL et SUPABASE_ANON_KEY).',
        );
      }

      debugPrint('Création du client Supabase avec URL: $url');

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: kDebugMode,
      );
      
      _client = Supabase.instance.client;
      
      // Écouter les changements d'authentification pour gérer les tokens expirés
      _client!.auth.onAuthStateChange.listen((AuthState state) {
        try {
          debugPrint('Auth state changed: ${state.event}');
          if (state.event == AuthChangeEvent.tokenRefreshed) {
            debugPrint('Token JWT rafraîchi automatiquement');
          } else if (state.event == AuthChangeEvent.signedOut) {
            debugPrint('Utilisateur déconnecté');
            _currentUserRole = null;
          }
        } catch (e) {
          // Gérer les erreurs JWT sans faire planter l'application
          debugPrint('⚠️ Erreur lors du traitement du changement d\'auth state: $e');
          if (e.toString().contains('InvalidJWTToken') || e.toString().contains('JWT')) {
            debugPrint('🔄 Erreur JWT détectée, tentative de récupération silencieuse...');
            // Ne pas faire planter l'app pour les erreurs JWT
          }
        }
      });
      
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

  static UserRole? get currentUserRole => _currentUserRole;

  static User? get currentUser => client.auth.currentUser;

  /// Délégation vers CompanyService (utilisé par les méthodes missions restantes).
  static Future<Map<String, dynamic>?> getUserCompany() =>
      CompanyService.getUserCompany();

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
        // Ne pas bloquer la connexion si la récupération du rôle échoue (ex: RLS)
        try {
          _currentUserRole = await getCurrentUserRole();
          debugPrint('Connexion réussie avec le rôle: $_currentUserRole');
        } catch (roleError) {
          debugPrint('⚠️ Récupération du rôle échouée après login: $roleError');
          // Laisser le rôle à null; l’UI pourra tenter une récupération plus tard
        }
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
      
      // Filtrer les partenaires - flexible pour 'role' ou 'user_role'
      final partners = List<Map<String, dynamic>>.from(
        response.where((user) {
          final userRole = user['user_role'] ?? user['role']; // Support des deux formats
          debugPrint('getPartners: Utilisateur ${user['email']} a le rôle: $userRole');
          return userRole == 'partenaire';
        })
      );

      debugPrint('getPartners: ${partners.length} partenaires trouvés');

      // Adapter les champs pour la compatibilité avec l'interface
      final adaptedPartners = partners.map((partner) {
        final role = partner['user_role'] ?? partner['role']; // Support des deux formats
        return {
          'user_id': partner['user_id'],
          'user_email': partner['email'], // Mapper 'email' vers 'user_email'
          'email': partner['email'],
          'first_name': partner['first_name'],
          'last_name': partner['last_name'],
          'phone': partner['phone'],
          'role': role,
          'status': partner['status'],
          'created_at': partner['created_at'],
          'updated_at': partner['updated_at'],
        };
      }).toList();

      debugPrint('getPartners: Partenaires adaptés: $adaptedPartners');
      return adaptedPartners;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des partenaires: $e');
      return [];
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

  // Méthode pour créer un nouvel utilisateur
  /// Crée un utilisateur via l'Edge Function `admin-create-user`.
  ///
  /// La création se fait exclusivement côté serveur (service_role) : le
  /// serveur vérifie que l'appelant est admin/associé, crée le compte auth
  /// et le profil, puis envoie un email de définition du mot de passe.
  /// Le mot de passe n'est plus choisi ni transmis par l'admin.
  static Future<void> createUser({
    required String email,
    required String firstName,
    required String lastName,
    required String phone,
    required UserRole role,
    int? companyId,
  }) async {
    try {
      final response = await client.functions.invoke(
        'admin-create-user',
        body: {
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
          'role': role.toString(),
          if (companyId != null) 'company_id': companyId,
        },
      );

      if (response.status != 200) {
        final message = (response.data is Map && response.data['error'] != null)
            ? response.data['error']
            : 'Erreur serveur (${response.status})';
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('Erreur lors de la création de l\'utilisateur: $e');
      rethrow;
    }
  }

  // Méthodes pour la gestion des clients et missions

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
    return await getCompanyMissions();
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


  // === MISSIONS FILTRÉES PAR RÔLE ===

  /// Récupérer les missions selon le rôle de l'utilisateur
  static Future<List<Map<String, dynamic>>> getCompanyMissions() async {
    try {
      debugPrint('getCompanyMissions() appelée');
      final userRole = await getCurrentUserRole();
      final userId = currentUser?.id;
      debugPrint('Rôle utilisateur: $userRole, ID: $userId');
      
      // Admin/Associé : voir toutes les missions
      if (userRole == UserRole.admin || userRole == UserRole.associe) {
        final response = await client
            .from('missions')
            .select('*')
            .order('created_at', ascending: false);
        
        debugPrint('Admin/Associé: ${response.length} missions récupérées');
        return List<Map<String, dynamic>>.from(response);
      }
      
      // Partenaire : voir uniquement les missions assignées
      if (userRole == UserRole.partenaire && userId != null) {
        return await getPartnerMissions(userId);
      }
      
      // Client : voir les missions de son entreprise
      if (userRole == UserRole.client) {
        final userCompany = await getUserCompany();
        if (userCompany == null || userCompany['company_id'] == null) {
          debugPrint('Client: Aucune entreprise trouvée');
          return [];
        }

        final response = await client
            .from('missions')
            .select('*')
            .eq('company_id', userCompany['company_id'])
            .order('created_at', ascending: false);
        
        debugPrint('Client: ${response.length} missions récupérées');
        return List<Map<String, dynamic>>.from(response);
      }
      
      return [];
    } catch (e) {
      debugPrint('Erreur getCompanyMissions: $e');
      return [];
    }
  }

  /// Récupérer les missions assignées à un partenaire
  static Future<List<Map<String, dynamic>>> getPartnerMissions(String partnerId) async {
    try {
      debugPrint('🔍 getPartnerMissions() pour $partnerId');
      
      // Méthode 1: Chercher par assigned_to
      var response = await client
          .from('missions')
          .select('*')
          .eq('assigned_to', partnerId)
          .order('created_at', ascending: false);
      
      if (response.isNotEmpty) {
        debugPrint('✅ ${response.length} missions trouvées par assigned_to');
        return List<Map<String, dynamic>>.from(response);
      }
      
      // Méthode 2: Chercher par partner_id
      response = await client
          .from('missions')
          .select('*')
          .eq('partner_id', partnerId)
          .order('created_at', ascending: false);
      
      if (response.isNotEmpty) {
        debugPrint('✅ ${response.length} missions trouvées par partner_id');
        return List<Map<String, dynamic>>.from(response);
      }
      
      // Méthode 3: Chercher avec OR (nécessite RPC ou requête combinée)
      // Essayer avec filtrage côté client
      final allMissions = await client
          .from('missions')
          .select('*')
          .order('created_at', ascending: false);
      
      final partnerMissions = (allMissions as List).where((m) {
        final assignedTo = m['assigned_to']?.toString();
        final missionPartnerId = m['partner_id']?.toString();
        return assignedTo == partnerId || missionPartnerId == partnerId;
      }).toList();
      
      debugPrint('📊 Partenaire: ${partnerMissions.length} missions trouvées (filtrage côté client)');
      return List<Map<String, dynamic>>.from(partnerMissions);
    } catch (e) {
      debugPrint('❌ Erreur getPartnerMissions: $e');
      return [];
    }
  }

  /// Récupérer les clients de l'entreprise (pour sélection lors de création mission)
  static Future<List<Map<String, dynamic>>> getCompanyClients() async {
    try {
      final response = await client.rpc('get_company_clients');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des clients: $e');
      return [];
    }
  }

  /// Créer une mission avec client spécifié (pour les associés)
  static Future<String?> createProjectWithClient({
    required String name,
    String? description,
    required String clientId,
    double? estimatedDays,
    double? dailyRate,
    DateTime? endDate,
  }) async {
    try {
      final response = await client.rpc('create_project_with_client', params: {
        'p_name': name,
        'p_client_id': clientId,
        'p_description': description,
        'p_estimated_days': estimatedDays,
        'p_daily_rate': dailyRate,
        'p_end_date': endDate?.toIso8601String().split('T')[0], // Format DATE
      });

      return response.toString(); // ID de la nouvelle mission
    } catch (e) {
      debugPrint('Erreur lors de la création de la mission avec client: $e');
      return null;
    }
  }

  /// Associer un client à une mission existante
  static Future<bool> assignClientToProject({
    required String projectId,
    required String clientId,
  }) async {
    try {
      final response = await client.rpc('assign_client_to_mission', params: {
        'p_mission_id': projectId,
        'p_client_id': clientId,
      });

      return response == true;
    } catch (e) {
      debugPrint('Erreur lors de l\'assignation du client à la mission: $e');
      return false;
    }
  }

  // === TÂCHES FILTRÉES PAR ENTREPRISE ===



  // === MÉTHODES SPÉCIFIQUES CLIENTS ===

  /// Récupérer les statistiques de l'entreprise du client
  static Future<Map<String, dynamic>> getClientCompanyStats() async {
    try {
      final userCompany = await getUserCompany();
      if (userCompany == null || userCompany['company_id'] == null) {
      return {
        'missions_count': 0,
        'company_name': 'Aucune entreprise',
      };
      }

      final missions = await getCompanyMissions();

      return {
        'missions_count': missions.length,
        'company_name': userCompany['company_name'] ?? 'Entreprise',
        'company_id': userCompany['company_id'],
      };
    } catch (e) {
      debugPrint('Erreur lors de la récupération des statistiques: $e');
      return {
        'missions_count': 0,
        'company_name': 'Erreur',
      };
    }
  }

  /// Récupérer les missions récentes de l'entreprise du client (limité à 5)
  static Future<List<Map<String, dynamic>>> getClientRecentMissions() async {
    try {
      final missions = await getCompanyMissions();
      return missions.take(5).toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des missions récentes: $e');
      return [];
    }
  }
  // =============================================
  // SYSTÈME D'ASSIGNATION DE MISSIONS
  // =============================================

  /// Assigner une mission à un partenaire
  static Future<Map<String, dynamic>?> assignMission({
    required String projectId,
    required String taskId,
    required String partnerId,
    required String message,
    String priority = 'medium',
    DateTime? deadline,
  }) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await client.from('mission_assignments').insert({
        'mission_id': projectId,
        'task_id': taskId,
        'assigned_to': partnerId,
        'assigned_by': currentUser.id,
        'message': message,
        'priority': priority,
        'deadline': deadline?.toIso8601String(),
        'status': 'pending',
      }).select().single();

      // Créer une notification pour le partenaire
      await NotificationService.createUserNotification(
        userId: partnerId,
        title: 'Nouvelle mission assignée',
        message: message,
        type: 'mission_assignment',
        missionAssignmentId: response['id'],
      );

      debugPrint('✅ Mission assignée avec succès: ${response['id']}');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'assignation de mission: $e');
      return null;
    }
  }

  /// Accepter une mission
  static Future<bool> acceptMission(String missionId, {String? responseMessage}) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return false;

      await client.from('mission_assignments').update({
        'status': 'accepted',
        'accepted_at': DateTime.now().toIso8601String(),
        'partner_response': responseMessage,
      }).eq('id', missionId).eq('assigned_to', currentUser.id);

      // Notifier l'associé qui a assigné la mission
      final mission = await getMissionAssignment(missionId);
      if (mission != null) {
        await NotificationService.createUserNotification(
          userId: mission['assigned_by'],
          title: 'Mission acceptée',
          message: 'Votre mission a été acceptée par le partenaire.',
          type: 'mission_update',
          missionAssignmentId: missionId,
        );
      }

      debugPrint('✅ Mission acceptée: $missionId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'acceptation de mission: $e');
      return false;
    }
  }

  /// Refuser une mission
  static Future<bool> rejectMission(String missionId, {String? responseMessage}) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return false;

      await client.from('mission_assignments').update({
        'status': 'rejected',
        'rejected_at': DateTime.now().toIso8601String(),
        'partner_response': responseMessage,
      }).eq('id', missionId).eq('assigned_to', currentUser.id);

      // Notifier l'associé qui a assigné la mission
      final mission = await getMissionAssignment(missionId);
      if (mission != null) {
        await NotificationService.createUserNotification(
          userId: mission['assigned_by'],
          title: 'Mission refusée',
          message: 'Votre mission a été refusée par le partenaire.',
          type: 'mission_update',
          missionAssignmentId: missionId,
        );
      }

      debugPrint('✅ Mission refusée: $missionId');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors du refus de mission: $e');
      return false;
    }
  }

  /// Obtenir les missions assignées à l'utilisateur connecté
  static Future<List<Map<String, dynamic>>> getMyMissions() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return [];

      final response = await client
          .from('mission_assignments_with_details')
          .select('*')
          .eq('assigned_to', currentUser.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des missions: $e');
      return [];
    }
  }

  /// Obtenir toutes les missions assignées (pour les associés/admins)
  static Future<List<Map<String, dynamic>>> getAllMissionAssignments() async {
    try {
      final response = await client
          .from('mission_assignments_with_details')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de toutes les missions: $e');
      return [];
    }
  }

  /// Obtenir une mission spécifique
  static Future<Map<String, dynamic>?> getMissionAssignment(String missionId) async {
    try {
      final response = await client
          .from('mission_assignments_with_details')
          .select('*')
          .eq('id', missionId)
          .single();

      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de la mission: $e');
      return null;
    }
  }

  /// Notifier tous les partenaires d'une nouvelle mission disponible
  static Future<bool> notifyAllPartnersMissionAvailable({
    required String projectId,
    required String title,
    required String message,
  }) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return false;

      // Appeler la fonction SQL qui notifie tous les partenaires
      final response = await client.rpc('notify_all_partners_mission_available', params: {
        'p_mission_id': projectId,
        'p_title': title,
        'p_message': message,
        'p_sent_by': currentUser.id,
      });

      debugPrint('✅ Notification envoyée à tous les partenaires: $response');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi de notification: $e');
      return false;
    }
  }





  // =============================================
  // GESTION DES CLIENTS
  // =============================================

  /// Créer un nouveau client
  static Future<Map<String, dynamic>?> createClient({
    required String name,
    required String email,
    String? phone,
    String? company,
    String? address,
    String? notes,
  }) async {
    try {
      debugPrint('🔍 [createClient] Début de la création du client');
      debugPrint('📝 [createClient] Nom: $name, Email: $email');
      
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [createClient] Utilisateur non connecté');
        throw Exception('Utilisateur non connecté');
      }
      debugPrint('👤 [createClient] Utilisateur connecté: ${currentUser.id}');

      // Vérifier que l'utilisateur a le droit de créer des clients
      final userRole = await getCurrentUserRole();
      debugPrint('🔑 [createClient] Rôle utilisateur: ${userRole?.value}');
      
      if (userRole?.value != 'admin' && userRole?.value != 'associe') {
        debugPrint('❌ [createClient] Droits insuffisants: ${userRole?.value}');
        throw Exception('Vous n\'avez pas les droits pour créer un client');
      }

      final clientData = {
        'name': name,
        'email': email,
        'phone': phone,
        'company': company,
        'address': address,
        'notes': notes,
        'created_by': currentUser.id,
        'status': 'active',
      };
      
      debugPrint('📊 [createClient] Données à insérer: $clientData');

      final response = await client.from('clients').insert(clientData).select().single();

      debugPrint('✅ [createClient] Client créé avec succès: ${response['id']}');
      return response;
    } catch (e) {
      debugPrint('❌ [createClient] Erreur lors de la création du client: $e');
      debugPrint('❌ [createClient] Type d\'erreur: ${e.runtimeType}');
      return null;
    }
  }


  /// Obtenir les détails d'un client spécifique
  static Future<Map<String, dynamic>?> getClientDetails(String clientId) async {
    try {
      final response = await client
          .from('clients')
          .select('*')
          .eq('id', clientId)
          .eq('status', 'active')
          .single();

      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des détails du client: $e');
      return null;
    }
  }




  // Méthodes pour les missions
  static Future<bool> createMission(Map<String, dynamic> missionData) async {
    try {
      debugPrint('🔍 Création d\'une nouvelle mission...');
      debugPrint('📊 Données mission: $missionData');
      
      // S'assurer que le statut par défaut est défini
      if (!missionData.containsKey('status')) {
        missionData['status'] = 'à_faire';
      }
      
      await client
          .from('missions')
          .insert(missionData);
      
      debugPrint('✅ Mission créée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de la mission: $e');
      return false;
    }
  }

  // Méthode pour mettre à jour le statut d'une mission (acceptation/refus)
  static Future<bool> updateMissionStatus(String missionId, String status) async {
    try {
      debugPrint('🔍 Mise à jour du statut de la mission $missionId vers $status');
      
      await client
          .from('missions')
          .update({'status': status})
          .eq('id', missionId);
      
      debugPrint('✅ Statut de la mission mis à jour avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du statut: $e');
      return false;
    }
  }

  // Méthode pour mettre à jour le statut d'avancement d'une mission
  static Future<bool> updateMissionProgressStatus(String missionId, String progressStatus) async {
    try {
      debugPrint('🔍 Mise à jour du statut d\'avancement de la mission $missionId vers $progressStatus');
      
      await client
          .from('missions')
          .update({'progress_status': progressStatus})
          .eq('id', missionId);
      
      debugPrint('✅ Statut d\'avancement de la mission mis à jour avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du statut d\'avancement: $e');
      return false;
    }
  }

  // Méthode pour récupérer les missions avec leurs statuts
  static Future<List<Map<String, dynamic>>> getMissionsWithStatus() async {
    try {
      debugPrint('🔍 Récupération des missions avec statuts...');
      debugPrint('👤 Utilisateur actuel: ${currentUser?.id}');
      debugPrint('🎭 Rôle actuel: $currentUserRole');
      
      // Vérifier d'abord si la table existe et contient des données
      debugPrint('📊 Test de connexion à la table missions...');
      
      final response = await client
          .from('missions')
          .select('*')
          .order('created_at', ascending: false);
      
      debugPrint('✅ ${response.length} missions récupérées');
      
      if (response.isEmpty) {
        debugPrint('⚠️ ATTENTION: Aucune mission récupérée!');
        debugPrint('🔍 Causes possibles:');
        debugPrint('   1. Aucune mission dans la table');
        debugPrint('   2. Politiques RLS bloquent l\'accès');
        debugPrint('   3. company_id ne correspond pas');
        
        // Essayer de récupérer le company_id de l'utilisateur
        try {
          final userRoleResponse = await client
              .from('user_roles')
              .select('company_id, role')
              .eq('user_id', currentUser!.id)
              .maybeSingle();
          
          if (userRoleResponse != null) {
            debugPrint('🏢 Company ID de l\'utilisateur: ${userRoleResponse['company_id']}');
            debugPrint('🎭 Rôle de l\'utilisateur: ${userRoleResponse['role']}');
          } else {
            debugPrint('❌ Aucun rôle trouvé pour cet utilisateur!');
          }
        } catch (e) {
          debugPrint('❌ Erreur lors de la récupération du rôle: $e');
        }
      }
      
      return response;
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur lors de la récupération des missions: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  // Méthode pour récupérer les missions proposées à un partenaire
  static Future<List<Map<String, dynamic>>> getProposedMissionsForPartner(String partnerId) async {
    try {
      debugPrint('🔍 Récupération des missions proposées au partenaire $partnerId...');
      
      final response = await client
          .from('missions')
          .select('*')
          .eq('partner_id', partnerId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);
      
      debugPrint('✅ ${response.length} missions proposées récupérées');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des missions proposées: $e');
      return [];
    }
  }





  // Récupérer les titres des missions existantes pour l'autocomplétion
  static Future<List<String>> getExistingMissions() async {
    try {
      debugPrint('🔍 Récupération des missions existantes...');
      
      final response = await client
          .from('missions')
          .select('title')
          .order('title');
      
      final missions = response.map((mission) => mission['title'] as String).toList();
      debugPrint('📊 ${missions.length} missions trouvées');
      
      return missions;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des missions: $e');
      return [];
    }
  }

  // Récupérer les missions existantes avec tous les détails pour l'autocomplétion
  static Future<List<Map<String, dynamic>>> getExistingMissionsWithDetails() async {
    try {
      debugPrint('🔍 Récupération des missions existantes avec détails...');
      
      final response = await client
          .from('missions')
          .select('*')
          .order('title');
      
      debugPrint('📊 ${response.length} missions trouvées avec détails');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des missions: $e');
      return [];
    }
  }

  // Créer une proposition de mission
  static Future<bool> createMissionProposal(Map<String, dynamic> proposalData) async {
    try {
      debugPrint('🔍 Création d\'une proposition de mission...');
      debugPrint('📊 Données proposition: $proposalData');

      await client
          .from('mission_proposals')
          .insert(proposalData);

      debugPrint('✅ Proposition de mission créée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de la proposition: $e');
      return false;
    }
  }
} 