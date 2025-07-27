import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

// Import conditionnel pour éviter les erreurs sur les plateformes non-web
import 'device_detector_stub.dart' 
  if (dart.library.html) 'device_detector_web.dart';

/// Utilitaire pour détecter le type d'appareil
class DeviceDetector {
  
  /// Détermine si l'appareil est un mobile/smartphone
  static bool isMobileDevice() {
    if (!kIsWeb) {
      // Sur les plateformes natives, vérifier si c'est iOS ou Android
      return Platform.isIOS || Platform.isAndroid;
    }
    
    // Sur web, utiliser la détection JavaScript
    return isMobileWeb();
  }
  
  /// Détermine si l'appareil est un desktop/ordinateur
  static bool isDesktopDevice() {
    if (!kIsWeb) {
      // Sur les plateformes natives, desktop = macOS, Windows, Linux
      return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
    }
    
    // Sur web, l'inverse de mobile
    return !isMobileWeb();
  }
  
  /// Détermine si on doit utiliser l'interface iOS
  /// - iOS natif → oui
  /// - Web mobile → oui (interface iOS adaptée au tactile)
  /// - Web desktop → non (interface macOS adaptée au desktop)
  static bool shouldUseIOSInterface() {
    if (!kIsWeb) {
      // Sur les plateformes natives, utiliser iOS uniquement sur iOS
      return Platform.isIOS;
    }
    
    // Sur web, utiliser iOS pour les appareils mobiles
    return isMobileDevice();
  }
  
  /// Détermine si on doit utiliser l'interface macOS/Desktop
  /// - macOS natif → oui  
  /// - Web desktop → oui (interface desktop avec souris/clavier)
  /// - Web mobile → non (interface iOS tactile)
  static bool shouldUseMacOSInterface() {
    return !shouldUseIOSInterface();
  }
  
  /// Informations de debug sur l'appareil détecté
  static String getDeviceInfo() {
    if (!kIsWeb) {
      if (Platform.isIOS) return 'iOS natif';
      if (Platform.isAndroid) return 'Android natif';
      if (Platform.isMacOS) return 'macOS natif';
      if (Platform.isWindows) return 'Windows natif';
      if (Platform.isLinux) return 'Linux natif';
      return 'Platform natif inconnu';
    }
    
    return 'Web - ${isMobileDevice() ? 'Mobile' : 'Desktop'} - Interface: ${shouldUseIOSInterface() ? 'iOS' : 'macOS'}';
  }
} 