// ============================================================================
// MODÈLE: InvestorGroup (Groupe d'investissement)
// ============================================================================

class InvestorGroup {
  final int id;
  final String name;
  final String? sector;
  final String? country;
  final String? contactMain;
  final String? phone;
  final String? website;
  final String? notes;
  final String? logoUrl;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  InvestorGroup({
    required this.id,
    required this.name,
    this.sector,
    this.country,
    this.contactMain,
    this.phone,
    this.website,
    this.notes,
    this.logoUrl,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory InvestorGroup.fromJson(Map<String, dynamic> json) {
    return InvestorGroup(
      id: json['id'] as int,
      name: json['name'] as String,
      sector: json['sector'] as String?,
      country: json['country'] as String?,
      contactMain: json['contact_main'] as String?,
      phone: json['phone'] as String?,
      website: json['website'] as String?,
      notes: json['notes'] as String?,
      logoUrl: json['logo_url'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sector': sector,
      'country': country,
      'contact_main': contactMain,
      'phone': phone,
      'website': website,
      'notes': notes,
      'logo_url': logoUrl,
      'active': active,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  InvestorGroup copyWith({
    int? id,
    String? name,
    String? sector,
    String? country,
    String? contactMain,
    String? phone,
    String? website,
    String? notes,
    String? logoUrl,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InvestorGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      sector: sector ?? this.sector,
      country: country ?? this.country,
      contactMain: contactMain ?? this.contactMain,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      logoUrl: logoUrl ?? this.logoUrl,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'InvestorGroup(id: $id, name: $name, sector: $sector)';
}






