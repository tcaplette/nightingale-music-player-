import 'package:flutter/material.dart';

abstract final class AppMotion {
  // ── Core durations ────────────────────────────────────────────────────────
  static const Duration micro = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 300);
  static const Duration emphasis = Duration(milliseconds: 500);

  // ── Phase 7 named durations (use these instead of raw milliseconds) ───────
  /// Page-level route transitions: enter and exit.
  static const Duration pageTransition = Duration(milliseconds: 250);

  /// Modal bottom sheet entrance slide.
  static const Duration sheetEnter = Duration(milliseconds: 300);

  /// Network-state component entrance/exit and in-place state changes.
  static const Duration stateTransition = Duration(milliseconds: 200);

  // ── Curves ────────────────────────────────────────────────────────────────
  /// Micro-interactions: button press, icon swap.
  static const Curve curveMicro = Curves.easeOut;

  /// Standard state transitions: screen-level changes, tab switches.
  static const Curve curveStandard = Curves.easeInOut;

  /// Emphasis animations: onboarding, first-time reveals.
  static const Curve curveEmphasis = Curves.easeOutCubic;

  /// Exit animations: elements leaving the screen.
  static const Curve curveExit = Curves.easeOut;

  /// Page transition easing (fade-through).
  static const Curve curvePageTransition = Curves.easeInOut;
}
