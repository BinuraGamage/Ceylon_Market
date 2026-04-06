import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../providers/product_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class ArPreviewScreen extends ConsumerWidget {
  final String productId;

  const ArPreviewScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.goNamed('product-detail', pathParameters: {'id': productId});
          },
        ),
        title: const Text('AR Preview'),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: productAsync.when(
        loading: () =>
            const Center(child: LoadingShimmer(height: 120, width: 120)),
        error: (e, _) => Center(
          child: ErrorBanner(
            message: 'Could not load AR model: ${e.toString()}',
            onRetry: () => ref.invalidate(productProvider(productId)),
          ),
        ),
        data: (product) {
          final modelUrl = product.arModelUrl;
          if (modelUrl == null || modelUrl.isEmpty) {
            return const Center(
              child: Text(
                'No AR model available for this product.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                color: AppColors.surface,
                child: ModelViewer(
                  src: modelUrl,
                  ar: true,
                  arModes: const ['scene-viewer', 'webxr', 'quick-look'],
                  autoRotate: true,
                  cameraControls: true,
                  backgroundColor: AppColors.surface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
