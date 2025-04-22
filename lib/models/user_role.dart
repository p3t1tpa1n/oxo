class UserRole {
  final String value;
  const UserRole._internal(this.value);

  static const associe = UserRole._internal('associe');
  static const partenaire = UserRole._internal('partenaire');
  static const client = UserRole._internal('client');
  static const admin = UserRole._internal('admin');

  @override
  String toString() => value;

  static UserRole? fromString(String? roleStr) {
    if (roleStr == null) return null;
    
    switch (roleStr) {
      case 'associe': return associe;
      case 'partenaire': return partenaire;
      case 'client': return client;
      case 'admin': return admin;
      default: return null;
    }
  }
} 