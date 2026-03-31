import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class SellerHomeStub extends ConsumerWidget {
  const SellerHomeStub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.storefront_outlined,
                size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?.displayName ?? 'Seller'}!',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Sora',
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Seller Dashboard — Coming Soon',
              style: TextStyle(
                fontFamily: 'Sora',
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) context.goNamed('login');
              },
              child: const Text('Sign Out',
                  style: TextStyle(fontFamily: 'Sora')),
            ),
          ],
        ),
      ),
    );
  }
}