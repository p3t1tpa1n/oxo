import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

/// Gestion des disponibilités des partenaires (extrait de SupabaseService).
class AvailabilityService {
  AvailabilityService._();

  static SupabaseClient get client => SupabaseService.client;
  static User? get currentUser => SupabaseService.currentUser;
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

}
