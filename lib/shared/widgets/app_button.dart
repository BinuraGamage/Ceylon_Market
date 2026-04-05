import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Primary full-width button used across all features.
/// Matches the elevatedButtonTheme defined in AppTheme.lightTheme.
/// Never put business logic here — pass callbacks in.
///
/// Usage:
/// ```dart
/// AppButton(
///   label: 'Submit',
///   onPressed: _submit,
/// )
/// // With loading state:
/// AppButton(
///   label: 'Submitting...',
///   onPressed: null,   // disables the button
///   isLoading: true,
/// )
/// ```
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;

  /// Optional leading icon.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    switch (variant) {
      case AppButtonVariant.primary:
        return _PrimaryButton(
          label: label,
          onPressed: isDisabled ? null : onPressed,
          isLoading: isLoading,
          icon: icon,
        );
      case AppButtonVariant.outline:
        return _OutlineButton(
          label: label,
          onPressed: isDisabled ? null : onPressed,
          isLoading: isLoading,
          icon: icon,
        );
      case AppButtonVariant.text:
        return _TextButtonVariant(
          label: label,
          onPressed: isDisabled ? null : onPressed,
          icon: icon,
        );
    }
  }
}

enum AppButtonVariant { primary, outline, text }

// ── Primary (filled brown) ─────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth ? double.infinity : null;
        return SizedBox(
          width: width,
          height: 52,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: onPressed == null
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _ButtonContent(
              label: label,
              isLoading: isLoading,
              icon: icon,
              textStyle: AppTextStyles.button,
            ),
          ),
        );
      },
    );
  }
}

// ── Outline (bordered, transparent fill) ─────────────────────────────────

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth ? double.infinity : null;
        return SizedBox(
          width: width,
          height: 52,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(
                color: onPressed == null
                    ? AppColors.primary.withValues(alpha: 0.4)
                    : AppColors.primary,
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _ButtonContent(
              label: label,
              isLoading: isLoading,
              icon: icon,
              textStyle:
                  AppTextStyles.button.copyWith(color: AppColors.primary),
            ),
          ),
        );
      },
    );
  }
}

// ── Text variant ──────────────────────────────────────────────────────────

class _TextButtonVariant extends StatelessWidget {
  const _TextButtonVariant({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: AppColors.primary),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
          ],
          Text(label,
              style: AppTextStyles.button.copyWith(color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ── Shared button content ─────────────────────────────────────────────────

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    required this.textStyle,
    this.icon,
  });

  final String label;
  final bool isLoading;
  final TextStyle textStyle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: AppColors.textOnPrimary,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(label, style: textStyle),
        ],
      );
    }

    return Text(label, style: textStyle);
  }
}