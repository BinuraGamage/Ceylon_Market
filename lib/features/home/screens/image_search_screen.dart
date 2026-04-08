import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/product_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/product_card.dart';
import '../widgets/customer_bottom_nav_bar.dart';

class ImageSearchScreen extends ConsumerWidget {
  const ImageSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageSearchAsync = ref.watch(imageSearchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(
          color: AppColors.textPrimary,
          onPressed: () {
            ref.read(imageSearchProvider.notifier).clearSearch();
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed('customer-home');
            }
          },
        ),
        title: const Text(
          'Search by image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: imageSearchAsync.when(
        loading: () => const _LoadingState(),
        error: (e, _) => ErrorBanner(
          message: 'Something went wrong. Please try again.',
          onRetry: () => ref.invalidate(imageSearchProvider),
        ),
        data: (state) {
          if (state.selectedImage == null) {
            return _PickImagePrompt(
              onPickImage: (source) => _pickAndSearch(context, ref, source),
            );
          }
          return _ResultsView(
            state: state,
            onPickNew: (source) => _pickAndSearch(context, ref, source),
          );
        },
      ),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: -1),
    );
  }

  Future<void> _pickAndSearch(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;
      await ref
          .read(imageSearchProvider.notifier)
          .searchWithImage(File(picked.path));
    } catch (e) {
      debugPrint('[ImageSearchScreen] _pickAndSearch error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not access camera or gallery.')),
        );
      }
    }
  }
}

// ── Pick Image Prompt ─────────────────────────────────────────────────────────

class _PickImagePrompt extends StatelessWidget {
  final void Function(ImageSource) onPickImage;

  const _PickImagePrompt({required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.image_search_rounded,
              size: 56,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Find similar products',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Upload a photo and we\'ll find matching local products from Ceylon Marketplace.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          // Camera button
          ElevatedButton.icon(
            onPressed: () => onPickImage(ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Take a photo'),
          ),
          const SizedBox(height: 12),
          // Gallery button
          OutlinedButton.icon(
            onPressed: () => onPickImage(ImageSource.gallery),
            icon: const Icon(
              Icons.photo_library_rounded,
              size: 18,
              color: AppColors.primary,
            ),
            label: const Text(
              'Choose from gallery',
              style: TextStyle(color: AppColors.primary),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading State ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          const SizedBox(height: 20),
          const Text(
            'Analysing your image…',
            style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'Finding similar local products',
            style: TextStyle(fontSize: 13, color: AppColors.textHint),
          ),
        ],
      ),
    );
  }
}

// ── Results View ──────────────────────────────────────────────────────────────

class _ResultsView extends StatelessWidget {
  final ImageSearchState state;
  final void Function(ImageSource) onPickNew;

  const _ResultsView({required this.state, required this.onPickNew});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Selected image preview + retake button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    state.selectedImage!,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state.results.length} product${state.results.length == 1 ? '' : 's'} found',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (state.suggestedTags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tags: ${state.suggestedTags.take(5).join(', ')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => onPickNew(ImageSource.gallery),
                  child: const Text(
                    'Change',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Error message if any
        if (state.error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  state.error!,
                  style: const TextStyle(fontSize: 13, color: AppColors.error),
                ),
              ),
            ),
          ),

        // Results grid
        if (state.results.isEmpty && state.error == null)
          const SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: AppColors.textHint,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No matching products found',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Try a different photo or search by keyword',
                    style: TextStyle(color: AppColors.textHint, fontSize: 13),
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => ProductCard(
                  product: state.results[i],
                  width: double.infinity,
                ),
                childCount: state.results.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
            ),
          ),
      ],
    );
  }
}
