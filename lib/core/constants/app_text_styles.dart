import 'package:flutter/material.dart';
import 'app_colors.dart';

/// All TextStyle definitions for the app.
/// Font family: 'Sora' — set globally via AppTheme; no need to repeat it here.
/// Never hardcode text styles inline — always use these constants.
abstract class AppTextStyles {
  // ── Headings ──────────────────────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.2,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ──────────────────────────────────────────────────────────────────
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  // ── Label ─────────────────────────────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Caption ───────────────────────────────────────────────────────────────
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Button ────────────────────────────────────────────────────────────────
  static const TextStyle button = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    letterSpacing: 0.2,
  );

  // ── Price ─────────────────────────────────────────────────────────────────
  /// Always used with: Text('LKR ${price.toStringAsFixed(2)}', style: AppTextStyles.price)
  static const TextStyle price = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.priceColor,
  );
}