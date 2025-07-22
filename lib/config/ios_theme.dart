import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IOSTheme {
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color secondaryBlue = Color(0xFF5AC8FA);
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);
  
  static const Color labelPrimary = Color(0xFF000000);
  static const Color labelSecondary = Color(0xFF3C3C43);
  static const Color labelTertiary = Color(0xFF3C3C43);
  
  static const Color systemBackground = Color(0xFFFFFFFF);
  static const Color secondarySystemBackground = Color(0xFFF2F2F7);
  static const Color tertiarySystemBackground = Color(0xFFFFFFFF);
  
  static const Color systemGroupedBackground = Color(0xFFF2F2F7);
  static const Color secondarySystemGroupedBackground = Color(0xFFFFFFFF);
  
  static const Color separator = Color(0x543C3C43);
  static const Color opaqueSeparator = Color(0xFFC6C6C8);
  
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemYellow = Color(0xFFFFCC00);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemTeal = Color(0xFF5AC8FA);
  static const Color systemIndigo = Color(0xFF5856D6);
  static const Color systemPurple = Color(0xFFAF52DE);
  static const Color systemPink = Color(0xFFFF2D92);

  static final CupertinoThemeData cupertinoTheme = CupertinoThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: systemBackground,
    barBackgroundColor: systemBackground,
    textTheme: const CupertinoTextThemeData(
      primaryColor: labelPrimary,
      textStyle: TextStyle(
        color: labelPrimary,
        fontSize: 17,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w400,
      ),
      navTitleTextStyle: TextStyle(
        color: labelPrimary,
        fontSize: 17,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w600,
      ),
      navLargeTitleTextStyle: TextStyle(
        color: labelPrimary,
        fontSize: 34,
        fontFamily: '.SF Pro Display',
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  static final ThemeData materialTheme = ThemeData(
    platform: TargetPlatform.iOS,
    primaryColor: primaryBlue,
    primarySwatch: createMaterialColor(primaryBlue),
    scaffoldBackgroundColor: systemBackground,
    cardColor: secondarySystemBackground,
    dividerColor: separator,
    
    // AppBar theme
    appBarTheme: const AppBarTheme(
      backgroundColor: systemBackground,
      foregroundColor: labelPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: labelPrimary,
        fontSize: 17,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    ),
    
    // Card theme
    cardTheme: CardTheme(
      color: secondarySystemBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    
    // Button themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 17,
          fontFamily: '.SF Pro Text',
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        textStyle: const TextStyle(
          fontSize: 17,
          fontFamily: '.SF Pro Text',
          fontWeight: FontWeight.w400,
        ),
      ),
    ),
    
    // Input decoration theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: tertiarySystemBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: systemGray4),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: systemGray4),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      labelStyle: const TextStyle(
        color: labelSecondary,
        fontSize: 17,
        fontFamily: '.SF Pro Text',
      ),
      hintStyle: const TextStyle(
        color: systemGray,
        fontSize: 17,
        fontFamily: '.SF Pro Text',
      ),
    ),
    
    // List tile theme
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      iconColor: systemGray,
      textColor: labelPrimary,
      titleTextStyle: TextStyle(
        color: labelPrimary,
        fontSize: 17,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w400,
      ),
      subtitleTextStyle: TextStyle(
        color: labelSecondary,
        fontSize: 15,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // Text theme
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: labelPrimary,
        fontSize: 34,
        fontFamily: '.SF Pro Display',
        fontWeight: FontWeight.w700,
      ),
      displayMedium: TextStyle(
        color: labelPrimary,
        fontSize: 28,
        fontFamily: '.SF Pro Display',
        fontWeight: FontWeight.w700,
      ),
      displaySmall: TextStyle(
        color: labelPrimary,
        fontSize: 22,
        fontFamily: '.SF Pro Display',
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: TextStyle(
        color: labelPrimary,
        fontSize: 20,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        color: labelPrimary,
        fontSize: 17,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        color: labelPrimary,
        fontSize: 16,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(
        color: labelPrimary,
        fontSize: 17,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: TextStyle(
        color: labelPrimary,
        fontSize: 15,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w400,
      ),
      bodySmall: TextStyle(
        color: labelSecondary,
        fontSize: 13,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w400,
      ),
      labelLarge: TextStyle(
        color: labelPrimary,
        fontSize: 17,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w600,
      ),
      labelMedium: TextStyle(
        color: labelSecondary,
        fontSize: 15,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w400,
      ),
      labelSmall: TextStyle(
        color: labelTertiary,
        fontSize: 13,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // Icon theme
    iconTheme: const IconThemeData(
      color: systemGray,
      size: 24,
    ),
    
    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: systemBackground,
      selectedItemColor: primaryBlue,
      unselectedItemColor: systemGray,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(
        fontSize: 10,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w400,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 10,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // Tab bar theme
    tabBarTheme: const TabBarTheme(
      labelColor: primaryBlue,
      unselectedLabelColor: systemGray,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: primaryBlue, width: 2),
      ),
      labelStyle: TextStyle(
        fontSize: 17,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 17,
        fontFamily: '.SF Pro Text',
        fontWeight: FontWeight.w400,
      ),
    ),
    
    // Switch theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith<Color>((states) {
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.selected)) {
          return primaryBlue;
        }
        return systemGray3;
      }),
    ),
    
    // Slider theme
    sliderTheme: const SliderThemeData(
      activeTrackColor: primaryBlue,
      inactiveTrackColor: systemGray4,
      thumbColor: Colors.white,
      overlayColor: Color(0x1F007AFF),
    ),
    
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: secondaryBlue,
      surface: systemBackground,
      error: systemRed,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: labelPrimary,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
  );

  static MaterialColor createMaterialColor(Color color) {
    final List<double> strengths = <double>[.05];
    final Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    
    for (final strength in strengths) {
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