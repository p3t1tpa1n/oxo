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
      print('Chargement du fichier .env...'); // Debug
      await dotenv.load();
      
      final url = dotenv.env['SUPABASE_URL'];
      final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
      
      print('URL Supabase: $url'); // Debug
      print('Clé anonyme chargée: ${anonKey?.substring(0, 10)}...'); // Debug
      
      await Supabase.initialize(
        url: url!,
        anonKey: anonKey!,
      );
      
      _client = Supabase.instance.client;
      print('Client Supabase initialisé avec succès'); // Debug
    } catch (e) {
      print('Erreur lors de l\'initialisation de Supabase: $e'); // Debug
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
      if (currentUser == null) return null;

      final response = await client
          .from('profiles')
          .select('role')
          .eq('id', currentUser!.id)
          .maybeSingle();

      if (response != null && response['role'] != null) {
        final roleStr = response['role'].toString().toLowerCase();
        if (roleStr == 'associe') {
          _currentUserRole = UserRole.associe;
        } else {
          _currentUserRole = UserRole.partenaire;
        }
        return _currentUserRole;
      }

      await client.from('profiles').upsert({
        'id': currentUser!.id,
        'email': currentUser!.email,
        'role': 'partenaire',
      });
      
      _currentUserRole = UserRole.partenaire;
      return _currentUserRole;
    } catch (e) {
      print('Erreur lors de la récupération du rôle: $e');
      _currentUserRole = UserRole.partenaire;
      return _currentUserRole;
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

  // Méthode pour l'authentification modifiée pour inclure le rôle
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

  // Méthode pour la déconnexion modifiée
  static Future<void> signOut() async {
    await client.auth.signOut();
    _currentUserRole = null;
  }

  // Méthode pour vérifier l'état de la session
  static bool get isAuthenticated {
    return client.auth.currentSession != null;
  }

  // Méthode pour obtenir l'utilisateur courant
  static User? get currentUser {
    return client.auth.currentUser;
  }

  // Exemple de méthode pour récupérer des données
  static Future<List<Map<String, dynamic>>> fetchTasks() async {
    final response = await client
      .from('tasks')
      .select()
      .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Exemple de méthode pour insérer des données
  static Future<void> insertTask(Map<String, dynamic> taskData) async {
    await client
      .from('tasks')
      .insert(taskData);
  }

  // Exemple de méthode pour mettre à jour des données
  static Future<void> updateTask(int taskId, Map<String, dynamic> updates) async {
    await client
      .from('tasks')
      .update(updates)
      .eq('id', taskId);
  }

  // Exemple de méthode pour supprimer des données
  static Future<void> deleteTask(int taskId) async {
    await client
      .from('tasks')
      .delete()
      .eq('id', taskId);
  }
} 