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

  // NOUVELLE CONFIGURATION SUPABASE
  // Remplacez ces valeurs par vos nouvelles credentials Supabase
  static const defaultUrl = 'https://VOTRE-NOUVELLE-URL.supabase.co';
  static const defaultKey = 'VOTRE-NOUVELLE-CLE-API';

  static Future<bool> initialize() async {
    if (_client != null) return true;

    debugPrint('Initialisation de Supabase...');
    
    try {
      String url = defaultUrl;
      String anonKey = defaultKey;
      
      if (kIsWeb) {
        // Pour Vercel et autres déploiements web
        debugPrint('Initialisation en mode web (Vercel)');
        try {
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
        debug: kDebugMode,
      );
      
      _client = Supabase.instance.client;
      
      debugPrint('✅ Supabase initialisé avec succès');
      debugPrint('URL: $url');
      debugPrint('Session active: ${_client!.auth.currentSession != null}');
      
      return true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de Supabase: $e');
      return false;
    }
  }

  // Méthode pour récupérer les variables d'environnement web
  static String? _getWebEnvVar(String key) {
    // Cette méthode sera implémentée selon votre setup web
    return null;
  }

  // Getters pour l'état de l'application
  static bool get isAuthenticated => _client?.auth.currentSession != null;
  static User? get currentUser => _client?.auth.currentUser;
  static UserRole? get currentUserRole => _currentUserRole;

  // Méthodes d'authentification
  static Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _client!.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await _client!.auth.signUp(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client!.auth.signOut();
    _currentUserRole = null;
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
      
      // Insérer le profil dans la base de données
      final response = await client
          .from('partner_profiles')
          .insert(profileData)
          .select()
          .single();
      
      debugPrint('✅ Profil partenaire créé avec succès: $response');
      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création du profil partenaire: $e');
      rethrow;
    }
  }

  static Future<bool> hasCompletedQuestionnaire() async {
    try {
      if (currentUser == null) return false;
      
      final response = await client
          .from('partner_profiles')
          .select('questionnaire_completed')
          .eq('user_id', currentUser!.id)
          .single();
      
      return response['questionnaire_completed'] ?? false;
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification du questionnaire: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getPartnerProfile() async {
    try {
      if (currentUser == null) return null;
      
      final response = await client
          .from('partner_profiles')
          .select('*')
          .eq('user_id', currentUser!.id)
          .single();
      
      return response;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du profil: $e');
      return null;
    }
  }

  // Méthodes pour les associés - voir les profils partenaires
  static Future<List<Map<String, dynamic>>> getAllPartnerProfiles() async {
    try {
      final response = await client
          .from('partner_profiles_summary')
          .select('*')
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des profils partenaires: $e');
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
}
