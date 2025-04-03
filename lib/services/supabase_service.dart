import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:version/version.dart';

enum UserRole {
  associe,
  partenaire,
}

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
      await dotenv.load();
      
      String? url;
      String? anonKey;
      
      if (kIsWeb) {
        debugPrint('Exécution en mode Web - recherche des variables d\'environnement');
        url = _getEnvVar('SUPABASE_URL');
        anonKey = _getEnvVar('SUPABASE_ANON_KEY');
        
        debugPrint('URL Supabase: ${url != null ? 'Trouvée' : 'Non trouvée'}');
        debugPrint('Clé anonyme: ${anonKey != null ? 'Trouvée' : 'Non trouvée'}');
      } else {
        // Mode natif, utiliser directement dotenv
        url = dotenv.env['SUPABASE_URL'];
        anonKey = dotenv.env['SUPABASE_ANON_KEY'];
        
        debugPrint('URL Supabase: $url');
        debugPrint('Clé anonyme: ${anonKey != null ? 'Trouvée' : 'Non trouvée'}');
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
    // Les variables seront injectées dans window par le HTML
    if (!kIsWeb) return null;
    
    // La logique d'accès aux variables d'environnement est gérée par le JavaScript injecté
    return null;
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
} 