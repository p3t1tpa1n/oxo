import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Design System iOS unifié avec les couleurs de marque
/// Toutes les couleurs et styles de l'application doivent utiliser cette classe
class IOSTheme {
  // COULEURS DE MARQUE PRINCIPALES
  static const Color primaryBlue = Color(0xFF1784AF);      // Bleu principal #1784af
  static const Color darkBlue = Color(0xFF122B35);         // Bleu foncé #122b35
  static const Color secondaryBlue = Color(0xFF5AC8FA);    // Bleu clair Apple
  
  // COULEURS SYSTÈME APPLE (conservées pour cohérence)
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemYellow = Color(0xFFFFCC00);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemTeal = Color(0xFF5AC8FA);
  static const Color systemIndigo = Color(0xFF5856D6);
  static const Color systemPurple = Color(0xFFAF52DE);
  static const Color systemPink = Color(0xFFFF2D92);
  
  // COULEURS DE FOND (Hiérarchie Apple)
  static const Color systemBackground = Color(0xFFFFFFFF);           // Fond principal
  static const Color secondarySystemBackground = Color(0xFFF2F2F7);  // Fond secondaire
  static const Color tertiarySystemBackground = Color(0xFFFFFFFF);   // Fond tertiaire
  static const Color systemGroupedBackground = Color(0xFFF2F2F7);    // Fond groupé
  static const Color secondarySystemGroupedBackground = Color(0xFFFFFFFF); // Fond groupé secondaire
  
  // COULEURS DE TEXTE (Hiérarchie Apple)
  static const Color labelPrimary = Color(0xFF000000);      // Texte principal
  static const Color labelSecondary = Color(0xFF3C3C43);    // Texte secondaire  
  static const Color labelTertiary = Color(0xFF3C3C4399);   // Texte tertiaire
  static const Color labelQuaternary = Color(0xFF3C3C4366); // Texte quaternaire
  
  // COULEURS GRISES (Système Apple)
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);
  
  // SÉPARATEURS
  static const Color separator = Color(0x543C3C43);
  static const Color opaqueSeparator = Color(0xFFC6C6C8);
  
  // COULEURS STATUT STANDARDISÉES
  static const Color successColor = systemGreen;
  static const Color warningColor = systemOrange;
  static const Color errorColor = systemRed;
  static const Color infoColor = primaryBlue;
  
  // COULEURS PRIORITÉ (Uniformes dans toute l'app)
  static const Color urgentColor = systemRed;
  static const Color highPriorityColor = systemOrange;
  static const Color mediumPriorityColor = primaryBlue;
  static const Color lowPriorityColor = systemGreen;
  
  // TYPOGRAPHIE STANDARDISÉE (SANS SOULIGNEMENT)
  static const TextStyle largeTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: labelPrimary,
    fontFamily: '.SF Pro Display',
    decoration: TextDecoration.none,
  );
  
  static const TextStyle title1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: labelPrimary,
    fontFamily: '.SF Pro Display',
    decoration: TextDecoration.none,
  );
  
  static const TextStyle title2 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: labelPrimary,
    fontFamily: '.SF Pro Display',
    decoration: TextDecoration.none,
  );
  
  static const TextStyle title3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: labelPrimary,
    fontFamily: '.SF Pro Display',
    decoration: TextDecoration.none,
  );
  
  static const TextStyle headline = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: labelPrimary,
    fontFamily: '.SF Pro Text',
    decoration: TextDecoration.none,
  );
  
  static const TextStyle body = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: labelPrimary,
    fontFamily: '.SF Pro Text',
    decoration: TextDecoration.none,
  );
  
  static const TextStyle callout = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: labelPrimary,
    fontFamily: '.SF Pro Text',
    decoration: TextDecoration.none,
  );
  
  static const TextStyle subheadline = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: labelPrimary,
    fontFamily: '.SF Pro Text',
    decoration: TextDecoration.none,
  );
  
  static const TextStyle footnote = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: labelSecondary,
    fontFamily: '.SF Pro Text',
    decoration: TextDecoration.none,
  );
  
  static const TextStyle caption1 = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: labelSecondary,
    fontFamily: '.SF Pro Text',
    decoration: TextDecoration.none,
  );
  
  static const TextStyle caption2 = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: labelSecondary,
    fontFamily: '.SF Pro Text',
    decoration: TextDecoration.none,
  );

  // THÈME CUPERTINO UNIFIÉ
  static final CupertinoThemeData cupertinoTheme = CupertinoThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: systemGroupedBackground,
    barBackgroundColor: systemBackground,
    textTheme: const CupertinoTextThemeData(
      primaryColor: labelPrimary,
      textStyle: body,
      navTitleTextStyle: headline,
      navLargeTitleTextStyle: largeTitle,
      actionTextStyle: TextStyle(
        color: primaryBlue,
        fontSize: 17,
        fontWeight: FontWeight.w400,
        fontFamily: '.SF Pro Text',
        decoration: TextDecoration.none,
      ),
      tabLabelTextStyle: TextStyle(
        color: labelSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        fontFamily: '.SF Pro Text',
        decoration: TextDecoration.none,
      ),
    ),
  );
  
  // STYLES DE CARTES STANDARDISÉS
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: systemBackground,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get groupedCardDecoration => BoxDecoration(
    color: secondarySystemGroupedBackground,
    borderRadius: BorderRadius.circular(10),
  );
  
  // STYLES DE BOUTONS STANDARDISÉS
  static BoxDecoration primaryButtonDecoration(bool isPressed) => BoxDecoration(
    color: isPressed ? primaryBlue.withValues(alpha: 0.8) : primaryBlue,
    borderRadius: BorderRadius.circular(8),
  );
  
  static BoxDecoration secondaryButtonDecoration(bool isPressed) => BoxDecoration(
    color: isPressed ? systemGray6 : systemGray5,
    borderRadius: BorderRadius.circular(8),
  );
  
  // MÉTHODES UTILITAIRES POUR LES COULEURS
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent': return urgentColor;
      case 'high': return highPriorityColor;
      case 'medium': return mediumPriorityColor;
      case 'low': return lowPriorityColor;
      default: return mediumPriorityColor;
    }
  }
  
  static String getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent': return 'URGENT';
      case 'high': return 'Haute';
      case 'medium': return 'Moyenne';
      case 'low': return 'Basse';
      default: return 'Moyenne';
    }
  }
  
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done': 
      case 'completed': 
      case 'success': return successColor;
      case 'in_progress': 
      case 'pending': return warningColor;
      case 'error': 
      case 'failed': return errorColor;
      default: return infoColor;
    }
  }

  // THÈME MATERIAL POUR COMPATIBILITÉ
  static final ThemeData materialTheme = ThemeData(
    primarySwatch: createMaterialColor(primaryBlue),
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: systemGroupedBackground,
    cardColor: systemBackground,
    dividerColor: separator,
    textTheme: const TextTheme(
      headlineLarge: largeTitle,
      headlineMedium: title1,
      headlineSmall: title2,
      titleLarge: title3,
      titleMedium: headline,
      bodyLarge: body,
      bodyMedium: callout,
      bodySmall: footnote,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: systemBackground,
      foregroundColor: labelPrimary,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: systemBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.pressed)) {
            return primaryBlue.withValues(alpha: 0.8);
          }
          return primaryBlue;
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
  );

  // CRÉER UN MATERIALSWATCH À PARTIR D'UNE COULEUR
  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

/// Extension pour faciliter l'usage des couleurs de statut
extension StatusColorExtension on String {
  Color get statusColor => IOSTheme.getStatusColor(this);
  Color get priorityColor => IOSTheme.getPriorityColor(this);
  String get priorityLabel => IOSTheme.getPriorityLabel(this);
} 