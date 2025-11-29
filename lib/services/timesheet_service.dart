// ============================================================================
// SERVICE TIMESHEET - Logique métier du module OXO TIME SHEETS
// ============================================================================

import 'package:flutter/foundation.dart';
import '../models/timesheet_models.dart';
import 'supabase_service.dart';

class TimesheetService {
  // ============================================================================
  // GESTION DES TARIFS (Associés uniquement)
  // ============================================================================

  /// Récupère tous les tarifs avec les détails des companies
  static Future<List<PartnerRate>> getAllRates() async {
    try {
      // Récupérer les tarifs
      final ratesResponse = await SupabaseService.client
          .from('partner_rates')
          .select('*')
          .order('created_at', ascending: false);

      // Récupérer toutes les companies pour les jointures
      final companiesResponse = await SupabaseService.client
          .from('company')
          .select('id, name');

      // Créer un map pour accéder rapidement aux companies par ID
      final companiesMap = <int, Map<String, dynamic>>{};
      for (var company in companiesResponse as List) {
        final id = company['id'] as int?;
        if (id != null) {
          companiesMap[id] = company;
        }
      }

      // Mapper les tarifs avec les noms des companies
      return (ratesResponse as List).map((json) {
        final companyId = json['company_id'] as int?;
        if (companyId != null && companiesMap.containsKey(companyId)) {
          json['company_name'] = companiesMap[companyId]!['name'];
        }
        return PartnerRate.fromJson(json);
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur getAllRates: $e');
      rethrow;
    }
  }

  /// Récupère les tarifs d'un opérateur spécifique
  static Future<List<PartnerRate>> getPartnerRates(String partnerId) async {
    try {
      final response = await SupabaseService.client
          .from('partner_rates')
          .select('*')
          .eq('partner_id', partnerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PartnerRate.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur getPartnerRates: $e');
      rethrow;
    }
  }

  /// Crée ou met à jour un tarif
  static Future<void> upsertRate({
    required String partnerId,
    required int companyId,
    required double dailyRate,
  }) async {
    try {
      await SupabaseService.client.from('partner_rates').upsert({
        'partner_id': partnerId,
        'company_id': companyId,
        'daily_rate': dailyRate,
      });
      debugPrint('✅ Tarif créé/mis à jour avec succès');
    } catch (e) {
      debugPrint('❌ Erreur upsertRate: $e');
      rethrow;
    }
  }

  /// Supprime un tarif
  static Future<void> deleteRate(String rateId) async {
    try {
      await SupabaseService.client
          .from('partner_rates')
          .delete()
          .eq('id', rateId);
      debugPrint('✅ Tarif supprimé avec succès');
    } catch (e) {
      debugPrint('❌ Erreur deleteRate: $e');
      rethrow;
    }
  }

  /// Récupère le tarif journalier d'un opérateur pour une company
  static Future<double> getDailyRate(String partnerId, int companyId) async {
    try {
      final response = await SupabaseService.client
          .rpc('get_partner_daily_rate', params: {
        'p_partner_id': partnerId,
        'p_company_id': companyId,
      });

      return (response as num?)?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('❌ Erreur getDailyRate: $e');
      return 0.0;
    }
  }

  // ============================================================================
  // GESTION DES PERMISSIONS (Associés uniquement)
  // ============================================================================

  /// Récupère toutes les permissions
  static Future<List<PartnerClientPermission>> getAllPermissions() async {
    try {
      final response = await SupabaseService.client
          .from('partner_client_permissions')
          .select('*')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PartnerClientPermission.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur getAllPermissions: $e');
      rethrow;
    }
  }

  /// Récupère les permissions d'un opérateur spécifique
  static Future<List<PartnerClientPermission>> getOperatorPermissions(
      String partnerId) async {
    try {
      final response = await SupabaseService.client
          .from('partner_client_permissions')
          .select('*')
          .eq('partner_id', partnerId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PartnerClientPermission.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur getOperatorPermissions: $e');
      rethrow;
    }
  }

  /// Crée ou met à jour une permission
  static Future<void> upsertPermission({
    required String partnerId,
    required String clientId,
    required bool allowed,
  }) async {
    try {
      await SupabaseService.client.from('partner_client_permissions').upsert({
        'partner_id': partnerId,
        'client_id': clientId,
        'allowed': allowed,
      });
      debugPrint('✅ Permission créée/mise à jour avec succès');
    } catch (e) {
      debugPrint('❌ Erreur upsertPermission: $e');
      rethrow;
    }
  }

  /// Supprime une permission
  static Future<void> deletePermission(String permissionId) async {
    try {
      await SupabaseService.client
          .from('partner_client_permissions')
          .delete()
          .eq('id', permissionId);
      debugPrint('✅ Permission supprimée avec succès');
    } catch (e) {
      debugPrint('❌ Erreur deletePermission: $e');
      rethrow;
    }
  }

  /// Vérifie si un opérateur a accès à un client
  static Future<bool> checkOperatorAccess(
      String partnerId, String clientId) async {
    try {
      final response = await SupabaseService.client
          .rpc('check_operator_client_access', params: {
        'p_partner_id': partnerId,
        'p_client_id': clientId,
      });

      return response as bool? ?? true;
    } catch (e) {
      debugPrint('❌ Erreur checkOperatorAccess: $e');
      return true; // Par défaut, on autorise
    }
  }

  /// Récupère les clients autorisés pour un opérateur avec leurs tarifs
  static Future<List<AuthorizedClient>> getAuthorizedClients(
      String partnerId) async {
    try {
      final response = await SupabaseService.client
          .rpc('get_authorized_clients_for_partner', params: {
        'p_partner_id': partnerId,
      });

      return (response as List)
          .map((json) => AuthorizedClient.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur getAuthorizedClients: $e');
      rethrow;
    }
  }

  // ============================================================================
  // GESTION DES SAISIES DE TEMPS
  // ============================================================================

  /// Récupère les saisies de temps d'un opérateur pour un mois
  static Future<List<TimesheetEntry>> getMonthlyEntries({
    required String partnerId,
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      final response = await SupabaseService.client
          .from('timesheet_entries_detailed')
          .select()
          .eq('partner_id', partnerId)
          .gte('entry_date', startDate.toIso8601String().split('T')[0])
          .lte('entry_date', endDate.toIso8601String().split('T')[0])
          .order('entry_date', ascending: true);

      return (response as List)
          .map((json) => TimesheetEntry.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur getMonthlyEntries: $e');
      rethrow;
    }
  }

  /// Récupère toutes les saisies pour un mois (Associés uniquement)
  static Future<List<TimesheetEntry>> getAllMonthlyEntries({
    required int year,
    required int month,
    int? companyId,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      var query = SupabaseService.client
          .from('timesheet_entries_detailed')
          .select()
          .gte('entry_date', startDate.toIso8601String().split('T')[0])
          .lte('entry_date', endDate.toIso8601String().split('T')[0]);

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      }

      final response = await query.order('entry_date', ascending: true);

      return (response as List)
          .map((json) => TimesheetEntry.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur getAllMonthlyEntries: $e');
      rethrow;
    }
  }

  /// Crée une nouvelle saisie de temps
  static Future<TimesheetEntry> createEntry({
    required String partnerId,
    String? clientId, // Gardé pour compatibilité mais déprécié
    required DateTime entryDate,
    required double days, // 0.5 ou 1.0
    String? comment,
    int? companyId,
  }) async {
    try {
      // Récupérer le tarif journalier - utiliser companyId si disponible, sinon clientId (déprécié)
      final dailyRate = companyId != null 
        ? await getDailyRate(partnerId, companyId)
        : 0.0; // Si pas de companyId, tarif par défaut à 0

      // Vérifier si c'est un week-end
      final isWeekend = entryDate.weekday == DateTime.saturday ||
          entryDate.weekday == DateTime.sunday;

      final data = {
        'partner_id': partnerId,
        'client_id': clientId,
        'entry_date': entryDate.toIso8601String().split('T')[0],
        'days': days,
        'comment': comment,
        'daily_rate': dailyRate,
        'is_weekend': isWeekend,
        'status': 'draft',
        'company_id': companyId,
      };

      final response = await SupabaseService.client
          .from('timesheet_entries')
          .insert(data)
          .select()
          .single();

      debugPrint('✅ Saisie créée avec succès');
      return TimesheetEntry.fromJson(response);
    } catch (e) {
      debugPrint('❌ Erreur createEntry: $e');
      rethrow;
    }
  }

  /// Met à jour une saisie de temps
  static Future<void> updateEntry({
    required String entryId,
    String? clientId,
    double? days,
    String? comment,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> updates = {};

      if (clientId != null) updates['client_id'] = clientId;
      if (days != null) updates['days'] = days;
      if (comment != null) updates['comment'] = comment;
      if (status != null) updates['status'] = status;

      await SupabaseService.client
          .from('timesheet_entries')
          .update(updates)
          .eq('id', entryId);

      debugPrint('✅ Saisie mise à jour avec succès');
    } catch (e) {
      debugPrint('❌ Erreur updateEntry: $e');
      rethrow;
    }
  }

  /// Supprime une saisie de temps
  static Future<void> deleteEntry(String entryId) async {
    try {
      await SupabaseService.client
          .from('timesheet_entries')
          .delete()
          .eq('id', entryId);
      debugPrint('✅ Saisie supprimée avec succès');
    } catch (e) {
      debugPrint('❌ Erreur deleteEntry: $e');
      rethrow;
    }
  }

  /// Soumet toutes les saisies d'un mois (change le statut de draft à submitted)
  static Future<void> submitMonth({
    required String partnerId,
    required int year,
    required int month,
  }) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = DateTime(year, month + 1, 0);

      await SupabaseService.client
          .from('timesheet_entries')
          .update({'status': 'submitted'})
          .eq('partner_id', partnerId)
          .eq('status', 'draft')
          .gte('entry_date', startDate.toIso8601String().split('T')[0])
          .lte('entry_date', endDate.toIso8601String().split('T')[0]);

      debugPrint('✅ Mois soumis avec succès');
    } catch (e) {
      debugPrint('❌ Erreur submitMonth: $e');
      rethrow;
    }
  }

  // ============================================================================
  // CALENDRIER
  // ============================================================================

  /// Génère le calendrier d'un mois
  static Future<List<CalendarDay>> generateMonthCalendar({
    required int year,
    required int month,
  }) async {
    try {
      final response = await SupabaseService.client
          .rpc('generate_month_calendar', params: {
        'p_year': year,
        'p_month': month,
      });

      return (response as List)
          .map((json) => CalendarDay.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur generateMonthCalendar: $e');
      rethrow;
    }
  }

  /// Génère le calendrier avec les saisies existantes
  static Future<List<CalendarDay>> getMonthCalendarWithEntries({
    required String partnerId,
    required int year,
    required int month,
  }) async {
    try {
      // Récupérer le calendrier
      final calendar = await generateMonthCalendar(year: year, month: month);

      // Récupérer les saisies
      final entries = await getMonthlyEntries(
        partnerId: partnerId,
        year: year,
        month: month,
      );

      // Associer les saisies aux jours
      for (var day in calendar) {
        day.entry = entries.firstWhere(
          (entry) =>
              entry.entryDate.year == day.date.year &&
              entry.entryDate.month == day.date.month &&
              entry.entryDate.day == day.date.day,
          orElse: () => TimesheetEntry(
            id: '',
            partnerId: partnerId,
            clientId: '',
            entryDate: day.date,
            days: 0,
            dailyRate: 0,
            amount: 0,
            isWeekend: day.isWeekend,
            status: 'draft',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
      }

      return calendar;
    } catch (e) {
      debugPrint('❌ Erreur getMonthCalendarWithEntries: $e');
      rethrow;
    }
  }

  // ============================================================================
  // STATISTIQUES ET REPORTING
  // ============================================================================

  /// Récupère les statistiques mensuelles d'un opérateur
  static Future<MonthlyStats> getOperatorMonthlyStats({
    required String partnerId,
    required int year,
    required int month,
  }) async {
    try {
      final response = await SupabaseService.client
          .rpc('get_partner_monthly_stats', params: {
        'p_partner_id': partnerId,
        'p_year': year,
        'p_month': month,
      });

      if (response == null || (response as List).isEmpty) {
        return MonthlyStats.empty();
      }

      return MonthlyStats.fromJson((response as List).first);
    } catch (e) {
      debugPrint('❌ Erreur getOperatorMonthlyStats: $e');
      return MonthlyStats.empty();
    }
  }

  /// Récupère le rapport par client pour un mois
  static Future<List<ClientReport>> getClientReport({
    required int year,
    required int month,
    int? companyId,
  }) async {
    try {
      final response = await SupabaseService.client
          .rpc('get_timesheet_report_by_client', params: {
        'p_year': year,
        'p_month': month,
        'p_company_id': companyId,
      });

      return (response as List)
          .map((json) => ClientReport.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur getClientReport: $e');
      rethrow;
    }
  }

  /// Récupère le rapport par opérateur pour un mois
  static Future<List<PartnerReport>> getPartnerReport({
    required int year,
    required int month,
    int? companyId,
  }) async {
    try {
      final response = await SupabaseService.client
          .rpc('get_timesheet_report_by_partner', params: {
        'p_year': year,
        'p_month': month,
        'p_company_id': companyId,
      });

      return (response as List)
          .map((json) => PartnerReport.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ Erreur getPartnerReport: $e');
      rethrow;
    }
  }

  // ============================================================================
  // UTILITAIRES
  // ============================================================================

  /// Calcule le total d'heures pour une liste de saisies
  static double calculateTotalDays(List<TimesheetEntry> entries) {
    return entries.fold(0.0, (sum, entry) => sum + entry.days);
  }

  /// Calcule le montant total pour une liste de saisies
  static double calculateTotalAmount(List<TimesheetEntry> entries) {
    return entries.fold(0.0, (sum, entry) => sum + entry.amount);
  }

  /// Calcule les totaux hebdomadaires pour un mois
  static Map<int, Map<String, double>> calculateWeeklyTotals(
      List<TimesheetEntry> entries) {
    final Map<int, Map<String, double>> weeklyTotals = {};

    for (var entry in entries) {
      final weekNumber = _getWeekNumber(entry.entryDate);

      if (!weeklyTotals.containsKey(weekNumber)) {
        weeklyTotals[weekNumber] = {'days': 0.0, 'amount': 0.0};
      }

      weeklyTotals[weekNumber]!['days'] =
          weeklyTotals[weekNumber]!['days']! + entry.days;
      weeklyTotals[weekNumber]!['amount'] =
          weeklyTotals[weekNumber]!['amount']! + entry.amount;
    }

    return weeklyTotals;
  }

  /// Calcule le numéro de semaine pour une date
  static int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return ((daysSinceFirstDay + firstDayOfYear.weekday) / 7).ceil();
  }

  /// Valide les jours saisis (0.5 ou 1.0)
  static bool validateDays(double days) {
    return days == 0.5 || days == 1.0;
  }

  /// Formate un montant en euros
  static String formatAmount(double amount) {
    return '${amount.toStringAsFixed(2)} €';
  }

  /// Formate des jours
  static String formatDays(double days) {
    if (days == 0.5) return 'Demi-journée';
    if (days == 1.0) return 'Journée';
    return '${days.toStringAsFixed(1)} j';
  }
}

