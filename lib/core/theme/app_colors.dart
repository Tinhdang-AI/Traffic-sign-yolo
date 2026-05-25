import 'package:flutter/material.dart';

/// SENTINEL AI — Design System Colors
/// Matches the Stitch "Safety-First Navigation" design system.
class AppColors {
  AppColors._();

  // ── Surfaces ────────────────────────────────────────────────────────────────
  static const Color background            = Color(0xFF131313);
  static const Color surfaceDim            = Color(0xFF131313);
  static const Color surfaceContainerLowest= Color(0xFF0E0E0E);
  static const Color surfaceContainerLow  = Color(0xFF1C1B1B);
  static const Color surfaceContainer     = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceBright        = Color(0xFF393939);
  static const Color surfaceTint          = Color(0xFFB2C5FF);

  // ── On-Surface ──────────────────────────────────────────────────────────────
  static const Color onSurface        = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFC3C6D6);
  static const Color inverseSurface   = Color(0xFFE5E2E1);
  static const Color inverseOnSurface = Color(0xFF313030);

  // ── Primary — Safety Blue ────────────────────────────────────────────────────
  static const Color primary              = Color(0xFFB2C5FF);
  static const Color primaryContainer     = Color(0xFF0056D2);
  static const Color onPrimary            = Color(0xFF002C72);
  static const Color onPrimaryContainer   = Color(0xFFCCD8FF);
  static const Color inversePrimary       = Color(0xFF0056D2);
  static const Color primaryFixed         = Color(0xFFDAE2FF);
  static const Color primaryFixedDim      = Color(0xFFB2C5FF);
  static const Color onPrimaryFixed       = Color(0xFF001847);
  static const Color onPrimaryFixedVariant= Color(0xFF0040A1);

  // ── Secondary — Alert Orange ─────────────────────────────────────────────────
  static const Color secondary            = Color(0xFFFFB77D);
  static const Color secondaryContainer   = Color(0xFFFD8B00);
  static const Color onSecondary          = Color(0xFF4D2600);
  static const Color onSecondaryContainer = Color(0xFF603100);
  static const Color secondaryFixed       = Color(0xFFFFDCC3);
  static const Color secondaryFixedDim    = Color(0xFFFFB77D);

  // ── Tertiary — Critical Red ──────────────────────────────────────────────────
  static const Color tertiary            = Color(0xFFFFB3B1);
  static const Color tertiaryContainer   = Color(0xFFBB152C);
  static const Color onTertiary          = Color(0xFF680011);
  static const Color onTertiaryContainer = Color(0xFFFFCDCB);
  static const Color tertiaryFixed       = Color(0xFFFFDAD8);
  static const Color tertiaryFixedDim    = Color(0xFFFFB3B1);

  // ── Error ────────────────────────────────────────────────────────────────────
  static const Color error            = Color(0xFFFFB4AB);
  static const Color errorContainer   = Color(0xFF93000A);
  static const Color onError          = Color(0xFF690005);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // ── Outline ──────────────────────────────────────────────────────────────────
  static const Color outline        = Color(0xFF8D90A0);
  static const Color outlineVariant = Color(0xFF424654);

  // ── Semantic helpers ─────────────────────────────────────────────────────────
  static const Color safetyBlue  = primaryContainer;    // #0056D2
  static const Color alertOrange = secondaryContainer;  // #FD8B00
  static const Color criticalRed = tertiaryContainer;   // #BB152C

  // ── Glass helper ─────────────────────────────────────────────────────────────
  static Color glassSurface = surfaceContainer.withOpacity(0.60);
  static Color glassBorder  = Colors.white.withOpacity(0.10);
}
