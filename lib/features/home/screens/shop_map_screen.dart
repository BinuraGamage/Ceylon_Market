import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/shop_model.dart';
import '../../../providers/product_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';

/// Customer map view for discovering shops by their saved coordinates.
class ShopMapScreen extends ConsumerWidget {
  const ShopMapScreen({super.key});

  static const CameraPosition _defaultCamera = CameraPosition(
    target: LatLng(7.8731, 80.7718),
    zoom: 7,
  );

  bool _hasValidCoordinates(ShopModel shop) {
    final latitude = shop.location.latitude;
    final longitude = shop.location.longitude;
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopsAsync = ref.watch(shopMapShopsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Shops Map', style: AppTextStyles.heading2),
      ),
      body: shopsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: LoadingShimmer(height: 360, width: double.infinity),
        ),
        error: (error, _) => ErrorBanner(
          message: 'Failed to load shop locations: $error',
          onRetry: () => ref.invalidate(shopMapShopsProvider),
        ),
        data: (shops) {
          final mapReadyShops = shops.where(_hasValidCoordinates).toList();

          final camera = mapReadyShops.isEmpty
              ? _defaultCamera
              : CameraPosition(
                  target: LatLng(
                    mapReadyShops.first.location.latitude,
                    mapReadyShops.first.location.longitude,
                  ),
                  zoom: 10,
                );

          final markers = mapReadyShops
              .map(
                (shop) => Marker(
                  markerId: MarkerId(shop.shopId),
                  position: LatLng(
                    shop.location.latitude,
                    shop.location.longitude,
                  ),
                  infoWindow: InfoWindow(
                    title: shop.name,
                    snippet: shop.city,
                    onTap: () => context.pushNamed(
                      'shop',
                      pathParameters: {'id': shop.shopId},
                    ),
                  ),
                ),
              )
              .toSet();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    mapReadyShops.isEmpty
                        ? 'No shops with exact coordinates yet. Sellers must capture location during registration.'
                        : 'Tap a marker to preview a shop, then tap the info window to open the store room.',
                    style: AppTextStyles.bodySecondary,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: GoogleMap(
                      initialCameraPosition: camera,
                      myLocationButtonEnabled: true,
                      markers: markers,
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              if (mapReadyShops.isNotEmpty)
                SizedBox(
                  height: 126,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: mapReadyShops.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final shop = mapReadyShops[index];
                      final categoryLabel = shop.categories.isEmpty
                          ? 'Category not set'
                          : shop.categories.take(2).join(', ');

                      return InkWell(
                        onTap: () => context.pushNamed(
                          'shop',
                          pathParameters: {'id': shop.shopId},
                        ),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 230,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.heading3,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${shop.city}, ${shop.address}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.caption,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                categoryLabel,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodySmall,
                              ),
                              const Spacer(),
                              Text(
                                'Open store room',
                                style: AppTextStyles.link,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }
}
