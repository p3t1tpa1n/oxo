// ============================================================================
// MODÈLE: Company (Société d'exploitation)
// ============================================================================

class Company {
  final int id;
  final String name;
  final int? groupId;
  final String? groupName; // Depuis company_with_group
  final String? groupSector; // Depuis company_with_group
  final String? city;
  final String? postalCode;
  final String? sector;
  final double? ownershipShare;
  final String? siret;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final bool active;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.name,
    this.groupId,
    this.groupName,
    this.groupSector,
    this.city,
    this.postalCode,
    this.sector,
    this.ownershipShare,
    this.siret,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    required this.active,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: (json['id'] ?? json['company_id']) as int,
      name: (json['name'] ?? json['company_name']) as String,
      groupId: json['group_id'] as int?,
      groupName: json['group_name'] as String?,
      groupSector: json['group_sector'] as String?,
      city: json['city'] as String?,
      postalCode: json['postal_code'] as String?,
      sector: (json['sector'] ?? json['company_sector']) as String?,
      ownershipShare: json['ownership_share'] != null 
          ? (json['ownership_share'] as num).toDouble() 
          : null,
      siret: json['siret'] as String?,
      contactName: json['contact_name'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      active: (json['active'] ?? json['company_active']) as bool? ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'group_id': groupId,
      'city': city,
      'postal_code': postalCode,
      'sector': sector,
      'ownership_share': ownershipShare,
      'siret': siret,
      'contact_name': contactName,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'active': active,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Company copyWith({
    int? id,
    String? name,
    int? groupId,
    String? groupName,
    String? groupSector,
    String? city,
    String? postalCode,
    String? sector,
    double? ownershipShare,
    String? siret,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
    bool? active,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupSector: groupSector ?? this.groupSector,
      city: city ?? this.city,
      postalCode: postalCode ?? this.postalCode,
      sector: sector ?? this.sector,
      ownershipShare: ownershipShare ?? this.ownershipShare,
      siret: siret ?? this.siret,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      active: active ?? this.active,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get displayName {
    if (groupName != null) {
      return '$name ($groupName)';
    }
    return name;
  }

  String get displayLocation {
    if (city != null) {
      return city!;
    }
    return '';
  }

  @override
  String toString() => 'Company(id: $id, name: $name, group: $groupName, city: $city)';
}
