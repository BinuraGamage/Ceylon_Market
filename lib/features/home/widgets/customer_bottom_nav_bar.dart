import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Customer-facing bottom navigation bar.
/// Owned by M2 — wrap any customer screen with [CustomerScaffold]
/// rather than using [Scaffold] directly, so nav is consistent.
class CustomerBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomerBottomNavBar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surface.withOpacity(0.72),
                  AppColors.surface.withOpacity(0.52),
                ],
              ),
              border: Border.all(
                color: AppColors.divider.withOpacity(0.65),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.cardShadow.withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  outlinedIcon: Icons.home_outlined,
                  label: 'Home',
                  index: 0,
                  currentIndex: currentIndex,
                  onTap: () => context.goNamed('customer-home'),
                ),
                _NavItem(
                  icon: Icons.search_rounded,
                  outlinedIcon: Icons.search_outlined,
                  label: 'Search',
                  index: 1,
                  currentIndex: currentIndex,
                  onTap: () => context.goNamed('search'),
                ),
                _NavItem(
                  icon: Icons.favorite_rounded,
                  outlinedIcon: Icons.favorite_border_rounded,
                  label: 'Wishlist',
                  index: 2,
                  currentIndex: currentIndex,
                  onTap: () => context.goNamed('wishlist'),
                ),
                _NavItem(
                  icon: Icons.shopping_bag_rounded,
                  outlinedIcon: Icons.shopping_bag_outlined,
                  label: 'Cart',
                  index: 3,
                  currentIndex: currentIndex,
                  onTap: () => context.goNamed('cart'),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  outlinedIcon: Icons.person_outline_rounded,
                  label: 'Profile',
                  index: 4,
                  currentIndex: currentIndex,
                  onTap: () => context.goNamed('profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isActive
                ? Border.all(
                    color: AppColors.primary.withOpacity(0.24),
                    width: 1,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? icon : outlinedIcon,
                color: isActive ? AppColors.navActive : AppColors.navInactive,
                size: 22,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTextStyles.navLabel.copyWith(
                  color: isActive ? AppColors.navActive : AppColors.navInactive,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}