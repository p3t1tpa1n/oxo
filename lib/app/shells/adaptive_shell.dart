// ============================================================================
// ADAPTIVE SHELL - OXO TIME SHEETS
// Sélecteur de shell selon la plateforme (Desktop vs Mobile)
// ============================================================================

import 'package:flutter/material.dart';
import '../../utils/device_detector.dart';
import 'desktop_shell.dart';
import 'mobile_shell.dart';

class AdaptiveShell extends StatelessWidget {
  final Widget? desktopChild;
  final String currentRoute;
  
  const AdaptiveShell({
    Key? key,
    this.desktopChild,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Détection de la plateforme
    if (DeviceDetector.shouldUseIOSInterface()) {
      // Sur iOS : utiliser le MobileShell avec tabs
      return const MobileShell();
    } else {
      // Sur Desktop : utiliser le DesktopShell avec sidebar
      return DesktopShell(
        currentRoute: currentRoute,
        child: desktopChild ?? Container(
          child: Center(
            child: Text('Page non trouvée pour: $currentRoute'),
          ),
        ),
      );
    }
  }
}


