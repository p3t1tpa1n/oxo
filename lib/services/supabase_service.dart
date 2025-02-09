import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseClient? _client;
  
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

  // Méthode pour l'authentification
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('Tentative de connexion pour: $email'); // Debug
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      print('Réponse de connexion reçue'); // Debug
      return response;
    } catch (e) {
      print('Erreur lors de la connexion: $e'); // Debug
      rethrow;
    }
  }

  // Méthode pour la déconnexion
  static Future<void> signOut() async {
    await client.auth.signOut();
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