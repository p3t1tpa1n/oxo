// ============================================================================
// PREFERENCES SERVICE - OXO TIME SHEETS
// Gestion centralisée des préférences utilisateur (thème, notifications, etc.)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service pour gérer les préférences utilisateur
/// Utilise SharedPreferences pour la persistance
class PreferencesService {
  PreferencesService._();
  
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyNotificationsEnabled = 'notifications_enabled';
  static const String _keyEmailNotifications = 'email_notifications';
  static const String _keyPushNotifications = 'push_notifications';
  static const String _keyLanguage = 'language';
  static const String _keyFirstLaunch = 'first_launch';
  static const String _keyDensity = 'density';
  
  // ══════════════════════════════════════════════════════════════════════════
  // THÈME
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Récupère le mode de thème sauvegardé
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_keyThemeMode);
    
    if (themeModeString == null) {
      return ThemeMode.system; // Par défaut, suivre le système
    }
    
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  /// Sauvegarde le mode de thème
  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeString;
    
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
        modeString = 'system';
        break;
    }
    
    await prefs.setString(_keyThemeMode, modeString);
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Vérifie si les notifications sont activées
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true; // Par défaut activées
  }
  
  /// Active ou désactive les notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }
  
  /// Vérifie si les notifications email sont activées
  static Future<bool> areEmailNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyEmailNotifications) ?? true;
  }
  
  /// Active ou désactive les notifications email
  static Future<void> setEmailNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEmailNotifications, enabled);
  }
  
  /// Vérifie si les notifications push sont activées
  static Future<bool> arePushNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyPushNotifications) ?? true;
  }
  
  /// Active ou désactive les notifications push
  static Future<void> setPushNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPushNotifications, enabled);
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // LANGUE
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Récupère la langue préférée
  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLanguage) ?? 'fr'; // Par défaut français
  }
  
  /// Sauvegarde la langue préférée
  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLanguage, languageCode);
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // PREMIER LANCEMENT
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Vérifie si c'est le premier lancement de l'application
  static Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFirstLaunch) ?? true;
  }
  
  /// Marque que l'application a déjà été lancée
  static Future<void> setFirstLaunchCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstLaunch, false);
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // DENSITÉ
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Récupère la densité préférée (compact ou regular)
  static Future<String> getDensity() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDensity) ?? 'regular'; // Par défaut regular
  }
  
  /// Sauvegarde la densité préférée
  static Future<void> setDensity(String density) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDensity, density);
  }
  
  // ══════════════════════════════════════════════════════════════════════════
  // MÉTHODES UTILITAIRES
  // ══════════════════════════════════════════════════════════════════════════
  
  /// Réinitialise toutes les préférences
  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
  
  /// Récupère toutes les préférences sous forme de Map
  static Future<Map<String, dynamic>> getAllPreferences() async {
    return {
      'theme_mode': await getThemeMode(),
      'notifications_enabled': await areNotificationsEnabled(),
      'email_notifications': await areEmailNotificationsEnabled(),
      'push_notifications': await arePushNotificationsEnabled(),
      'language': await getLanguage(),
      'first_launch': await isFirstLaunch(),
    };
  }
}
