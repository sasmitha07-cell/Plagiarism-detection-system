import 'package:flutter/material.dart';

/// Premium light-theme color palette for Academic Writing Coach.
/// Visual identity: warm ivory base, deep forest green primary,
/// soft amber accents, and coral highlights.
/// NOT a generic blue/purple dark AI theme.
class AppColors {
  AppColors._();

  // ── Primary: Deep Forest Green ──────────────────────────────
  static const primary = Color(0xFF1A6B4A);
  static const primaryLight = Color(0xFF2E8B6A);
  static const primaryLighter = Color(0xFF4CAF85);
  static const primarySurface = Color(0xFFE8F5EE);
  static const primaryBorder = Color(0xFFB8DEC9);

  // ── Accent: Warm Amber ────────────────────────────────────
  static const accent = Color(0xFFE8A427);
  static const accentLight = Color(0xFFF5C46B);
  static const accentLighter = Color(0xFFFBE5B2);
  static const accentSurface = Color(0xFFFFF8EC);

  // ── Secondary: Coral Rose ─────────────────────────────────
  static const secondary = Color(0xFFE05A4A);
  static const secondaryLight = Color(0xFFEB7D6F);
  static const secondaryLighter = Color(0xFFF5AFA8);
  static const secondarySurface = Color(0xFFFFF0EE);

  // ── Tertiary: Soft Slate Blue ─────────────────────────────
  static const tertiary = Color(0xFF4A6FA5);
  static const tertiaryLight = Color(0xFF6B8EC2);
  static const tertiarySurface = Color(0xFFEDF2FA);

  // ── Background / Surface ──────────────────────────────────
  static const background = Color(0xFFF9F6F1);       // Warm ivory
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF4F0EA);   // Parchment
  static const surfaceCard = Color(0xFFFFFDF9);      // Very warm white

  // ── Text ─────────────────────────────────────────────────
  static const textPrimary = Color(0xFF1A1A0F);      // Near-black with warmth
  static const textSecondary = Color(0xFF4A4A3A);
  static const textTertiary = Color(0xFF7A7A6A);
  static const textDisabled = Color(0xFFB0AFA5);
  static const textOnPrimary = Color(0xFFFFFFFF);
  static const textOnAccent = Color(0xFF1A1A0F);

  // ── Borders & Dividers ───────────────────────────────────
  static const border = Color(0xFFE8E4DC);
  static const borderLight = Color(0xFFF0EDE6);
  static const divider = Color(0xFFECE8E0);

  // ── Risk / Severity Colors ───────────────────────────────
  static const riskSafe = Color(0xFF2D9E5F);
  static const riskSafeLight = Color(0xFFE8F7EF);
  static const riskLow = Color(0xFF7CB83E);
  static const riskLowLight = Color(0xFFF0F8E5);
  static const riskMedium = Color(0xFFE8A427);
  static const riskMediumLight = Color(0xFFFFF8EC);
  static const riskHigh = Color(0xFFE05A4A);
  static const riskHighLight = Color(0xFFFFF0EE);
  static const riskCritical = Color(0xFFB91C1C);
  static const riskCriticalLight = Color(0xFFFFEBEB);

  // ── Score Colors ─────────────────────────────────────────
  static const scoreExcellent = Color(0xFF2D9E5F);
  static const scoreGood = Color(0xFF7CB83E);
  static const scoreFair = Color(0xFFE8A427);
  static const scorePoor = Color(0xFFE05A4A);
  static const scoreCritical = Color(0xFFB91C1C);

  // ── AI Detection Colors ──────────────────────────────────
  static const humanWritten = Color(0xFF2D9E5F);
  static const aiGenerated = Color(0xFF4A6FA5);
  static const mixedContent = Color(0xFFE8A427);

  // ── Named Gradients ──────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A6B4A), Color(0xFF2E8B6A)],
  );

  static const gradientAccent = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE8A427), Color(0xFFF5C46B)],
  );

  static const gradientHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A6B4A), Color(0xFF4CAF85)],
  );

  static const gradientWarm = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFF8EC), Color(0xFFF9F6F1)],
  );

  static const gradientBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF9F6F1), Color(0xFFEFEBE3)],
  );

  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFFFFDF9)],
  );

  static const gradientSafe = LinearGradient(
    colors: [Color(0xFF2D9E5F), Color(0xFF4CAF85)],
  );

  static const gradientRisk = LinearGradient(
    colors: [Color(0xFFE05A4A), Color(0xFFB91C1C)],
  );

  // ── Shadow Colors ────────────────────────────────────────
  static const shadowPrimary = Color(0x201A6B4A);
  static const shadowCard = Color(0x14000000);
  static const shadowElevated = Color(0x24000000);
}
