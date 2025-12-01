import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/user_role.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static SupabaseClient get client => _client!;
  static UserRole? _currentUserRole;

  // URL et clé par défaut - CREDENTIALS CONFIRMÉS
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
      debugPrint('🔍 URL utilisée: $url');
      debugPrint('🔍 Clé utilisée: ${anonKey.substring(0, 20)}...');
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: true, // Forcer le mode debug même en production pour diagnostiquer le problème
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
        invoiceData['mission_id'] = projectId;
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

  // === GESTION DES ENTREPRISES ===

  /// Récupérer toutes les entreprises (pour admins/associés)
  static Future<List<Map<String, dynamic>>> getAllCompanies() async {
    try {
      // Essayer d'abord 'company' (singulier), puis 'companies' (pluriel) en fallback
      try {
        final response = await client
            .from('company')
            .select('id, name')
            .order('name', ascending: true);
        
        final companies = List<Map<String, dynamic>>.from(response);
        debugPrint('✅ ${companies.length} companies récupérées depuis la table "company"');
        return companies;
      } catch (e) {
        debugPrint('⚠️ Table "company" non trouvée, tentative avec "companies"...');
      final response = await client
          .from('companies')
            .select('id, name')
          .order('name', ascending: true);
      
        final companies = List<Map<String, dynamic>>.from(response);
        debugPrint('✅ ${companies.length} companies récupérées depuis la table "companies"');
        return companies;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des entreprises: $e');
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

  /// Créer une mission pour l'entreprise de l'utilisateur (DÉPRÉCIÉ - Utiliser createProjectWithClient)
  @Deprecated('Utilisez createProjectWithClient pour spécifier un client spécifique')
  static Future<Map<String, dynamic>?> createProjectForCompany({
    required String name,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    debugPrint('⚠️ ATTENTION: createProjectForCompany est déprécié. Utilisez createProjectWithClient pour spécifier un client.');
    
    try {
      // Récupérer l'entreprise de l'utilisateur
      final userCompany = await getUserCompany();
      if (userCompany == null || userCompany['company_id'] == null) {
        throw Exception('Utilisateur non assigné à une entreprise');
      }

      final response = await client
          .from('missions')
          .insert({
            'title': name,
            'description': description,
            'status': status ?? 'active',
            'start_date': startDate?.toIso8601String(),
            'end_date': endDate?.toIso8601String(),
            'company_id': userCompany['company_id'],
            // NOTE: client_id sera NULL - Il faudra l'assigner plus tard
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      debugPrint('Erreur lors de la création de la mission: $e');
      rethrow;
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


  // ==== MÉTHODES POUR LA GESTION DES DEMANDES CLIENT ====

  /// Récupérer toutes les propositions de projets (pour les associés)
  static Future<List<Map<String, dynamic>>> getProjectProposals() async {
    try {
      final response = await _client!
          .from('project_proposals')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des propositions: $e');
      return [];
    }
  }

  /// Récupérer les propositions en attente uniquement
  static Future<List<Map<String, dynamic>>> getPendingProjectProposals() async {
    try {
      final response = await _client!
          .from('project_proposals')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des propositions en attente: $e');
      return [];
    }
  }

  /// Récupérer toutes les demandes d'extension de temps
  static Future<List<Map<String, dynamic>>> getTimeExtensionRequests() async {
    try {
      final response = await _client!
          .from('time_extension_requests')
          .select('*')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes d\'extension: $e');
      return [];
    }
  }

  /// Récupérer les demandes d'extension en attente uniquement
  static Future<List<Map<String, dynamic>>> getPendingTimeExtensionRequests() async {
    try {
      final response = await _client!
          .from('time_extension_requests')
          .select('*')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur lors de la récupération des demandes d\'extension en attente: $e');
      return [];
    }
  }

  /// Approuver une proposition de projet (crée automatiquement le projet)
  static Future<String?> approveProjectProposal({
    required String proposalId,
    String? responseMessage,
  }) async {
    try {
      final response = await _client!.rpc('approve_project_proposal', params: {
        'p_proposal_id': proposalId,
        'p_response_message': responseMessage,
      });

      return response.toString(); // ID de la nouvelle mission créé
    } catch (e) {
      debugPrint('Erreur lors de l\'approbation de la proposition: $e');
      return null;
    }
  }

  /// Rejeter une proposition de projet
  static Future<bool> rejectProjectProposal({
    required String proposalId,
    String? responseMessage,
  }) async {
    try {
      final updates = {
        'status': 'rejected',
        'reviewed_by': currentUser?.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (responseMessage != null && responseMessage.isNotEmpty) {
        updates['response_message'] = responseMessage;
      }

      await _client!
          .from('project_proposals')
          .update(updates)
          .eq('id', proposalId);

      return true;
    } catch (e) {
      debugPrint('Erreur lors du rejet de la proposition: $e');
      return false;
    }
  }

  /// Approuver une demande d'extension de temps (met à jour automatiquement le projet)
  static Future<bool> approveTimeExtensionRequest({
    required String requestId,
    String? responseMessage,
  }) async {
    try {
      final response = await _client!.rpc('approve_time_extension', params: {
        'p_request_id': requestId,
        'p_response_message': responseMessage,
      });

      return response == true;
    } catch (e) {
      debugPrint('Erreur lors de l\'approbation de l\'extension: $e');
      return false;
    }
  }

  /// Rejeter une demande d'extension de temps
  static Future<bool> rejectTimeExtensionRequest({
    required String requestId,
    String? responseMessage,
  }) async {
    try {
      final updates = {
        'status': 'rejected',
        'approved_by': currentUser?.id,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (responseMessage != null && responseMessage.isNotEmpty) {
        updates['response_message'] = responseMessage;
      }

      await _client!
          .from('time_extension_requests')
          .update(updates)
          .eq('id', requestId);

      return true;
    } catch (e) {
      debugPrint('Erreur lors du rejet de la demande d\'extension: $e');
      return false;
    }
  }

  /// Soumettre une nouvelle proposition de projet (pour les clients)
  static Future<String?> submitProjectProposal({
    required String title,
    required String description,
    double? estimatedBudget,
    double? estimatedDays,
    DateTime? endDate,
    List<Map<String, dynamic>>? documents,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer la company_id de l'utilisateur
      final userProfile = await _client!
          .from('profiles')
          .select('company_id')
          .eq('user_id', currentUser!.id)
          .single();

      final proposalData = {
        'title': title,
        'description': description,
        'estimated_budget': estimatedBudget,
        'estimated_days': estimatedDays,
        'end_date': endDate?.toIso8601String().split('T')[0], // Format DATE
        'client_id': currentUser!.id,
        'company_id': userProfile['company_id'],
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      final proposalResponse = await _client!
          .from('project_proposals')
          .insert(proposalData)
          .select()
          .single();

      final proposalId = proposalResponse['id'];

      // Sauvegarder les documents s'il y en a
      debugPrint('💾 Sauvegarde documents en base - Proposal ID: $proposalId');
      if (documents != null && documents.isNotEmpty) {
        debugPrint('📋 ${documents.length} documents à sauvegarder en base');
        for (int i = 0; i < documents.length; i++) {
          final doc = documents[i];
          debugPrint('💾 Sauvegarde document ${i+1}/${documents.length}: ${doc['file_name']}');
          
          try {
            final docData = {
              'proposal_id': proposalId,
              'file_name': doc['file_name'],
              'file_path': doc['file_path'],
              'file_size': doc['file_size'],
              'mime_type': doc['mime_type'],
              'uploaded_at': DateTime.now().toIso8601String(),
            };
            
            debugPrint('📄 Données document: $docData');
            
            await _client!.from('project_proposal_documents').insert(docData);
            debugPrint('✅ Document sauvegardé en base avec succès');
          } catch (docError) {
            debugPrint('❌ Erreur sauvegarde document ${doc['file_name']}: $docError');
          }
        }
        debugPrint('🎉 Tous les documents traités pour la proposition $proposalId');
      } else {
        debugPrint('ℹ️ Aucun document à sauvegarder (documents: $documents)');
      }

      return proposalId;
    } catch (e) {
      debugPrint('Erreur lors de la soumission de la proposition: $e');
      return null;
    }
  }

  /// Soumettre une demande d'extension de temps (pour les clients)
  static Future<bool> submitTimeExtensionRequest({
    required String projectId,
    required double daysRequested,
    required String reason,
  }) async {
    try {
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final extensionData = {
        'mission_id': projectId,
        'client_id': currentUser!.id,
        'days_requested': daysRequested,
        'reason': reason,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client!.from('time_extension_requests').insert(extensionData);
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la soumission de la demande d\'extension: $e');
      return false;
    }
  }

  /// Upload des documents vers Supabase Storage
  static Future<List<Map<String, dynamic>>> uploadDocuments(List<PlatformFile> files) async {
    List<Map<String, dynamic>> uploadedFiles = [];
    
    try {
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      debugPrint('🔄 Début upload de ${files.length} fichier(s)...');

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        debugPrint('📁 Upload fichier ${i+1}/${files.length}: ${file.name}');
        
        try {
          if (file.bytes != null) {
            // Web: utiliser les bytes
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final filePath = 'project_documents/${currentUser!.id}/$fileName';
            
            debugPrint('🌐 Upload web - Chemin: $filePath');
            
            final response = await _client!.storage
                .from('documents')
                .uploadBinary(filePath, file.bytes!);

            debugPrint('✅ Upload réussi - Réponse: $response');

            uploadedFiles.add({
              'file_name': file.name,
              'file_path': filePath,
              'file_size': file.size,
              'mime_type': _getMimeType(file.name),
            });
            
          } else if (file.path != null) {
            // Mobile/Desktop: utiliser le path
            final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
            final filePath = 'project_documents/${currentUser!.id}/$fileName';
            
            debugPrint('📱 Upload mobile/desktop - Chemin: $filePath');
            
            final fileBytes = await File(file.path!).readAsBytes();
            debugPrint('📝 Fichier lu: ${fileBytes.length} bytes');
            
            final response = await _client!.storage
                .from('documents')
                .uploadBinary(filePath, fileBytes);

            debugPrint('✅ Upload réussi - Réponse: $response');

            uploadedFiles.add({
              'file_name': file.name,
              'file_path': filePath,
              'file_size': file.size,
              'mime_type': _getMimeType(file.name),
            });
          } else {
            debugPrint('❌ Fichier ${file.name} sans bytes ni path');
          }
        } catch (fileError) {
          debugPrint('❌ Erreur upload fichier ${file.name}: $fileError');
          // Continue avec les autres fichiers
        }
      }
      
      debugPrint('🎉 Upload terminé: ${uploadedFiles.length}/${files.length} fichiers uploadés');
      return uploadedFiles;
    } catch (e) {
      debugPrint('💥 Erreur générale lors de l\'upload des documents: $e');
      return [];
    }
  }

  /// Obtenir le type MIME basé sur l'extension du fichier
  static String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'txt':
        return 'text/plain';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        return 'application/octet-stream';
    }
  }

  /// Récupérer les documents d'une proposition (pour les associés)
  static Future<List<Map<String, dynamic>>> getProposalDocuments(String proposalId) async {
    try {
      debugPrint('📋 Récupération documents pour proposition: $proposalId');
      
      final response = await _client!
          .from('project_proposal_documents')
          .select('*')
          .eq('proposal_id', proposalId)
          .order('uploaded_at', ascending: false);

      debugPrint('📄 ${response.length} document(s) trouvé(s)');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur récupération documents: $e');
      return [];
    }
  }

  /// Télécharger l'URL publique d'un document
  static String getDocumentUrl(String filePath) {
    return _client!.storage.from('documents').getPublicUrl(filePath);
  }

  /// Télécharger un document depuis le storage
  static Future<Uint8List?> downloadDocument(String filePath) async {
    try {
      debugPrint('⬇️ Téléchargement document: $filePath');
      
      final response = await _client!.storage
          .from('documents')
          .download(filePath);

      debugPrint('✅ Document téléchargé: ${response.length} bytes');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur téléchargement document: $e');
      return null;
    }
  }

  // ==========================================
  // GESTION DES ACTIONS COMMERCIALES
  // ==========================================

  /// Récupérer toutes les actions commerciales pour l'entreprise de l'utilisateur connecté
  static Future<List<Map<String, dynamic>>> getCommercialActions() async {
    try {
      debugPrint('🏢 Récupération des actions commerciales...');
      final userId = currentUser?.id;
      debugPrint('👤 User ID: $userId');
      
      // Essayer d'abord avec la fonction RPC
      try {
        final response = await client.rpc('get_commercial_actions_for_company');
        final actions = List<Map<String, dynamic>>.from(response);
        debugPrint('🏢 ${actions.length} actions commerciales récupérées via RPC');
        
        if (actions.isNotEmpty) {
          return actions;
        }
      } catch (rpcError) {
        debugPrint('⚠️ Erreur RPC, fallback sur requête directe: $rpcError');
      }
      
      // Fallback 1 : récupérer par company_id si disponible
      debugPrint('🔄 Fallback 1: récupération par company_id...');
      final userCompany = await getUserCompany();
      if (userCompany != null && userCompany['company_id'] != null) {
        final companyId = userCompany['company_id'];
        debugPrint('🏢 Company ID: $companyId');
        
        try {
          final response = await client
              .from('commercial_actions')
              .select('*')
              .eq('company_id', companyId)
              .order('created_at', ascending: false);
          
          final actions = List<Map<String, dynamic>>.from(response);
          debugPrint('🏢 ${actions.length} actions commerciales récupérées par company_id');
          
          if (actions.isNotEmpty) {
            return _transformActions(actions);
          }
        } catch (e) {
          debugPrint('⚠️ Erreur lors de la récupération par company_id: $e');
        }
      }
      
      // Fallback 2 : récupérer les actions créées par l'utilisateur
      if (userId != null) {
        debugPrint('🔄 Fallback 2: récupération par created_by...');
        try {
          final response = await client
              .from('commercial_actions')
              .select('*')
              .eq('created_by', userId)
              .order('created_at', ascending: false);
          
          final actions = List<Map<String, dynamic>>.from(response);
          debugPrint('🏢 ${actions.length} actions commerciales récupérées par created_by');
          
          if (actions.isNotEmpty) {
            return _transformActions(actions);
          }
        } catch (e) {
          debugPrint('⚠️ Erreur lors de la récupération par created_by: $e');
        }
      }
      
      // Fallback 3 : récupérer les actions assignées à l'utilisateur
      if (userId != null) {
        debugPrint('🔄 Fallback 3: récupération par assigned_to...');
        try {
          final response = await client
              .from('commercial_actions')
              .select('*')
              .eq('assigned_to', userId)
              .order('created_at', ascending: false);
          
          final actions = List<Map<String, dynamic>>.from(response);
          debugPrint('🏢 ${actions.length} actions commerciales récupérées par assigned_to');
          
          if (actions.isNotEmpty) {
            return _transformActions(actions);
          }
        } catch (e) {
          debugPrint('⚠️ Erreur lors de la récupération par assigned_to: $e');
        }
      }
      
      // Fallback 4 : récupérer les actions où l'utilisateur est partenaire
      if (userId != null) {
        debugPrint('🔄 Fallback 4: récupération par partner_id...');
        try {
          final response = await client
              .from('commercial_actions')
              .select('*')
              .eq('partner_id', userId)
              .order('created_at', ascending: false);
          
          final actions = List<Map<String, dynamic>>.from(response);
          debugPrint('🏢 ${actions.length} actions commerciales récupérées par partner_id');
          
          if (actions.isNotEmpty) {
            return _transformActions(actions);
          }
        } catch (e) {
          debugPrint('⚠️ Erreur lors de la récupération par partner_id: $e');
        }
      }
      
      debugPrint('❌ Aucune action commerciale trouvée avec aucun des fallbacks');
      return [];
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des actions commerciales: $e');
      return [];
    }
  }
  
  /// Transformer les actions pour correspondre au format attendu
  static List<Map<String, dynamic>> _transformActions(List<Map<String, dynamic>> actions) {
    return actions.map((action) {
      return {
        'id': action['id'],
        'title': action['title'],
        'description': action['description'],
        'type': action['type'],
        'status': action['status'],
        'priority': action['priority'],
        'client_name': action['client_name'] ?? '',
        'contact_person': action['contact_person'],
        'contact_email': action['contact_email'],
        'contact_phone': action['contact_phone'],
        'estimated_value': action['estimated_value'],
        'actual_value': action['actual_value'],
        'due_date': action['due_date'],
        'completed_date': action['completed_date'],
        'created_at': action['created_at'],
        'updated_at': action['updated_at'],
        'assigned_to_email': null,
        'assigned_to_name': null,
        'partner_email': null,
        'partner_name': null,
        'notes': action['notes'],
      };
    }).toList();
  }

  /// Créer une nouvelle action commerciale
  static Future<Map<String, dynamic>?> createCommercialAction({
    required String title,
    required String description,
    required String type,
    required String clientName,
    required String priority,
    String? contactPerson,
    String? contactEmail,
    String? contactPhone,
    double? estimatedValue,
    DateTime? dueDate,
    String? assignedTo,
    String? partnerId,
    String? notes,
  }) async {
    try {
      debugPrint('🏢 Création d\'une action commerciale: $title');
      
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer l'entreprise de l'utilisateur
      final userProfile = await client
          .from('profiles')
          .select('company_id')
          .eq('user_id', currentUser.id)
          .single();

      final actionData = {
        'title': title,
        'description': description,
        'type': type,
        'status': 'planned',
        'priority': priority,
        'client_name': clientName,
        'contact_person': contactPerson,
        'contact_email': contactEmail,
        'contact_phone': contactPhone,
        'estimated_value': estimatedValue,
        'due_date': dueDate?.toIso8601String(),
        'assigned_to': assignedTo,
        'partner_id': partnerId,
        'company_id': userProfile['company_id'],
        'created_by': currentUser.id,
        'notes': notes,
      };

      // Supprimer les valeurs nulles
      actionData.removeWhere((key, value) => value == null);

      final response = await client
          .from('commercial_actions')
          .insert(actionData)
          .select()
          .single();

      debugPrint('✅ Action commerciale créée avec l\'ID: ${response['id']}');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de l\'action commerciale: $e');
      return null;
    }
  }

  /// Mettre à jour une action commerciale
  static Future<bool> updateCommercialAction({
    required String actionId,
    String? title,
    String? description,
    String? type,
    String? status,
    String? priority,
    String? clientName,
    String? contactPerson,
    String? contactEmail,
    String? contactPhone,
    double? estimatedValue,
    double? actualValue,
    DateTime? dueDate,
    DateTime? completedDate,
    String? assignedTo,
    String? partnerId,
    String? notes,
    String? outcome,
  }) async {
    try {
      debugPrint('🏢 Mise à jour de l\'action commerciale: $actionId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (type != null) updateData['type'] = type;
      if (status != null) updateData['status'] = status;
      if (priority != null) updateData['priority'] = priority;
      if (clientName != null) updateData['client_name'] = clientName;
      if (contactPerson != null) updateData['contact_person'] = contactPerson;
      if (contactEmail != null) updateData['contact_email'] = contactEmail;
      if (contactPhone != null) updateData['contact_phone'] = contactPhone;
      if (estimatedValue != null) updateData['estimated_value'] = estimatedValue;
      if (actualValue != null) updateData['actual_value'] = actualValue;
      if (dueDate != null) updateData['due_date'] = dueDate.toIso8601String();
      if (completedDate != null) updateData['completed_date'] = completedDate.toIso8601String();
      if (assignedTo != null) updateData['assigned_to'] = assignedTo;
      if (partnerId != null) updateData['partner_id'] = partnerId;
      if (notes != null) updateData['notes'] = notes;
      if (outcome != null) updateData['outcome'] = outcome;

      await client
          .from('commercial_actions')
          .update(updateData)
          .eq('id', actionId);

      debugPrint('✅ Action commerciale mise à jour');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour de l\'action commerciale: $e');
      return false;
    }
  }

  /// Supprimer une action commerciale
  static Future<bool> deleteCommercialAction(String actionId) async {
    try {
      debugPrint('🏢 Suppression de l\'action commerciale: $actionId');

      await client
          .from('commercial_actions')
          .delete()
          .eq('id', actionId);

      debugPrint('✅ Action commerciale supprimée');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de l\'action commerciale: $e');
      return false;
    }
  }

  /// Marquer une action commerciale comme terminée
  static Future<bool> completeCommercialAction({
    required String actionId,
    double? actualValue,
    String? outcome,
  }) async {
    return updateCommercialAction(
      actionId: actionId,
      status: 'completed',
      completedDate: DateTime.now(),
      actualValue: actualValue,
      outcome: outcome,
    );
  }

  // ==========================================
  // GESTION DES DISPONIBILITÉS DES PARTENAIRES
  // ==========================================

  /// Récupérer les disponibilités des partenaires pour une période donnée
  static Future<List<Map<String, dynamic>>> getPartnerAvailabilityForPeriod({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('📅 Récupération des disponibilités des partenaires...');
      
      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime.now().add(const Duration(days: 30));
      
      // Essayer d'abord avec la fonction RPC
      try {
        final response = await client.rpc('get_partner_availability_for_period', params: {
          'start_date': start.toIso8601String().split('T')[0],
          'end_date': end.toIso8601String().split('T')[0],
        });
        
        final availabilities = List<Map<String, dynamic>>.from(response);
        debugPrint('📅 ${availabilities.length} disponibilités récupérées via RPC');
        return availabilities;
      } catch (rpcError) {
        debugPrint('⚠️ Erreur RPC, essai avec requête directe: $rpcError');
        
        // Fallback : requête directe sur la table avec jointure
        final currentUser = client.auth.currentUser;
        if (currentUser == null) {
          throw Exception('Utilisateur non connecté');
        }

        // Récupérer d'abord l'entreprise de l'utilisateur
        final userProfile = await client
            .from('profiles')
            .select('company_id')
            .eq('user_id', currentUser.id)
            .single();

        // Puis récupérer les disponibilités avec jointure manuelle
        final availabilityResponse = await client
            .from('partner_availability')
            .select('*')
            .eq('company_id', userProfile['company_id'])
            .gte('date', start.toIso8601String().split('T')[0])
            .lte('date', end.toIso8601String().split('T')[0])
            .order('date', ascending: true);
        
        // Récupérer les profils des partenaires
        final partnerIds = availabilityResponse
            .map((item) => item['partner_id'])
            .toSet()
            .toList();
        
        Map<String, Map<String, dynamic>> partnersMap = {};
        if (partnerIds.isNotEmpty) {
          final partnersResponse = await client
              .from('profiles')
              .select('user_id, first_name, last_name, email')
              .inFilter('user_id', partnerIds);
          
          for (var partner in partnersResponse) {
            partnersMap[partner['user_id']] = partner;
          }
        }
        
        // Transformer les données pour correspondre au format attendu
        final availabilities = availabilityResponse.map<Map<String, dynamic>>((item) {
          final profile = partnersMap[item['partner_id']] ?? {};
          final firstName = profile['first_name']?.toString() ?? '';
          final lastName = profile['last_name']?.toString() ?? '';
          final partnerName = '$firstName $lastName'.trim();
          
          return {
            'id': item['id'],
            'partner_id': item['partner_id'],
            'partner_name': partnerName.isEmpty ? 'Partenaire inconnu' : partnerName,
            'partner_email': profile['email']?.toString() ?? '',
            'date': item['date'],
            'is_available': item['is_available'],
            'availability_type': item['availability_type'],
            'start_time': item['start_time'],
            'end_time': item['end_time'],
            'notes': item['notes'],
            'unavailability_reason': item['unavailability_reason'],
          };
        }).toList();
        
        debugPrint('📅 ${availabilities.length} disponibilités récupérées via requête directe');
        return availabilities;
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des disponibilités: $e');
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
      await _createUserNotification(
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
        await _createUserNotification(
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
        await _createUserNotification(
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

  /// Obtenir les notifications de l'utilisateur connecté
  static Future<List<Map<String, dynamic>>> getUserNotifications() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return [];

      final response = await client
          .from('user_notifications')
          .select('*')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des notifications: $e');
      return [];
    }
  }

  /// Marquer une notification comme lue
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return false;

      await client.from('user_notifications').update({
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      }).eq('id', notificationId).eq('user_id', currentUser.id);

      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors du marquage de notification: $e');
      return false;
    }
  }

  /// Obtenir le nombre de notifications non lues
  static Future<int> getUnreadNotificationsCount() async {
    try {
      final currentUser = SupabaseService.currentUser;
      if (currentUser == null) return 0;

      final response = await client
          .from('unread_notifications_count')
          .select('unread_count')
          .eq('user_id', currentUser.id)
          .single();

      return response['unread_count'] ?? 0;
    } catch (e) {
      debugPrint('❌ Erreur lors du comptage des notifications: $e');
      return 0;
    }
  }

  /// Fonction privée pour créer une notification utilisateur
  static Future<void> _createUserNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? missionAssignmentId,
    String? notificationId,
  }) async {
    try {
      await client.rpc('create_user_notification', params: {
        'p_user_id': userId,
        'p_title': title,
        'p_message': message,
        'p_type': type,
        'p_mission_assignment_id': missionAssignmentId,
        'p_notification_id': notificationId,
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de notification: $e');
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

  /// Résumé des disponibilités des partenaires sur une période, avec agrégation par partenaire
  static Future<Map<String, dynamic>> getPartnersAvailabilitySummary({
    DateTime? startDate,
    DateTime? endDate,
    int periodDays = 14,
  }) async {
    final DateTime start = startDate ?? DateTime.now();
    final DateTime end = endDate ?? DateTime.now().add(Duration(days: periodDays - 1));

    try {
      final availabilities = await getPartnerAvailabilityForPeriod(
        startDate: start,
        endDate: end,
      );

      // Agréger par partenaire
      final Map<String, Map<String, dynamic>> partnerToSummary = {};

      for (final item in availabilities) {
        final String partnerId = item['partner_id']?.toString() ?? '';
        if (partnerId.isEmpty) continue;

        partnerToSummary.putIfAbsent(partnerId, () => {
          'partner_id': partnerId,
          'partner_name': item['partner_name'] ?? '',
          'partner_email': item['partner_email'] ?? '',
          'daily': <Map<String, dynamic>>[],
          'available_days': 0,
        });

        final bool isAvailable = item['is_available'] == true;
        final String availabilityType = (item['availability_type'] ?? '').toString();

        // Compter un jour disponible si is_available true (quel que soit le type)
        if (isAvailable) {
          partnerToSummary[partnerId]!['available_days'] =
              (partnerToSummary[partnerId]!['available_days'] as int) + 1;
        }

        (partnerToSummary[partnerId]!['daily'] as List<Map<String, dynamic>>).add({
          'date': item['date'],
          'is_available': isAvailable,
          'availability_type': availabilityType,
        });
      }

      return {
        'start_date': start.toIso8601String().split('T')[0],
        'end_date': end.toIso8601String().split('T')[0],
        'summary': partnerToSummary.values.toList(),
      };
    } catch (e) {
      debugPrint('❌ Erreur résumé disponibilités: $e');
      return {
        'start_date': start.toIso8601String().split('T')[0],
        'end_date': end.toIso8601String().split('T')[0],
        'summary': <Map<String, dynamic>>[],
      };
    }
  }

  /// Liste des partenaires disponibles au moins `minAvailableDays` jours sur les `periodDays` prochains jours
  static Future<List<Map<String, dynamic>>> getPartnersAvailableAtLeast({
    int periodDays = 14,
    int minAvailableDays = 7,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(Duration(days: periodDays - 1));

    final summary = await getPartnersAvailabilitySummary(
      startDate: start,
      endDate: end,
      periodDays: periodDays,
    );

    final List<Map<String, dynamic>> partners = List<Map<String, dynamic>>.from(summary['summary'] ?? []);
    partners.sort((a, b) => (b['available_days'] as int).compareTo(a['available_days'] as int));
    return partners.where((p) => (p['available_days'] as int) >= minAvailableDays).toList();
  }

  /// Récupérer les partenaires disponibles pour une date donnée
  static Future<List<Map<String, dynamic>>> getAvailablePartnersForDate(DateTime date) async {
    try {
      debugPrint('📅 Récupération des partenaires disponibles pour ${date.toIso8601String().split('T')[0]}');
      
      final response = await client.rpc('get_available_partners_for_date', params: {
        'target_date': date.toIso8601String().split('T')[0],
      });
      
      final partners = List<Map<String, dynamic>>.from(response);
      debugPrint('📅 ${partners.length} partenaires disponibles trouvés');
      return partners;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des partenaires disponibles: $e');
      return [];
    }
  }

  /// Récupérer les disponibilités d'un partenaire spécifique
  static Future<List<Map<String, dynamic>>> getPartnerOwnAvailability({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('📅 Récupération des disponibilités du partenaire connecté...');
      
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final start = startDate ?? DateTime.now();
      final end = endDate ?? DateTime.now().add(const Duration(days: 30));
      
      final response = await client
          .from('partner_availability_view')
          .select('*')
          .eq('partner_id', currentUser.id)
          .gte('date', start.toIso8601String().split('T')[0])
          .lte('date', end.toIso8601String().split('T')[0])
          .order('date', ascending: true);
      
      final availabilities = List<Map<String, dynamic>>.from(response);
      debugPrint('📅 ${availabilities.length} disponibilités du partenaire récupérées');
      return availabilities;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des disponibilités du partenaire: $e');
      return [];
    }
  }

  /// Créer ou mettre à jour la disponibilité d'un partenaire pour une date
  static Future<Map<String, dynamic>?> setPartnerAvailability({
    required DateTime date,
    required bool isAvailable,
    String availabilityType = 'full_day',
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? notes,
    String? unavailabilityReason,
    String? partnerId, // Si null, utilise l'utilisateur connecté
  }) async {
    try {
      debugPrint('📅 Définition de la disponibilité pour ${date.toIso8601String().split('T')[0]}');
      
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final targetPartnerId = partnerId ?? currentUser.id;

      // Récupérer l'entreprise de l'utilisateur
      final userProfile = await client
          .from('profiles')
          .select('company_id')
          .eq('user_id', currentUser.id)
          .single();

      final availabilityData = {
        'partner_id': targetPartnerId,
        'company_id': userProfile['company_id'],
        'date': date.toIso8601String().split('T')[0],
        'is_available': isAvailable,
        'availability_type': availabilityType,
        'start_time': startTime != null ? '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00' : null,
        'end_time': endTime != null ? '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00' : null,
        'notes': notes,
        'unavailability_reason': unavailabilityReason,
        'created_by': currentUser.id,
      };

      // Supprimer les valeurs nulles
      availabilityData.removeWhere((key, value) => value == null);

      // Utiliser upsert pour créer ou mettre à jour
      final response = await client
          .from('partner_availability')
          .upsert(availabilityData, onConflict: 'partner_id,date')
          .select()
          .single();

      debugPrint('✅ Disponibilité définie avec succès');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la définition de la disponibilité: $e');
      return null;
    }
  }

  /// Supprimer la disponibilité d'un partenaire pour une date
  static Future<bool> deletePartnerAvailability({
    required DateTime date,
    String? partnerId, // Si null, utilise l'utilisateur connecté
  }) async {
    try {
      debugPrint('📅 Suppression de la disponibilité pour ${date.toIso8601String().split('T')[0]}');
      
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final targetPartnerId = partnerId ?? currentUser.id;

      await client
          .from('partner_availability')
          .delete()
          .eq('partner_id', targetPartnerId)
          .eq('date', date.toIso8601String().split('T')[0]);

      debugPrint('✅ Disponibilité supprimée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la disponibilité: $e');
      return false;
    }
  }

  /// Créer les disponibilités par défaut pour un partenaire
  static Future<bool> createDefaultAvailabilityForPartner({
    String? partnerId, // Si null, utilise l'utilisateur connecté
    int daysAhead = 30,
  }) async {
    try {
      debugPrint('📅 Création des disponibilités par défaut...');
      
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Utilisateur non connecté');
      }

      final targetPartnerId = partnerId ?? currentUser.id;

      await client.rpc('create_default_availability_for_partner', params: {
        'new_partner_id': targetPartnerId,
        'days_ahead': daysAhead,
      });

      debugPrint('✅ Disponibilités par défaut créées avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création des disponibilités par défaut: $e');
      return false;
    }
  }

  /// Définir la disponibilité pour une plage de dates
  static Future<bool> setPartnerAvailabilityBulk({
    required DateTime startDate,
    required DateTime endDate,
    required bool isAvailable,
    String availabilityType = 'full_day',
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? notes,
    String? unavailabilityReason,
    List<int>? daysOfWeek, // 1=Lundi, 7=Dimanche (null = tous les jours)
    String? partnerId,
  }) async {
    try {
      debugPrint('📅 Définition de la disponibilité en masse du ${startDate.toIso8601String().split('T')[0]} au ${endDate.toIso8601String().split('T')[0]}');
      
      bool allSuccess = true;
      DateTime currentDate = startDate;

      while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
        // Vérifier si on doit traiter ce jour de la semaine
        bool shouldProcess = true;
        if (daysOfWeek != null) {
          int dayOfWeek = currentDate.weekday; // 1=Lundi, 7=Dimanche
          shouldProcess = daysOfWeek.contains(dayOfWeek);
        }

        if (shouldProcess) {
          final result = await setPartnerAvailability(
            date: currentDate,
            isAvailable: isAvailable,
            availabilityType: availabilityType,
            startTime: startTime,
            endTime: endTime,
            notes: notes,
            unavailabilityReason: unavailabilityReason,
            partnerId: partnerId,
          );

          if (result == null) {
            allSuccess = false;
          }
        }

        currentDate = currentDate.add(const Duration(days: 1));
      }

      debugPrint(allSuccess ? '✅ Disponibilités en masse définies avec succès' : '⚠️ Certaines disponibilités n\'ont pas pu être définies');
      return allSuccess;
    } catch (e) {
      debugPrint('❌ Erreur lors de la définition des disponibilités en masse: $e');
      return false;
    }
  }

  // Méthodes pour le questionnaire partenaire
  static Future<Map<String, dynamic>?> createPartnerProfile(Map<String, dynamic> profileData) async {
    try {
      debugPrint('🔍 Création du profil partenaire...');
      debugPrint('📊 Données reçues: $profileData');
      
      // Vérifier que l'utilisateur est connecté
      if (currentUser == null) {
        debugPrint('❌ Aucun utilisateur connecté');
        throw Exception('Utilisateur non connecté');
      }
      
      debugPrint('👤 Utilisateur connecté: ${currentUser!.id}');
      
      // Vérifier s'il existe déjà un profil
      debugPrint('🔍 Vérification d\'un profil existant...');
      try {
        final existingProfile = await client
            .from('partner_profiles')
            .select('id, questionnaire_completed')
            .eq('user_id', currentUser!.id)
            .maybeSingle();
        
        if (existingProfile != null) {
          debugPrint('⚠️ Profil existant trouvé: ${existingProfile['id']}');
          debugPrint('📋 Questionnaire complété: ${existingProfile['questionnaire_completed']}');
          
          // Mettre à jour le profil existant au lieu d'en créer un nouveau
          debugPrint('🔄 Mise à jour du profil existant...');
          final response = await client
              .from('partner_profiles')
              .update(profileData)
              .eq('user_id', currentUser!.id)
              .select()
              .single();
          
          debugPrint('✅ Profil partenaire mis à jour avec succès: $response');
          return response;
        }
      } catch (e) {
        debugPrint('ℹ️ Aucun profil existant trouvé, création d\'un nouveau profil');
      }
      
      // Créer un nouveau profil
      debugPrint('💾 Création d\'un nouveau profil...');
      final response = await client
          .from('partner_profiles')
          .insert(profileData)
          .select()
          .single();
      
      debugPrint('✅ Profil partenaire créé avec succès: $response');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création du profil partenaire: $e');
      debugPrint('🔍 Type d\'erreur: ${e.runtimeType}');
      debugPrint('🔍 Détails de l\'erreur: ${e.toString()}');
      rethrow;
    }
  }

  static Future<bool> hasCompletedQuestionnaire() async {
    try {
      if (currentUser == null) return false;
      
      // Contourner le problème de récursion en utilisant une requête plus simple
      final response = await client
          .from('partner_profiles')
          .select('questionnaire_completed')
          .eq('user_id', currentUser!.id)
          .maybeSingle();
      
      if (response == null) {
        debugPrint('ℹ️ Aucun profil trouvé, questionnaire non complété');
        return false;
      }
      
      return response['questionnaire_completed'] ?? false;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du questionnaire: $e');
      // En cas d'erreur, considérer que le questionnaire n'est pas complété
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getPartnerProfile(String partnerId) async {
    try {
      debugPrint('🔍 Récupération du profil partenaire: $partnerId');
      
      final response = await client
          .from('partner_profiles')
          .select('*')
          .eq('user_id', partnerId)
          .single();
      
      debugPrint('📊 Profil récupéré: ${response['first_name']} ${response['last_name']}');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du profil: $e');
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


  static Future<bool> sendNotificationToPartner(String partnerId, String title, String message) async {
    try {
      debugPrint('🔔 Envoi de notification au partenaire: $partnerId');
      debugPrint('📝 Titre: $title');
      debugPrint('📝 Message: $message');
      
      final notificationData = {
        'user_id': partnerId,
        'title': title,
        'message': message,
        'type': 'mission_assignment',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };
      
      await client
          .from('notifications')
          .insert(notificationData);
      
      debugPrint('✅ Notification envoyée avec succès');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi de la notification: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getPartnerAvailability(
    String partnerId,
    DateTime selectedDate,
    String view,
  ) async {
    try {
      debugPrint('📅 Récupération des disponibilités du partenaire: $partnerId');
      debugPrint('📅 Date sélectionnée: $selectedDate');
      debugPrint('📅 Vue: $view');
      
      DateTime startDate;
      DateTime endDate;
      
      if (view == 'week') {
        // Semaine courante
        startDate = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        endDate = startDate.add(const Duration(days: 6));
      } else {
        // Mois courant
        startDate = DateTime(selectedDate.year, selectedDate.month, 1);
        endDate = DateTime(selectedDate.year, selectedDate.month + 1, 0);
      }
      
      final response = await client
          .from('partner_availability')
          .select('*')
          .eq('partner_id', partnerId)
          .gte('start_time', startDate.toIso8601String())
          .lte('end_time', endDate.toIso8601String())
          .order('start_time');
      
      debugPrint('📊 ${response.length} créneaux de disponibilité trouvés');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des disponibilités: $e');
      return [];
    }
  }

  // Méthodes pour les associés - voir les profils partenaires
  static Future<List<Map<String, dynamic>>> getAllPartnerProfiles() async {
    try {
      debugPrint('🔍 Récupération de tous les profils partenaires...');
      debugPrint('👤 Utilisateur connecté: ${currentUser?.id}');
      debugPrint('🔑 Rôle utilisateur: ${currentUserRole?.value}');
      
      // Test 1: Vérifier si la table existe et est accessible
      try {
        await client
            .from('partner_profiles')
            .select('id')
            .limit(1);
        debugPrint('✅ Table partner_profiles accessible');
      } catch (tableError) {
        debugPrint('❌ Erreur accès table partner_profiles: $tableError');
        return [];
      }
      
      // Test 2: Compter le nombre total de profils
      try {
        final countResponse = await client
            .from('partner_profiles')
            .select('id');
        debugPrint('📊 Nombre total de profils dans la table: ${countResponse.length}');
      } catch (countError) {
        debugPrint('❌ Erreur comptage: $countError');
      }
      
      // Test 3: Récupérer tous les profils
      final response = await client
          .from('partner_profiles')
          .select('*')
          .order('created_at', ascending: false);
      
      debugPrint('📊 ${response.length} profils partenaires récupérés');
      
      if (response.isNotEmpty) {
        debugPrint('📋 Premier profil: ${response.first['first_name']} ${response.first['last_name']}');
      } else {
        debugPrint('⚠️ Aucun profil trouvé - vérifier les données et les politiques RLS');
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des profils partenaires: $e');
      debugPrint('🔍 Type d\'erreur: ${e.runtimeType}');
      debugPrint('🔍 Détails: ${e.toString()}');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> findBestPartnersForMission(
    Map<String, dynamic> missionCriteria,
    {int limit = 10}
  ) async {
    try {
      // Créer les critères de mission
      final criteriaResponse = await client
          .from('mission_criteria')
          .insert(missionCriteria)
          .select()
          .single();
      
      // Trouver les meilleurs partenaires
      final response = await client
          .rpc('find_best_partners_for_mission', params: {
            'p_mission_criteria_id': criteriaResponse['id'],
            'p_limit': limit,
          });
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur lors de la recherche de partenaires: $e');
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