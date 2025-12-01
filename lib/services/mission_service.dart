// ============================================================================
// SERVICE: MissionService
// ============================================================================
// Gère les missions avec contexte complet (Société + Groupe)

import 'package:flutter/foundation.dart';
import '../models/mission.dart';
import '../models/company.dart';
import 'supabase_service.dart';

class MissionService {
  /// Récupère toutes les missions actives d'un partenaire
  static Future<List<Mission>> getMissionsByPartner(String partnerId) async {
    try {
      debugPrint('🔍 Récupération des missions pour le partenaire: $partnerId');
      
      final response = await SupabaseService.client
          .rpc('get_missions_by_partner', params: {
        'p_partner_id': partnerId,
      });

      debugPrint('✅ ${response.length} missions récupérées');
      
      return (response as List)
          .map((json) => Mission.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des missions: $e');
      rethrow;
    }
  }

  /// Récupère les missions disponibles pour la saisie du temps
  /// (missions actives à une date donnée)
  static Future<List<Mission>> getAvailableMissionsForTimesheet({
    required String partnerId,
    DateTime? date,
  }) async {
    debugPrint('🔍 MissionService: Recherche missions pour partenaire $partnerId');
    
    // Essayer plusieurs méthodes en cascade
    List<Mission> missions = [];
    
    // Méthode 1: RPC (si la fonction existe et fonctionne)
    try {
      final targetDate = date ?? DateTime.now();
      final response = await SupabaseService.client
          .rpc('get_available_missions_for_timesheet', params: {
        'p_partner_id': partnerId,
        'p_date': targetDate.toIso8601String().split('T')[0],
      });

      missions = (response as List)
          .map((json) => Mission.fromJson(json as Map<String, dynamic>))
          .toList();
      
      debugPrint('✅ RPC: ${missions.length} missions');
      if (missions.isNotEmpty) return missions;
    } catch (e) {
      debugPrint('⚠️ RPC échouée: $e');
    }

    // Méthode 2: Requête directe par partner_id
    try {
      final response = await SupabaseService.client
          .from('missions')
          .select()
          .eq('partner_id', partnerId)
          .inFilter('status', ['in_progress', 'pending', 'accepted']);
      
      missions = (response as List)
          .map((json) => Mission.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      
      debugPrint('✅ Query partner_id: ${missions.length} missions');
      if (missions.isNotEmpty) return missions;
    } catch (e) {
      debugPrint('⚠️ Query partner_id échouée: $e');
    }

    // Méthode 3: Requête directe par assigned_to
    try {
      final response = await SupabaseService.client
          .from('missions')
          .select()
          .eq('assigned_to', partnerId)
          .inFilter('status', ['in_progress', 'pending', 'accepted']);
      
      missions = (response as List)
          .map((json) => Mission.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      
      debugPrint('✅ Query assigned_to: ${missions.length} missions');
      if (missions.isNotEmpty) return missions;
    } catch (e) {
      debugPrint('⚠️ Query assigned_to échouée: $e');
    }

    // Méthode 4: Récupérer toutes les missions actives (dernier recours)
    try {
      debugPrint('🔄 Dernier recours: toutes les missions actives');
      final response = await SupabaseService.client
          .from('missions')
          .select()
          .inFilter('status', ['in_progress', 'pending', 'accepted'])
          .order('created_at', ascending: false)
          .limit(100);
      
      missions = (response as List)
          .map((json) => Mission.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      
      debugPrint('✅ Toutes missions actives: ${missions.length} missions');
      return missions;
    } catch (e) {
      debugPrint('❌ Dernier recours échoué: $e');
    }

    debugPrint('❌ AUCUNE mission trouvée !');
    return [];
  }


  /// Récupère une mission par ID
  static Future<Mission?> getMissionById(String missionId) async {
    try {
      final response = await SupabaseService.client
          .from('mission_with_context')
          .select()
          .eq('mission_id', missionId)
          .single();

      return Mission.fromJson(response);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de la mission $missionId: $e');
      return null;
    }
  }

  /// Récupère toutes les sociétés actives (pour sélection)
  static Future<List<Company>> getAllCompanies() async {
    try {
      final response = await SupabaseService.client
          .from('company_with_group')
          .select()
          .eq('company_active', true)
          .order('company_name');

      return (response as List)
          .map((json) => Company.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des sociétés: $e');
      rethrow;
    }
  }

  /// Récupère les sociétés d'un groupe
  static Future<List<Company>> getCompaniesByGroup(int groupId) async {
    try {
      final response = await SupabaseService.client
          .from('company_with_group')
          .select()
          .eq('group_id', groupId)
          .eq('company_active', true)
          .order('company_name');

      return (response as List)
          .map((json) => Company.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des sociétés du groupe $groupId: $e');
      rethrow;
    }
  }

  /// Crée une nouvelle mission
  static Future<Mission> createMission({
    required String title,
    required int companyId,
    required String partnerId,
    required DateTime startDate,
    DateTime? endDate,
    String status = 'in_progress',
    String progressStatus = 'à_assigner',
    double? dailyRate,
    double? estimatedDays,
    String? notes,
  }) async {
    try {
      final response = await SupabaseService.client
          .from('missions')
          .insert({
        'title': title,
        'company_id': companyId,
        'partner_id': partnerId,
        'start_date': startDate.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
        'status': status,
        'progress_status': progressStatus,
        'daily_rate': dailyRate,
        'estimated_days': estimatedDays,
        'notes': notes,
      })
          .select()
          .single();

      debugPrint('✅ Mission créée: ${response['id']}');
      return Mission.fromJson(response);
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de la mission: $e');
      rethrow;
    }
  }

  /// Met à jour une mission
  static Future<void> updateMission({
    required String missionId,
    String? title,
    int? companyId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? progressStatus,
    double? dailyRate,
    double? estimatedDays,
    String? notes,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (companyId != null) data['company_id'] = companyId;
      if (startDate != null) data['start_date'] = startDate.toIso8601String().split('T')[0];
      if (endDate != null) data['end_date'] = endDate.toIso8601String().split('T')[0];
      if (status != null) data['status'] = status;
      if (progressStatus != null) data['progress_status'] = progressStatus;
      if (dailyRate != null) data['daily_rate'] = dailyRate;
      if (estimatedDays != null) data['estimated_days'] = estimatedDays;
      if (notes != null) data['notes'] = notes;

      await SupabaseService.client
          .from('missions')
          .update(data)
          .eq('id', missionId);

      debugPrint('✅ Mission mise à jour: $missionId');
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour de la mission: $e');
      rethrow;
    }
  }

  /// Supprime une mission
  static Future<void> deleteMission(String missionId) async {
    try {
      await SupabaseService.client
          .from('missions')
          .delete()
          .eq('id', missionId);

      debugPrint('✅ Mission supprimée: $missionId');
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression de la mission: $e');
      rethrow;
    }
  }
}

