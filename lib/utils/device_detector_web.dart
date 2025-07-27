import 'dart:html' as html;

/// Implémentation web pour la détection d'appareil mobile
bool isMobileWeb() {
  final userAgent = html.window.navigator.userAgent.toLowerCase();
  
  // Liste des patterns pour détecter les appareils mobiles
  final mobilePatterns = [
    'mobile',
    'android',
    'iphone', 
    'ipad',
    'ipod',
    'blackberry',
    'windows phone',
    'webos',
    'opera mini',
    'mobi',
    'phone',
    'tablet'
  ];
  
  // Vérifier si l'user agent contient un pattern mobile
  for (final pattern in mobilePatterns) {
    if (userAgent.contains(pattern)) {
      return true;
    }
  }
  
  // Vérification supplémentaire avec les propriétés du navigateur
  try {
    // Vérifier la taille d'écran (mobile généralement < 768px)
    final screenWidth = html.window.screen?.width ?? 1920;
    if (screenWidth < 768) {
      return true;
    }
    
    // Vérifier le support tactile
    final hasTouchScreen = (html.window.navigator.maxTouchPoints ?? 0) > 0;
    if (hasTouchScreen && screenWidth < 1024) {
      return true;
    }
  } catch (e) {
    // En cas d'erreur, fallback sur l'user agent
  }
  
  return false;
} 