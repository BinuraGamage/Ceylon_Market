import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// All TextStyle definitions for Ceylon Marketplace.
/// Never hardcode TextStyle inline in widgets — always reference these.
/// Font family: 'Sora' — defined in pubspec.yaml assets/fonts.
class AppTextStyles {
  // ── Headings ──────────────────────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    fontFamily: 'Sora',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: 'Sora',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: 'Sora',
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: 'Sora',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ── Body ──────────────────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Sora',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Sora',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.6,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: 'Sora',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Sora',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
  );

  // ── Labels & UI Elements ──────────────────────────────────────────────────
  static const TextStyle label = TextStyle(
    fontFamily: 'Sora',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSecondary = TextStyle(
    fontFamily: 'Sora',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle hint = TextStyle(
    fontFamily: 'Sora',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Sora',
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Product / Commerce ────────────────────────────────────────────────────

  /// LKR price — always use this for all price displays.
  static const TextStyle price = TextStyle(
    fontFamily: 'Sora',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.priceColor,
  );

  static const TextStyle priceLarge = TextStyle(
    fontFamily: 'Sora',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.priceColor,
  );

  static const TextStyle priceSmall = TextStyle(
    fontFamily: 'Sora',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.priceColor,
  );

  static const TextStyle productName = TextStyle(
    fontFamily: 'Sora',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle productNameLarge = TextStyle(
    fontFamily: 'Sora',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.3,
  );

  static const TextStyle shopName = TextStyle(
    fontFamily: 'Sora',
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle shopStory = TextStyle(
    fontFamily: 'Sora',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static const TextStyle rating = TextStyle(
    fontFamily: 'Sora',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Buttons ───────────────────────────────────────────────────────────────
  static const TextStyle buttonPrimary = TextStyle(
    fontFamily: 'Sora',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: 'Sora',
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );

  static const TextStyle link = TextStyle(
    fontFamily: 'Sora',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
  );

  // ── Navigation ────────────────────────────────────────────────────────────
  static const TextStyle navLabel = TextStyle(
    fontFamily: 'Sora',
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  // ── Input & Form ──────────────────────────────────────────────────────────
  static const TextStyle inputLabel = TextStyle(
    fontFamily: 'Sora',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle inputText = TextStyle(
    fontFamily: 'Sora',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle errorText = TextStyle(
    fontFamily: 'Sora',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );
}