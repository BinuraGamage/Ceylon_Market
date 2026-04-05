import 'package:flutter/material.dart';

class AppColors {
  // ── Core Palette ──────────────────────────────────────────────────────────
  static const Color primary     = Color(0xFFC67C4E); // Warm brown — buttons, icons
  static const Color background  = Color(0xFFF6EBE5); // Warm cream — all screens
  static const Color surface     = Color(0xFFFFFFFF); // White — cards, inputs
  static const Color border = Color(0xFFE2D5C8);     // Subtle borders
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF1565C0);
  static const Color error       = Color(0xFFED5151); // Coral red — errors, alerts
  static const Color accent      = Color(0xFFC67C4E); // Same as primary for now

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF888888);
  static const Color textHint      = Color(0xFFBBBBBB);
  static const Color textOnPrimary = Color(0xFFFFFFFF); // White text on brown buttons

  // ── Missing ones for compile errors ──────────────────────────────────────
  static const Color onPrimary   = Color(0xFFFFFFFF); // White
  static const Color outline     = Color(0xFFBBBBBB); // Gray
  static const Color primaryContainer = Color(0xFFE8D8D0);
  static const Color surfaceVariant   = Color(0xFFF6EBE5);

  // ── UI Elements ───────────────────────────────────────────────────────────
  static const Color divider      = Color(0xFFE8D8D0);
  static const Color cardShadow   = Color(0x1AC67C4E); // Subtle brown shadow
  static const Color priceColor   = Color(0xFFC67C4E); // LKR price text
  static const Color starColor    = Color(0xFFFFC107); // Star ratings
  static const Color navActive    = Color(0xFFC67C4E); // Bottom nav active icon
  static const Color navInactive  = Color(0xFFBBBBBB); // Bottom nav inactive
  static const Color star = Color(0xFFFFC107); // Star rating yellow

}