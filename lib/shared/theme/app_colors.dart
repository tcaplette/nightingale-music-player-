import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Neutral palette ──────────────────────────────────────────────────────
  static const Color neutral0 = Color(0xFF000000);
  static const Color neutral50 = Color(0xFF111111);
  static const Color neutral100 = Color(0xFF1C1C1E);
  static const Color neutral150 = Color(0xFF2C2C2E);
  static const Color neutral200 = Color(0xFF3A3A3C);
  static const Color neutral300 = Color(0xFF636366);
  static const Color neutral400 = Color(0xFF8E8E93);
  static const Color neutral500 = Color(0xFFAEAEB2);
  static const Color neutral600 = Color(0xFFC7C7CC);
  static const Color neutral700 = Color(0xFFD1D1D6);
  static const Color neutral800 = Color(0xFFE5E5EA);
  static const Color neutral850 = Color(0xFFF2F2F7);
  static const Color neutral900 = Color(0xFFF8F8FA);
  static const Color neutral950 = Color(0xFFFFFFFF);

  // ── Single accent ─────────────────────────────────────────────────────────
  static const Color accent = Color(0xFF6B5CE7);
  static const Color accentSubdued = Color(0xFF9B8FEF);

  // ── Semantic — light mode ─────────────────────────────────────────────────
  static const Color backgroundLight = neutral950;
  static const Color surfaceLight = neutral900;
  static const Color surfaceVariantLight = neutral850;
  static const Color onSurfaceLight = neutral50;
  static const Color onSurfaceVariantLight = neutral300;
  static const Color outlineLight = neutral700;
  static const Color errorLight = Color(0xFFD93025);
  static const Color onErrorLight = neutral950;

  // ── Semantic — dark mode ──────────────────────────────────────────────────
  static const Color backgroundDark = neutral50;
  static const Color surfaceDark = neutral100;
  static const Color surfaceVariantDark = neutral150;
  static const Color onSurfaceDark = neutral900;
  static const Color onSurfaceVariantDark = neutral500;
  static const Color outlineDark = neutral200;
  static const Color errorDark = Color(0xFFFF6B6B);
  static const Color onErrorDark = neutral50;

  // ── Network-state semantic colours (shared between light/dark) ────────────
  static const Color offlineIndicator = neutral400;
  static const Color warningBanner = Color(0xFFF0A500);
}
