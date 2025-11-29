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
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String? progressStatus;
  final double? budget;
  final double? dailyRate;
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
    required this.startDate,
    this.endDate,
    required this.status,
    this.progressStatus,
    this.budget,
    this.dailyRate,
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
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'company_id': companyId,
      'partner_id': partnerId,
      'start_date': startDate.toIso8601String().split('T')[0],
      'end_date': endDate?.toIso8601String().split('T')[0],
      'status': status,
      'progress_status': progressStatus,
      'budget': budget,
      'daily_rate': dailyRate,
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
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? progressStatus,
    double? budget,
    double? dailyRate,
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
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      progressStatus: progressStatus ?? this.progressStatus,
      budget: budget ?? this.budget,
      dailyRate: dailyRate ?? this.dailyRate,
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
    return status == 'in_progress' && 
           startDate.isBefore(now.add(const Duration(days: 1))) &&
           (endDate == null || endDate!.isAfter(now.subtract(const Duration(days: 1))));
  }

  @override
  String toString() => 'Mission(id: $id, title: $title, company: $companyName, group: $groupName)';
}






