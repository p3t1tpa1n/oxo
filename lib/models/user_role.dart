import 'package:flutter/foundation.dart';

class UserRole {
  final String value;
  const UserRole._internal(this.value);

  static const associe = UserRole._internal('associe');
  static const partenaire = UserRole._internal('partenaire');
  static const client = UserRole._internal('client');
  static const admin = UserRole._internal('admin');

  @override
  String toString() => value;
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is UserRole) {
      return value.toLowerCase() == other.value.toLowerCase();
    } else if (other is String) {
      return value.toLowerCase() == other.toLowerCase();
    }
    return false;
  }
  
  @override
  int get hashCode => value.toLowerCase().hashCode;

  static UserRole? fromString(String? roleStr) {
    if (roleStr == null) return null;
    
    // Conversion en minuscules pour ignorer la casse
    final role = roleStr.toLowerCase().trim();
    
    switch (role) {
      case 'associe': 
      case 'associé': 
        return associe;
      case 'partenaire': 
        return partenaire;
      case 'client': 
        debugPrint('UserRole.fromString: rôle client détecté, retournant l\'instance UserRole.client');
        return client;
      case 'admin':
      case 'administrator':
      case 'administrateur':  
        return admin;
      default: 
        debugPrint('UserRole.fromString: Rôle non reconnu: $roleStr');
        return null;
    }
  }
} 