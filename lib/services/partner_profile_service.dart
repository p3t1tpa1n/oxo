import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Profils partenaires et questionnaire (extrait de SupabaseService).
class PartnerProfileService {
  PartnerProfileService._();

  static SupabaseClient get client => SupabaseService.client;
  static User? get currentUser => SupabaseService.currentUser;
  static get currentUserRole => SupabaseService.currentUserRole;

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
}
