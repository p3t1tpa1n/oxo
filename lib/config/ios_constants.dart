/// Constantes iOS conformes aux Human Interface Guidelines
class IOSConstants {
  // Espacements standard iOS
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 20.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;
  static const double spacingXXXL = 40.0;

  // Marges standard
  static const double marginHorizontal = 16.0;
  static const double marginVertical = 20.0;
  static const double marginSection = 32.0;

  // Tailles des éléments UI
  static const double buttonHeight = 50.0;
  static const double buttonHeightSmall = 36.0;
  static const double inputHeight = 50.0;
  static const double listItemHeight = 44.0;
  static const double navigationBarHeight = 44.0;
  static const double tabBarHeight = 49.0;
  static const double statusBarHeight = 20.0;

  // Zone de toucher minimale (iOS HIG)
  static const double minimumTouchTarget = 44.0;

  // Rayons de bordure
  static const double radiusXS = 4.0;
  static const double radiusS = 6.0;
  static const double radiusM = 8.0;
  static const double radiusL = 10.0;
  static const double radiusXL = 12.0;
  static const double radiusXXL = 16.0;
  static const double radiusCard = 10.0;
  static const double radiusButton = 8.0;
  static const double radiusInput = 10.0;
  static const double radiusModal = 14.0;
  static const double radiusAppIcon = 22.0; // Pour 100x100pt
  static const double radiusAppIconLarge = 27.0; // Pour 120x120pt

  // Tailles de police iOS (en points)
  static const double fontSizeCaption = 11.0;
  static const double fontSizeCaption2 = 12.0;
  static const double fontSizeFootnote = 13.0;
  static const double fontSizeSubheadline = 15.0;
  static const double fontSizeCallout = 16.0;
  static const double fontSizeBody = 17.0;
  static const double fontSizeHeadline = 17.0;
  static const double fontSizeTitle3 = 20.0;
  static const double fontSizeTitle2 = 22.0;
  static const double fontSizeTitle1 = 28.0;
  static const double fontSizeLargeTitle = 34.0;

  // Poids de police iOS
  static const String fontWeightUltraLight = 'w100';
  static const String fontWeightThin = 'w200';
  static const String fontWeightLight = 'w300';
  static const String fontWeightRegular = 'w400';
  static const String fontWeightMedium = 'w500';
  static const String fontWeightSemibold = 'w600';
  static const String fontWeightBold = 'w700';
  static const String fontWeightHeavy = 'w800';
  static const String fontWeightBlack = 'w900';

  // Familles de police iOS
  static const String fontFamilySystem = '-apple-system';
  static const String fontFamilySFProText = '.SF Pro Text';
  static const String fontFamilySFProDisplay = '.SF Pro Display';
  static const String fontFamilySFMono = '.SF Mono';

  // Opacité et transparence
  static const double opacityDisabled = 0.3;
  static const double opacitySecondary = 0.6;
  static const double opacitySeparator = 0.33;
  static const double opacityOverlay = 0.4;
  static const double opacityModal = 0.25;

  // Ombres et élévation
  static const double shadowBlurRadius = 10.0;
  static const double shadowSpreadRadius = 0.0;
  static const double shadowOffsetY = 2.0;
  static const double shadowOpacity = 0.1;

  // Ombres spécifiques aux cartes
  static const double cardShadowBlurRadius = 8.0;
  static const double cardShadowOffsetY = 2.0;
  static const double cardShadowOpacity = 0.05;

  // Ombres pour les éléments flottants
  static const double floatingShadowBlurRadius = 20.0;
  static const double floatingShadowOffsetY = 8.0;
  static const double floatingShadowOpacity = 0.15;

  // Durées d'animation iOS
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationNormal = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  static const Duration animationDurationModal = Duration(milliseconds: 350);

  // Courbes d'animation iOS
  static const String easingDefault = 'ease-in-out';
  static const String easingEnter = 'ease-out';
  static const String easingExit = 'ease-in';

  // Tailles d'écran de référence iOS
  static const double iPhoneSEWidth = 375.0;
  static const double iPhoneSEHeight = 667.0;
  static const double iPhone11ProWidth = 414.0;
  static const double iPhone11ProHeight = 896.0;
  static const double iPhone12ProMaxWidth = 428.0;
  static const double iPhone12ProMaxHeight = 926.0;
  
  static const double iPadMiniWidth = 768.0;
  static const double iPadMiniHeight = 1024.0;
  static const double iPadProWidth = 1024.0;
  static const double iPadProHeight = 1366.0;

  // Breakpoints responsive
  static const double breakpointMobile = 480.0;
  static const double breakpointTablet = 768.0;
  static const double breakpointDesktop = 1024.0;

  // Safe Areas iOS
  static const double safeAreaTopRegular = 20.0;
  static const double safeAreaTopNotch = 44.0;
  static const double safeAreaBottom = 34.0;
  static const double safeAreaBottomHome = 0.0;

  // Navigation iOS
  static const double navigationBarTitleTopPadding = 6.0;
  static const double navigationBarLargeTitleTopPadding = 16.0;
  static const double navigationBarLargeTitleBottomPadding = 12.0;

  // Liste iOS
  static const double listSectionHeaderHeight = 35.0;
  static const double listSectionFooterHeight = 30.0;
  static const double listSeparatorHeight = 0.5;
  static const double listSeparatorIndent = 16.0;

  // Modal et Alert
  static const double modalMaxWidth = 270.0;
  static const double modalMinHeight = 180.0;
  static const double modalPadding = 16.0;
  static const double modalTitleBottomPadding = 8.0;
  static const double modalButtonHeight = 44.0;

  // Accessibilité
  static const double accessibilityMinTouchTarget = 44.0;
  static const double accessibilityPreferredFontSizeRatio = 1.0;

  // Configuration réseau
  static const Duration networkTimeoutDuration = Duration(seconds: 30);
  static const Duration cacheStaleTime = Duration(minutes: 5);

  // Validation
  static const int maxEmailLength = 254;
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxNameLength = 50;
  static const int maxMessageLength = 1000;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Images et médias
  static const int maxImageSizeBytes = 5 * 1024 * 1024; // 5MB
  static const double imageCompressionQuality = 0.8;
  static const int thumbnailSize = 150;

  /// Utilitaire pour obtenir la taille de police appropriée selon le contexte
  static double getFontSize(String textStyle) {
    switch (textStyle.toLowerCase()) {
      case 'largetitle':
        return fontSizeLargeTitle;
      case 'title1':
        return fontSizeTitle1;
      case 'title2':
        return fontSizeTitle2;
      case 'title3':
        return fontSizeTitle3;
      case 'headline':
        return fontSizeHeadline;
      case 'body':
        return fontSizeBody;
      case 'callout':
        return fontSizeCallout;
      case 'subheadline':
        return fontSizeSubheadline;
      case 'footnote':
        return fontSizeFootnote;
      case 'caption':
        return fontSizeCaption;
      case 'caption2':
        return fontSizeCaption2;
      default:
        return fontSizeBody;
    }
  }

  /// Utilitaire pour déterminer si l'écran est de taille mobile
  static bool isMobile(double width) {
    return width < breakpointTablet;
  }

  /// Utilitaire pour déterminer si l'écran est de taille tablette
  static bool isTablet(double width) {
    return width >= breakpointTablet && width < breakpointDesktop;
  }

  /// Utilitaire pour déterminer si l'écran est de taille desktop
  static bool isDesktop(double width) {
    return width >= breakpointDesktop;
  }

  /// Utilitaire pour obtenir l'espacement approprié selon la taille d'écran
  static double getResponsiveSpacing(double screenWidth, {
    double mobileSpacing = spacingM,
    double tabletSpacing = spacingL,
    double desktopSpacing = spacingXL,
  }) {
    if (isMobile(screenWidth)) return mobileSpacing;
    if (isTablet(screenWidth)) return tabletSpacing;
    return desktopSpacing;
  }

  /// Utilitaire pour obtenir la largeur maximale d'un conteneur
  static double getMaxContentWidth(double screenWidth) {
    if (isMobile(screenWidth)) return screenWidth - (marginHorizontal * 2);
    if (isTablet(screenWidth)) return 600.0;
    return 800.0;
  }
} 