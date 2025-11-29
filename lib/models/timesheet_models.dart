// ============================================================================
// MODÈLES DART POUR LE MODULE OXO TIME SHEETS
// ============================================================================

/// Modèle pour les tarifs journaliers opérateur-company
class PartnerRate {
  final String id;
  final String partnerId;
  final int? companyId; // Changé de String clientId à int? companyId
  final double dailyRate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Champs optionnels pour les jointures
  final String? partnerName;
  final String? partnerEmail;
  final String? companyName; // Changé de clientName à companyName

  PartnerRate({
    required this.id,
    required this.partnerId,
    this.companyId, // Optionnel pour compatibilité
    required this.dailyRate,
    required this.createdAt,
    required this.updatedAt,
    this.partnerName,
    this.partnerEmail,
    this.companyName,
  });

  factory PartnerRate.fromJson(Map<String, dynamic> json) {
    return PartnerRate(
      id: json['id']?.toString() ?? '',
      partnerId: json['partner_id']?.toString() ?? '',
      companyId: json['company_id'] != null ? (json['company_id'] as num).toInt() : null,
      dailyRate: (json['daily_rate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      partnerName: json['partner_name']?.toString(),
      partnerEmail: json['partner_email']?.toString(),
      companyName: json['company_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner_id': partnerId,
      'company_id': companyId,
      'daily_rate': dailyRate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsert() {
    return {
      'partner_id': partnerId,
      'company_id': companyId,
      'daily_rate': dailyRate,
    };
  }
}

/// Modèle pour les permissions opérateur-client
class PartnerClientPermission {
  final String id;
  final String partnerId;
  final String clientId;
  final bool allowed;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Champs optionnels pour les jointures
  final String? partnerName;
  final String? partnerEmail;
  final String? clientName;

  PartnerClientPermission({
    required this.id,
    required this.partnerId,
    required this.clientId,
    required this.allowed,
    required this.createdAt,
    required this.updatedAt,
    this.partnerName,
    this.partnerEmail,
    this.clientName,
  });

  factory PartnerClientPermission.fromJson(Map<String, dynamic> json) {
    return PartnerClientPermission(
      id: json['id']?.toString() ?? '',
      partnerId: json['partner_id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      allowed: json['allowed'] as bool? ?? true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      partnerName: json['partner_name']?.toString(),
      partnerEmail: json['partner_email']?.toString(),
      clientName: json['client_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner_id': partnerId,
      'client_id': clientId,
      'allowed': allowed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsert() {
    return {
      'partner_id': partnerId,
      'client_id': clientId,
      'allowed': allowed,
    };
  }
}

/// Modèle pour les saisies de temps
class TimesheetEntry {
  final String id;
  final String partnerId;
  final String clientId;
  final DateTime entryDate;
  final double days; // 0.5 = demi-journée, 1.0 = journée complète
  final String? comment;
  final double dailyRate;
  final double amount;
  final bool isWeekend;
  final String status; // draft, submitted, approved, rejected
  final String? companyId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Champs optionnels pour les jointures
  final String? partnerName;
  final String? partnerEmail;
  final String? clientName;
  final String? dayName;

  TimesheetEntry({
    required this.id,
    required this.partnerId,
    required this.clientId,
    required this.entryDate,
    required this.days,
    this.comment,
    required this.dailyRate,
    required this.amount,
    required this.isWeekend,
    required this.status,
    this.companyId,
    required this.createdAt,
    required this.updatedAt,
    this.partnerName,
    this.partnerEmail,
    this.clientName,
    this.dayName,
  });

  factory TimesheetEntry.fromJson(Map<String, dynamic> json) {
    return TimesheetEntry(
      id: json['id']?.toString() ?? '',
      partnerId: json['partner_id']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? '',
      entryDate: DateTime.tryParse(json['entry_date']?.toString() ?? '') ?? DateTime.now(),
      days: (json['days'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment']?.toString(),
      dailyRate: (json['daily_rate'] as num?)?.toDouble() ?? 0.0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      isWeekend: json['is_weekend'] as bool? ?? false,
      status: json['status']?.toString() ?? 'draft',
      companyId: json['company_id']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
      partnerName: json['partner_name']?.toString(),
      partnerEmail: json['partner_email']?.toString(),
      clientName: json['client_name']?.toString(),
      dayName: json['day_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner_id': partnerId,
      'client_id': clientId,
      'entry_date': entryDate.toIso8601String().split('T')[0],
      'days': days,
      'comment': comment,
      'daily_rate': dailyRate,
      'is_weekend': isWeekend,
      'status': status,
      'company_id': companyId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toInsert() {
    return {
      'partner_id': partnerId,
      'client_id': clientId,
      'entry_date': entryDate.toIso8601String().split('T')[0],
      'days': days,
      'comment': comment,
      'daily_rate': dailyRate,
      'is_weekend': isWeekend,
      'status': status,
      'company_id': companyId,
    };
  }

  TimesheetEntry copyWith({
    String? id,
    String? partnerId,
    String? clientId,
    DateTime? entryDate,
    double? days,
    String? comment,
    double? dailyRate,
    double? amount,
    bool? isWeekend,
    String? status,
    String? companyId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? partnerName,
    String? partnerEmail,
    String? clientName,
    String? dayName,
  }) {
    return TimesheetEntry(
      id: id ?? this.id,
      partnerId: partnerId ?? this.partnerId,
      clientId: clientId ?? this.clientId,
      entryDate: entryDate ?? this.entryDate,
      days: days ?? this.days,
      comment: comment ?? this.comment,
      dailyRate: dailyRate ?? this.dailyRate,
      amount: amount ?? this.amount,
      isWeekend: isWeekend ?? this.isWeekend,
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      partnerName: partnerName ?? this.partnerName,
      partnerEmail: partnerEmail ?? this.partnerEmail,
      clientName: clientName ?? this.clientName,
      dayName: dayName ?? this.dayName,
    );
  }
}

/// Modèle pour un jour du calendrier
class CalendarDay {
  final DateTime date;
  final String dayName;
  final int dayNumber;
  final bool isWeekend;
  final int weekNumber;

  // Saisie de temps associée (optionnel)
  TimesheetEntry? entry;

  CalendarDay({
    required this.date,
    required this.dayName,
    required this.dayNumber,
    required this.isWeekend,
    required this.weekNumber,
    this.entry,
  });

  factory CalendarDay.fromJson(Map<String, dynamic> json) {
    return CalendarDay(
      date: DateTime.tryParse(json['entry_date']?.toString() ?? '') ?? DateTime.now(),
      dayName: json['day_name']?.toString() ?? '',
      dayNumber: json['day_number'] as int? ?? 1,
      isWeekend: json['is_weekend'] as bool? ?? false,
      weekNumber: json['week_number'] as int? ?? 1,
    );
  }

  bool get hasEntry => entry != null;
}

/// Modèle pour les statistiques mensuelles d'un opérateur
class MonthlyStats {
  final double totalDays; // Total en jours (peut inclure des 0.5)
  final double totalAmount;
  final int daysWorked; // Nombre de jours distincts travaillés
  final int totalEntries;
  final double avgDaysPerEntry;

  MonthlyStats({
    required this.totalDays,
    required this.totalAmount,
    required this.daysWorked,
    required this.totalEntries,
    required this.avgDaysPerEntry,
  });

  factory MonthlyStats.fromJson(Map<String, dynamic> json) {
    return MonthlyStats(
      totalDays: (json['total_days'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      daysWorked: json['days_worked'] as int? ?? 0,
      totalEntries: json['total_entries'] as int? ?? 0,
      avgDaysPerEntry: (json['avg_days_per_entry'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory MonthlyStats.empty() {
    return MonthlyStats(
      totalDays: 0.0,
      totalAmount: 0.0,
      daysWorked: 0,
      totalEntries: 0,
      avgDaysPerEntry: 0.0,
    );
  }
}

/// Modèle pour le rapport par client
class ClientReport {
  final String clientId;
  final String clientName;
  final double totalDays; // Total en jours (peut inclure des 0.5)
  final double totalAmount;
  final int partnerCount;

  ClientReport({
    required this.clientId,
    required this.clientName,
    required this.totalDays,
    required this.totalAmount,
    required this.partnerCount,
  });

  factory ClientReport.fromJson(Map<String, dynamic> json) {
    return ClientReport(
      clientId: json['client_id'] as String,
      clientName: json['client_name'] as String,
      totalDays: (json['total_days'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      partnerCount: json['partner_count'] as int,
    );
  }
}

/// Modèle pour le rapport par partenaire
class PartnerReport {
  final String partnerId;
  final String partnerName;
  final String partnerEmail;
  final double totalDays; // Total en jours (peut inclure des 0.5)
  final double totalAmount;
  final int clientCount;

  PartnerReport({
    required this.partnerId,
    required this.partnerName,
    required this.partnerEmail,
    required this.totalDays,
    required this.totalAmount,
    required this.clientCount,
  });

  factory PartnerReport.fromJson(Map<String, dynamic> json) {
    return PartnerReport(
      partnerId: json['partner_id'] as String,
      partnerName: json['partner_name'] as String,
      partnerEmail: json['partner_email'] as String,
      totalDays: (json['total_days'] as num).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      clientCount: json['client_count'] as int,
    );
  }
}

/// Modèle pour un client autorisé avec son tarif
class AuthorizedClient {
  final String clientId;
  final String clientName;
  final double dailyRate;

  AuthorizedClient({
    required this.clientId,
    required this.clientName,
    required this.dailyRate,
  });

  factory AuthorizedClient.fromJson(Map<String, dynamic> json) {
    return AuthorizedClient(
      clientId: json['client_id']?.toString() ?? '',
      clientName: json['client_name']?.toString() ?? 'Client sans nom',
      dailyRate: (json['daily_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

