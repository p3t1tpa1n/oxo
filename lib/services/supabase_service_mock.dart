// Service Supabase mock pour tester sans connexion
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/user_role.dart';

class SupabaseService {
  static bool _isInitialized = false;
  static UserRole? _currentUserRole;
  
  // Simulation d'un utilisateur connecté
  static bool get isAuthenticated => _isInitialized;
  static Map<String, dynamic>? get currentUser => _isInitialized 
      ? {'id': 'test-user-123', 'email': 'test@example.com'} 
      : null;
  static UserRole? get currentUserRole => _currentUserRole;

  static Future<bool> initialize() async {
    debugPrint('🔄 Initialisation du service mock Supabase...');
    
    // Simuler un délai d'initialisation
    await Future.delayed(const Duration(seconds: 1));
    
    _isInitialized = true;
    _currentUserRole = UserRole.partenaire; // Pour tester le questionnaire
    
    debugPrint('✅ Service mock Supabase initialisé');
    return true;
  }

  // Méthodes mock pour le questionnaire
  static Future<Map<String, dynamic>?> createPartnerProfile(Map<String, dynamic> profileData) async {
    debugPrint('🔍 [MOCK] Création du profil partenaire...');
    debugPrint('📊 [MOCK] Données reçues: $profileData');
    
    // Simuler un délai de sauvegarde
    await Future.delayed(const Duration(seconds: 2));
    
    // Simuler une réponse réussie
    final mockResponse = {
      'id': 'mock-profile-123',
      'user_id': profileData['user_id'],
      'questionnaire_completed': true,
      'created_at': DateTime.now().toIso8601String(),
      ...profileData,
    };
    
    debugPrint('✅ [MOCK] Profil partenaire créé avec succès: $mockResponse');
    return mockResponse;
  }

  static Future<bool> hasCompletedQuestionnaire() async {
    debugPrint('🔍 [MOCK] Vérification du questionnaire...');
    return false; // Simuler qu'il n'a pas encore complété le questionnaire
  }

  static Future<Map<String, dynamic>?> getPartnerProfile() async {
    debugPrint('🔍 [MOCK] Récupération du profil...');
    return null; // Simuler qu'il n'y a pas encore de profil
  }

  static Future<List<Map<String, dynamic>>> getAllPartnerProfiles() async {
    debugPrint('🔍 [MOCK] Récupération des profils partenaires...');
    
    // Simuler des profils de test
    return [
      {
        'id': 'profile-1',
        'full_name': 'Jean Dupont',
        'company_name': 'Entreprise A',
        'activity_domains': ['Direction Financière'],
        'professional_experiences': ['Acquisition', 'Cession'],
        'business_sectors': ['Finance', 'Tech'],
        'experience_score': 85,
      },
      {
        'id': 'profile-2', 
        'full_name': 'Marie Martin',
        'company_name': 'Société B',
        'activity_domains': ['Direction Juridique'],
        'professional_experiences': ['Restructuration', 'PSE'],
        'business_sectors': ['Industrie', 'Services'],
        'experience_score': 92,
      },
    ];
  }

  static Future<List<Map<String, dynamic>>> findBestPartnersForMission(
    Map<String, dynamic> missionCriteria,
    {int limit = 10}
  ) async {
    debugPrint('🔍 [MOCK] Recherche de partenaires pour mission...');
    debugPrint('📊 [MOCK] Critères: $missionCriteria');
    
    // Simuler des résultats de recherche
    return [
      {
        'partner_profile_id': 'profile-1',
        'partner_name': 'Jean Dupont',
        'match_score': 8.5,
        'match_reasons': {
          'domains': ['Direction Financière'],
          'experiences': ['Acquisition'],
          'sectors': ['Finance'],
        },
      },
      {
        'partner_profile_id': 'profile-2',
        'partner_name': 'Marie Martin', 
        'match_score': 7.2,
        'match_reasons': {
          'domains': ['Direction Juridique'],
          'experiences': ['Restructuration'],
          'sectors': ['Industrie'],
        },
      },
    ];
  }

  // Méthodes d'authentification mock
  static Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    debugPrint('🔍 [MOCK] Connexion avec $email...');
    await Future.delayed(const Duration(seconds: 1));
    
    return {
      'user': {'id': 'test-user-123', 'email': email},
      'session': {'access_token': 'mock-token'},
    };
  }

  static Future<Map<String, dynamic>> signUpWithEmail(String email, String password) async {
    debugPrint('🔍 [MOCK] Inscription avec $email...');
    await Future.delayed(const Duration(seconds: 1));
    
    return {
      'user': {'id': 'test-user-123', 'email': email},
      'session': {'access_token': 'mock-token'},
    };
  }

  static Future<void> signOut() async {
    debugPrint('🔍 [MOCK] Déconnexion...');
    _isInitialized = false;
    _currentUserRole = null;
  }
}
