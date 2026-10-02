import 'package:flutter/material.dart';

/// Spacing, radius, and sizing constants for VEGA AI UI.
abstract class AppDimensions {
  // Padding & Spacing
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Border Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusFull = 999.0;

  static const BorderRadius roundedSm = BorderRadius.all(Radius.circular(radiusSm));
  static const BorderRadius roundedMd = BorderRadius.all(Radius.circular(radiusMd));
  static const BorderRadius roundedLg = BorderRadius.all(Radius.circular(radiusLg));
  static const BorderRadius roundedFull = BorderRadius.all(Radius.circular(radiusFull));

  // Circular Assistant Orb Sizes
  static const double orbSizePhone = 180.0;
  static const double orbGlowSpread = 24.0;
  static const double orbWaveRingInitial = 190.0;
  static const double orbWaveRingMax = 260.0;

  // Icon Sizes
  static const double iconSm = 16.0;
  static const double iconMd = 24.0;
  static const double iconLg = 32.0;

  // Status Indicator Sizes
  static const double indicatorDot = 8.0;
}
