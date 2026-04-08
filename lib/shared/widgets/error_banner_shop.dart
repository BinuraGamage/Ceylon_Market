import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Displays an error message with an optional retry button.
/// Used as the error state across all screens.
///
/// Usage:
/// ```dart
/// ErrorBanner(message: e.toString())
///
/// // With retry:
/// ErrorBanner(
///   message: 'Failed to load shop.',
///   onRetry: () => ref.invalidate(myShopProvider),
/// )
/// ```
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Something went wrong',
                  style: AppTextStyles.label.copyWith(color: AppColors.error),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.error.withOpacity(0.8),
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onRetry,
                    child: Text(
                      'Tap to retry',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
