// ============================================================================
// MODÈLE: Mission (avec contexte Société + Groupe)
// ============================================================================

class Mission {
  final String id;
  final String title;
  final int? companyId;
  final String? companyName;
  final String? companyCity;
  final int? groupId;
  final String? groupName;
  final String? groupSector;
  final String? partnerId;
  final String? partnerEmail;
  final String? partnerFirstName;
  final String? partnerLastName;
  final String? assignedTo; // ID du partenaire assigné
  final String? assignedToFirstName;
  final String? assignedToLastName;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String? progressStatus;
  final double? budget;
  final double? dailyRate;
  final double? monthlyCap;       // Plafond mensuel
  final double? referralFee;      // Commission apporteur
  final String? referralFeeType;  // 'fixed' ou 'percentage'
  final String? currency;         // EUR, USD, GBP, CHF
  final double? estimatedDays;
  final double? workedDays;
  final double? completionPercentage;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Mission({
    required this.id,
    required this.title,
    this.companyId,
    this.companyName,
    this.companyCity,
    this.groupId,
    this.groupName,
    this.groupSector,
    this.partnerId,
    this.partnerEmail,
    this.partnerFirstName,
    this.partnerLastName,
    this.assignedTo,
    this.assignedToFirstName,
    this.assignedToLastName,
    required this.startDate,
    this.endDate,
    required this.status,
    this.progressStatus,
    this.budget,
    this.dailyRate,
    this.monthlyCap,
    this.referralFee,
    this.referralFeeType,
    this.currency,
    this.estimatedDays,
    this.workedDays,
    this.completionPercentage,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: (json['id'] ?? json['mission_id'])?.toString() ?? '',
      title: (json['title'] ?? json['mission_title'])?.toString() ?? '',
      companyId: json['company_id'] as int?,
      companyName: json['company_name'] as String?,
      companyCity: json['city'] as String?,
      groupId: json['group_id'] as int?,
      groupName: json['group_name'] as String?,
      groupSector: json['group_sector'] as String?,
      partnerId: json['partner_id']?.toString(),
      partnerEmail: json['partner_email'] as String?,
      partnerFirstName: json['partner_first_name'] as String?,
      partnerLastName: json['partner_last_name'] as String?,
      assignedTo: json['assigned_to']?.toString(),
      assignedToFirstName: json['assigned_to_first_name'] as String?,
      assignedToLastName: json['assigned_to_last_name'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'] as String) 
          : null,
      status: json['status']?.toString() ?? 'draft',
      progressStatus: json['progress_status'] as String?,
      budget: json['budget'] != null 
          ? (json['budget'] as num).toDouble() 
          : null,
      dailyRate: json['daily_rate'] != null 
          ? (json['daily_rate'] as num).toDouble() 
          : null,
      monthlyCap: json['monthly_cap'] != null 
          ? (json['monthly_cap'] as num).toDouble() 
          : null,
      referralFee: json['referral_fee'] != null 
          ? (json['referral_fee'] as num).toDouble() 
          : null,
      referralFeeType: json['referral_fee_type'] as String?,
      currency: json['currency'] as String? ?? 'EUR',
      estimatedDays: json['estimated_days'] != null 
          ? (json['estimated_days'] as num).toDouble() 
          : null,
      workedDays: json['worked_days'] != null 
          ? (json['worked_days'] as num).toDouble() 
          : null,
      completionPercentage: json['completion_percentage'] != null 
          ? (json['completion_percentage'] as num).toDouble() 
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company_id': companyId,
      'partner_id': partnerId,
      'assigned_to': assignedTo,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'status': status,
      'progress_status': progressStatus,
      'budget': budget,
      'daily_rate': dailyRate,
      'monthly_cap': monthlyCap,
      'referral_fee': referralFee,
      'referral_fee_type': referralFeeType,
      'currency': currency,
      'estimated_days': estimatedDays,
      'worked_days': workedDays,
      'completion_percentage': completionPercentage,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Mission copyWith({
    String? id,
    String? title,
    int? companyId,
    String? companyName,
    String? companyCity,
    int? groupId,
    String? groupName,
    String? groupSector,
    String? partnerId,
    String? partnerEmail,
    String? partnerFirstName,
    String? partnerLastName,
    String? assignedTo,
    String? assignedToFirstName,
    String? assignedToLastName,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? progressStatus,
    double? budget,
    double? dailyRate,
    double? monthlyCap,
    double? referralFee,
    String? referralFeeType,
    String? currency,
    double? estimatedDays,
    double? workedDays,
    double? completionPercentage,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Mission(
      id: id ?? this.id,
      title: title ?? this.title,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyCity: companyCity ?? this.companyCity,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupSector: groupSector ?? this.groupSector,
      partnerId: partnerId ?? this.partnerId,
      partnerEmail: partnerEmail ?? this.partnerEmail,
      partnerFirstName: partnerFirstName ?? this.partnerFirstName,
      partnerLastName: partnerLastName ?? this.partnerLastName,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToFirstName: assignedToFirstName ?? this.assignedToFirstName,
      assignedToLastName: assignedToLastName ?? this.assignedToLastName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      progressStatus: progressStatus ?? this.progressStatus,
      budget: budget ?? this.budget,
      dailyRate: dailyRate ?? this.dailyRate,
      monthlyCap: monthlyCap ?? this.monthlyCap,
      referralFee: referralFee ?? this.referralFee,
      referralFeeType: referralFeeType ?? this.referralFeeType,
      currency: currency ?? this.currency,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      workedDays: workedDays ?? this.workedDays,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Affichage pour dropdown: "Titre - Société (Groupe)"
  String get displayName {
    final parts = <String>[title];
    if (companyName != null) {
      parts.add(companyName!);
    }
    if (groupName != null) {
      parts.add('($groupName)');
    }
    return parts.join(' - ');
  }

  /// Affichage court: "Titre - Société"
  String get shortDisplayName {
    if (companyName != null) {
      return '$title - $companyName';
    }
    return title;
  }

  /// Nom complet du partenaire
  String? get partnerFullName {
    if (partnerFirstName != null && partnerLastName != null) {
      return '$partnerFirstName $partnerLastName';
    }
    return partnerEmail;
  }

  /// Est-ce que la mission est active (disponible pour saisie de temps)
  bool get isActive {
    final now = DateTime.now();
    return (status == 'in_progress' || status == 'pending' || status == 'accepted') && 
           startDate.isBefore(now.add(const Duration(days: 1))) &&
           (endDate == null || endDate!.isAfter(now.subtract(const Duration(days: 1))));
  }

  /// Est-ce que la mission n'est assignée à personne
  bool get isUnassigned {
    return (assignedTo == null || assignedTo!.isEmpty) && 
           (partnerId == null || partnerId!.isEmpty);
  }

  /// Nom complet du partenaire assigné
  String? get assignedToFullName {
    if (assignedToFirstName != null && assignedToLastName != null) {
      return '$assignedToFirstName $assignedToLastName';
    }
    return null;
  }

  /// Formater le TJM avec devise
  String get formattedDailyRate {
    if (dailyRate == null) return '-';
    final currencySymbol = _getCurrencySymbol(currency ?? 'EUR');
    return '${dailyRate!.toStringAsFixed(0)} $currencySymbol/jour';
  }

  /// Formater le plafond mensuel
  String get formattedMonthlyCap {
    if (monthlyCap == null) return '-';
    final currencySymbol = _getCurrencySymbol(currency ?? 'EUR');
    return '${monthlyCap!.toStringAsFixed(0)} $currencySymbol/mois';
  }

  /// Formater la commission apporteur
  String get formattedReferralFee {
    if (referralFee == null) return '-';
    if (referralFeeType == 'percentage') {
      return '${referralFee!.toStringAsFixed(1)}%';
    }
    final currencySymbol = _getCurrencySymbol(currency ?? 'EUR');
    return '${referralFee!.toStringAsFixed(0)} $currencySymbol';
  }

  /// Obtenir le symbole de devise
  static String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'EUR': return '€';
      case 'USD': return '\$';
      case 'GBP': return '£';
      case 'CHF': return 'CHF';
      default: return '€';
    }
  }

  /// Vérifier la cohérence du pricing (TJM vs plafond mensuel)
  bool get isPricingCoherent {
    if (dailyRate == null || monthlyCap == null) return true;
    // Avertissement si TJM > plafond/20 jours ouvrés
    return dailyRate! <= (monthlyCap! / 20);
  }

  @override
  String toString() => 'Mission(id: $id, title: $title, company: $companyName, group: $groupName)';
}






