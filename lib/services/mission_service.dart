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
    try {
      final targetDate = date ?? DateTime.now();
      debugPrint('🔍 Récupération des missions disponibles pour: ${targetDate.toIso8601String().split('T')[0]}');
      
      final response = await SupabaseService.client
          .rpc('get_available_missions_for_timesheet', params: {
        'p_partner_id': partnerId,
        'p_date': targetDate.toIso8601String().split('T')[0],
      });

      debugPrint('✅ ${response.length} missions disponibles');
      
      return (response as List)
          .map((json) => Mission.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des missions disponibles: $e');
      // En cas d'erreur, essayer de récupérer depuis la vue
      return await _getMissionsFromView(partnerId, date);
    }
  }

  /// Fallback: récupère les missions depuis la vue si la fonction RPC échoue
  static Future<List<Mission>> _getMissionsFromView(
    String partnerId,
    DateTime? date,
  ) async {
    try {
      final targetDate = date ?? DateTime.now();
      final dateStr = targetDate.toIso8601String().split('T')[0];
      debugPrint('🔄 Fallback: récupération depuis mission_with_context');
      
      // Chercher les missions assignées au partenaire (partner_id OU assigned_to)
      var response = await SupabaseService.client
          .from('mission_with_context')
          .select()
          .or('partner_id.eq.$partnerId,assigned_to.eq.$partnerId')
          .inFilter('status', ['in_progress', 'pending', 'accepted'])
          .lte('start_date', dateStr)
          .or('end_date.is.null,end_date.gte.$dateStr')
          .order('start_date', ascending: false);

      debugPrint('✅ ${response.length} missions récupérées depuis la vue');
      
      if (response.isEmpty) {
        // Si aucune mission trouvée, essayer directement depuis la table missions
        debugPrint('🔄 Aucune mission dans la vue, tentative directe depuis missions');
        response = await SupabaseService.client
            .from('missions')
            .select('*, company:company_id(name, city, group_id, investor_group:group_id(name, sector))')
            .or('partner_id.eq.$partnerId,assigned_to.eq.$partnerId')
            .inFilter('status', ['in_progress', 'pending', 'accepted'])
            .lte('start_date', dateStr)
            .or('end_date.is.null,end_date.gte.$dateStr')
            .order('start_date', ascending: false);
        debugPrint('✅ ${response.length} missions récupérées directement depuis missions');
      }
      
      return response
          .map<Mission>((json) => Mission.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur fallback: $e');
      // Dernier fallback : récupérer toutes les missions actives du partenaire
      return await _getSimpleMissionsForPartner(partnerId, date);
    }
  }

  /// Dernier recours : récupération simple des missions
  static Future<List<Mission>> _getSimpleMissionsForPartner(
    String partnerId,
    DateTime? date,
  ) async {
    try {
      // Note: date non utilisée dans ce fallback simple pour maximiser les résultats
      debugPrint('🔄 Dernier fallback: récupération simple des missions pour $partnerId');
      
      final response = await SupabaseService.client
          .from('missions')
          .select()
          .or('partner_id.eq.$partnerId,assigned_to.eq.$partnerId')
          .inFilter('status', ['in_progress', 'pending', 'accepted'])
          .order('start_date', ascending: false);
      
      debugPrint('✅ ${response.length} missions récupérées (fallback simple)');
      
      return response
          .map<Mission>((json) => Mission.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur fallback simple: $e');
      return [];
    }
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

