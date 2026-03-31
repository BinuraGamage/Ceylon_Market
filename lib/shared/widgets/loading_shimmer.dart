import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

/// Shimmer placeholder — use instead of CircularProgressIndicator in lists.
/// Always wrap in a sized container.
class LoadingShimmer extends StatelessWidget {
  final double? height;
  final double? width;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.height,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.surface,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Horizontal row of shimmer cards — for home screen product rows.
class ShimmerProductRow extends StatelessWidget {
  final int count;

  const ShimmerProductRow({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => const LoadingShimmer(
          height: 220,
          width: 160,
          borderRadius: 12,
        ),
      ),
    );
  }
}

/// Shimmer list of search result tiles.
class ShimmerListTiles extends StatelessWidget {
  final int count;

  const ShimmerListTiles({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const LoadingShimmer(height: 72, width: 72, borderRadius: 8),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LoadingShimmer(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.5),
                  const SizedBox(height: 6),
                  const LoadingShimmer(height: 12, width: 80),
                  const SizedBox(height: 6),
                  const LoadingShimmer(height: 10, width: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}