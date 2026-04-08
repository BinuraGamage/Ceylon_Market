import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/custom_request_model.dart';
import '../../../providers/customization_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class SellerCustomRequestsScreen extends ConsumerWidget {
  const SellerCustomRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shopAsync = ref.watch(myShopProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const AppLogoTitle(title: 'Custom Requests'),
        centerTitle: false,
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: shopAsync.when(
        loading: () => const Center(child: LoadingShimmer()),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: error.toString(),
            onRetry: () => ref.invalidate(myShopProvider),
          ),
        ),
        data: (shop) {
          if (shop == null) {
            return const Center(
              child: Text('No seller shop profile found.'),
            );
          }

          final requestsAsync = ref.watch(
            shopCustomRequestsProvider(shop.shopId),
          );

          return requestsAsync.when(
            loading: () => const Center(child: LoadingShimmer()),
            error: (error, _) => Center(
              child: ErrorBanner(
                message: error.toString(),
                onRetry: () =>
                    ref.invalidate(shopCustomRequestsProvider(shop.shopId)),
              ),
            ),
            data: (requests) {
              final visibleRequests = requests
                  .where(
                    (request) =>
                        request.type == 'customization' ||
                        request.type == 'inquiry',
                  )
                  .toList();

              if (visibleRequests.isEmpty) {
                return const Center(
                  child: Text('No custom requests for your shop yet.'),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: visibleRequests.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final request = visibleRequests[index];
                  return _SellerCustomRequestTile(request: request);
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _SellerCustomRequestTile extends StatelessWidget {
  const _SellerCustomRequestTile({required this.request});

  final CustomRequestModel request;

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'assigned':
        return AppColors.primary;
      case 'in_progress':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'customization':
        return 'Product Customization';
      case 'inquiry':
        return 'Custom Inquiry';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(request.status);
    final createdLabel = DateFormat(
      'd MMM yyyy • h:mm a',
    ).format(request.createdAt.toLocal());

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.pushNamed(
        'custom-request-detail',
        pathParameters: {'id': request.requestId},
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(_typeLabel(request.type), style: AppTextStyles.heading3),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    request.status.replaceAll('_', ' '),
                    style: AppTextStyles.caption.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              request.description.isEmpty
                  ? 'No description provided.'
                  : request.description,
              style: AppTextStyles.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (request.productId != null && request.productId!.isNotEmpty)
                  Expanded(
                    child: Text(
                      'Product: ${request.productId}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  const Spacer(),
                Text(
                  createdLabel,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}