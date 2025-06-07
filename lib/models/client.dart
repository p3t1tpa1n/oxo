class Client {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String company;
  final String notes;
  final String status;
  final DateTime createdAt;

  Client({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.company,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      company: json['company'] ?? '',
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'actif',
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'company': company,
      'notes': notes,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 