import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/current_user_profile_button.dart';

class AdminDashboardStub extends ConsumerWidget {
  const AdminDashboardStub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.admin_panel_settings_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?.displayName ?? 'Admin'}!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Sora',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Admin Dashboard — Coming Soon',
              style: TextStyle(
                fontFamily: 'Sora',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            const CurrentUserProfileButton(radius: 24),
            const SizedBox(height: 8),
            const Text(
              'Tap profile to log out',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
