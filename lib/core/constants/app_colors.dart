import 'package:flutter/material.dart';

/// Design tokens and color palette for VEGA AI.
///
/// Features a futuristic JARVIS-inspired aesthetic with vibrant primary pink,
/// calming lavender, and clean high-contrast neutral surfaces.
abstract class AppColors {
  // Brand Colors
  static const Color primaryPink = Color(0xFFF73B9A);
  static const Color primaryPinkDark = Color(0xFFD41B79);
  static const Color primaryPinkLight = Color(0xFFFF77BD);

  static const Color lavender = Color(0xFFD9C6FD);
  static const Color lavenderLight = Color(0xFFEDE2FE);
  static const Color lavenderDark = Color(0xFF9E7DE8);

  // Backgrounds & Surfaces (Light)
  static const Color backgroundLight = Color(0xFFFAF7FD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightSubtle = Color(0xFFF3EDF9);
  static const Color cardBorderLight = Color(0xFFE9DEFA);

  // Backgrounds & Surfaces (Dark / Sci-Fi JARVIS Mode)
  static const Color backgroundDark = Color(0xFF0F0B18);
  static const Color surfaceDark = Color(0xFF181326);
  static const Color surfaceDarkSubtle = Color(0xFF231B36);
  static const Color cardBorderDark = Color(0xFF2E2447);

  // Status & Connectivity Colors
  static const Color onlineGreen = Color(0xFF00E676);
  static const Color offlineOrange = Color(0xFFFF9100);
  static const Color listeningPulse = Color(0xFFF73B9A);
  static const Color processingGlow = Color(0xFFB388FF);
  static const Color speakingWave = Color(0xFF651FFF);
  static const Color idleGlow = Color(0xFF9E7DE8);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF1E172B);
  static const Color textSecondaryLight = Color(0xFF6E6382);
  static const Color textPrimaryDark = Color(0xFFF4F0FB);
  static const Color textSecondaryDark = Color(0xFFAFA5C3);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryPink, lavenderDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient orbActiveGradient = LinearGradient(
    colors: [primaryPink, lavender],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientLight = LinearGradient(
    colors: [Color(0xCCFFFFFF), Color(0x99F5EFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradientDark = LinearGradient(
    colors: [Color(0xCC1F1832), Color(0x99140F21)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
