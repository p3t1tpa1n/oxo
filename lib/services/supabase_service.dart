import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole {
  associe,
  partenaire,
}

class SupabaseService {
  static SupabaseClient? _client;
  static UserRole? _currentUserRole;

  static Future<void> initialize() async {
    try {
      final bool isWeb = kIsWeb;

      String? url;
      String? anonKey;

      if (isWeb) {
        url = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
        anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
        
        if (url.isEmpty || anonKey.isEmpty) {
          throw Exception('Les variables d\'environnement SUPABASE_URL et SUPABASE_ANON_KEY sont requises pour la version web');
        }
      } else {
        debugPrint('Chargement du fichier .env...');
        await dotenv.load();
        url = dotenv.env['SUPABASE_URL'];
        anonKey = dotenv.env['SUPABASE_ANON_KEY'];
        
        if (url == null || anonKey == null) {
          throw Exception('Les variables SUPABASE_URL et SUPABASE_ANON_KEY sont manquantes dans le fichier .env');
        }
      }

      debugPrint('URL Supabase: $url');
      debugPrint('Clé anonyme chargée: ${anonKey.substring(0, 10)}...');

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );

      _client = Supabase.instance.client;
      debugPrint('Client Supabase initialisé avec succès');

      final session = _client?.auth.currentSession;
      if (session != null) {
        debugPrint('Session existante trouvée');
        _currentUserRole = await getCurrentUserRole();
      } else {
        debugPrint('Aucune session existante');
        await signOut();
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation de Supabase: $e');
      rethrow;
    }
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }
    return _client!;
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

  static UserRole? get currentUserRole => _currentUserRole;

  static Future<void> setUserRole(String userId, UserRole role) async {
    try {
      await client
          .from('profiles')
          .update({'role': role.toString().split('.').last})
          .eq('id', userId);
    } catch (e) {
      print('Erreur lors de la modification du rôle: $e');
      rethrow;
    }
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('Tentative de connexion pour: $email');
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUserRole = await getCurrentUserRole();
      }

      return response;
    } catch (e) {
      print('Erreur lors de la connexion: $e');
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
    final session = client.auth.currentSession;
    final isValid = session != null && !session.isExpired;
    debugPrint('Vérification de l\'authentification: ${isValid ? 'Authentifié' : 'Non authentifié'}');
    return isValid;
  }

  static User? get currentUser {
    return client.auth.currentUser;
  }

  static Future<List<Map<String, dynamic>>> fetchTasks() async {
    try {
      final response = await client
        .from('tasks')
        .select()
        .order('created_at', ascending: false);
      
      if (response == null) {
        return [];
      }
      
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
      if (response == null || response.isEmpty) {
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
      if (response == null) {
        return [];
      }
      return List<Map<String, dynamic>>.from(
        response.where((user) => user['user_role'] == 'partenaire')
      );
    } catch (e) {
      debugPrint('Erreur lors de la récupération des partenaires: $e');
      return [];
    }
  }
}