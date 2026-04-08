import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class CurrentUserProfileButton extends ConsumerWidget {
  const CurrentUserProfileButton({super.key, this.radius = 18});
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return GestureDetector(
      onTap: () => _showLogoutDialog(context, ref),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.surface,
        backgroundImage: user?.photoUrl != null
            ? CachedNetworkImageProvider(user!.photoUrl!)
            : null,
        child: user?.photoUrl == null
            ? Icon(
                Icons.person,
                size: radius * 1.5,
                color: AppColors.textSecondary,
              )
            : null,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Log Out', style: AppTextStyles.heading2),
        content: const Text(
          'Are you sure you want to log out of Ceylon Market?',
          style: AppTextStyles.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await ref.read(authNotifierProvider.notifier).signOut();
              if (context.mounted) {
                context.goNamed('login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
              elevation: 0,
            ),
            child: const Text('Log Out', style: AppTextStyles.button),
          ),
        ],
      ),
    );
  }
}
