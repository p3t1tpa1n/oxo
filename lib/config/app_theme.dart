// ============================================================================
// DESIGN SYSTEM - OXO TIME SHEETS
// Centralisation de toutes les couleurs, typographies et styles
// ============================================================================

import 'package:flutter/material.dart';

/// Thème global de l'application OXO
/// Utiliser `AppTheme.colors.primary` au lieu de définir des couleurs en dur
class AppTheme {
  // ══════════════════════════════════════════════════════════════════════════
  // COULEURS PRINCIPALES
  // ══════════════════════════════════════════════════════════════════════════
  
  static const AppColors colors = AppColors();
  static const AppTypography typography = AppTypography();
  static const AppSpacing spacing = AppSpacing();
  static const AppRadius radius = AppRadius();
  static const AppShadows shadows = AppShadows();
  
  // ══════════════════════════════════════════════════════════════════════════
  // MATERIAL THEME
  // ══════════════════════════════════════════════════════════════════════════
  
  static ThemeData get materialTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.primary,
      primary: colors.primary,
      secondary: colors.secondary,
      surface: colors.surface,
      error: colors.error,
    ),
    scaffoldBackgroundColor: colors.background,
    // Transitions de pages homogènes et fluides :
    // slide Cupertino sur iOS/Android, fondu discret sur desktop
    // (le zoom Material par défaut donne un rendu saccadé en fenêtre).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      // Look flat et pro : bordure fine plutôt qu'ombre portée
      elevation: 0,
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.medium),
        side: BorderSide(color: colors.border, width: 0.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius.small),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius.small),
      ),
      filled: true,
      fillColor: colors.inputBackground,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius.medium),
      ),
    ),
    dividerTheme: DividerThemeData(
      color: colors.border,
      thickness: 0.5,
      space: 1,
    ),
  );
  
  // ══════════════════════════════════════════════════════════════════════════
  // DARK THEME (pour mode sombre futur)
  // ══════════════════════════════════════════════════════════════════════════
  
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: colors.primary,
      secondary: colors.secondary,
      surface: const Color(0xFF1E1E1E),
      error: colors.error,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// COULEURS
// ══════════════════════════════════════════════════════════════════════════

class AppColors {
  const AppColors();
  
  // Couleurs primaires (bleu OXO)
  final Color primary = const Color(0xFF16283C);
  final Color primaryLight = const Color(0xFF2C4258);
  final Color primaryDark = const Color(0xFF0E1B2A);
  
  // Couleurs secondaires (cyan)
  final Color secondary = const Color(0xFF3E5C76);
  final Color secondaryLight = const Color(0xFF5C7A94);
  final Color secondaryDark = const Color(0xFF2B4256);
  
  // Couleurs d'état
  final Color success = const Color(0xFF2E7D5B);
  final Color warning = const Color(0xFFB07B2E);
  final Color error = const Color(0xFFB0413E);
  final Color info = const Color(0xFF3E5C76);
  
  // Couleurs de fond
  final Color background = const Color(0xFFF6F7F9);
  final Color surface = const Color(0xFFFFFFFF);
  final Color surfaceVariant = const Color(0xFFFBFCFD);
  
  // Couleurs de texte
  final Color textPrimary = const Color(0xFF1A2530);
  final Color textSecondary = const Color(0xFF64748B);
  final Color textDisabled = const Color(0xFFBDBDBD);
  final Color textOnPrimary = const Color(0xFFFFFFFF);
  
  // Couleurs de bordure
  final Color border = const Color(0xFFDCE1E8);
  final Color borderLight = const Color(0xFFF0F0F0);
  final Color borderDark = const Color(0xFFBDBDBD);
  
  // Couleurs d'état de ligne (Timesheet)
  final Color rowModified = const Color(0xFFE3F2FD); // Bleu clair
  final Color rowSaved = const Color(0xFFE8F5E9); // Vert clair
  final Color rowToday = const Color(0xFFFFF9E6); // Jaune très clair
  final Color rowWeekend = const Color(0xFFF6F7F9); // Gris clair
  
  // Couleurs de statut de mission
  final Color statusPending = const Color(0xFFB07B2E); // Orange
  final Color statusInProgress = const Color(0xFF3E5C76); // Bleu
  final Color statusCompleted = const Color(0xFF2E7D5B); // Vert
  final Color statusCancelled = const Color(0xFF9E9E9E); // Gris
  
  // Couleurs de progression
  final Color progressLow = const Color(0xFFB07B2E); // < 50%
  final Color progressMedium = const Color(0xFF3E5C76); // 50-79%
  final Color progressHigh = const Color(0xFF2E7D5B); // >= 80%
  
  // Sidebar (accent de sélection sur fond primary)
  final Color sidebarAccent = const Color(0xFF7FA3C4);

  // Couleurs d'input
  final Color inputBackground = const Color(0xFFFAFAFA);
  final Color inputBorder = const Color(0xFFDCE1E8);
  final Color inputFocused = const Color(0xFF16283C);
}

// ══════════════════════════════════════════════════════════════════════════
// TYPOGRAPHIE
// ══════════════════════════════════════════════════════════════════════════

class AppTypography {
  const AppTypography();
  
  // Titres
  TextStyle get h1 => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1A2530),
    letterSpacing: -0.5,
  );
  
  TextStyle get h2 => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Color(0xFF1A2530),
    letterSpacing: -0.25,
  );
  
  TextStyle get h3 => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1A2530),
  );
  
  TextStyle get h4 => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1A2530),
  );
  
  // Corps de texte
  TextStyle get bodyLarge => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1A2530),
    height: 1.5,
  );
  
  TextStyle get bodyMedium => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: Color(0xFF1A2530),
    height: 1.5,
  );
  
  TextStyle get bodySmall => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFF64748B),
    height: 1.4,
  );
  
  // Labels
  TextStyle get labelLarge => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1A2530),
    letterSpacing: 0.1,
  );
  
  TextStyle get labelMedium => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Color(0xFF64748B),
    letterSpacing: 0.5,
  );
  
  TextStyle get labelSmall => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: Color(0xFF64748B),
    letterSpacing: 0.5,
  );
  
  // Boutons
  TextStyle get button => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  // Caption
  TextStyle get caption => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: Color(0xFF64748B),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// ESPACEMENTS
// ══════════════════════════════════════════════════════════════════════════

class AppSpacing {
  const AppSpacing();
  
  // Espacements standards (système de 4px)
  final double xs = 4.0;
  final double sm = 8.0;
  final double md = 16.0;
  final double lg = 24.0;
  final double xl = 32.0;
  final double xxl = 48.0;
  
  // Espacements spécifiques
  final double cardPadding = 20.0;
  final double sectionPadding = 24.0;
  final double pagePadding = 32.0;
}

// ══════════════════════════════════════════════════════════════════════════
// RADIUS (ARRONDIS)
// ══════════════════════════════════════════════════════════════════════════

class AppRadius {
  const AppRadius();
  
  final double small = 8.0;
  final double medium = 12.0;
  final double large = 16.0;
  final double xlarge = 24.0;
  final double circle = 999.0;
}

// ══════════════════════════════════════════════════════════════════════════
// OMBRES
// ══════════════════════════════════════════════════════════════════════════

class AppShadows {
  const AppShadows();
  
  List<BoxShadow> get small => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ];
  
  List<BoxShadow> get large => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
}

// ══════════════════════════════════════════════════════════════════════════
// EXTENSIONS UTILES
// ══════════════════════════════════════════════════════════════════════════

extension ColorExtensions on Color {
  /// Retourne une couleur avec opacité
  Color withOpacityValue(double opacity) {
    return withOpacity(opacity);
  }
  
  /// Retourne une couleur plus claire
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
  
  /// Retourne une couleur plus foncée
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}



