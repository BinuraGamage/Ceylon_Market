import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/product_model.dart';
import '../../../models/custom_request_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customization_provider.dart';
import '../../../providers/product_provider.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../shared/widgets/app_logo.dart';

class DesignerDashboardScreen extends ConsumerWidget {
  const DesignerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Login required')));
    }

    final incoming = ref.watch(designerCustomRequestsProvider(currentUser.uid));

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(title: 'Designer Dashboard'),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        centerTitle: false,
      ),
      backgroundColor: AppColors.background,
      body: incoming.when(
        loading: () =>
            const Center(child: LoadingShimmer(height: 120, width: 120)),
        error: (e, _) => Center(child: Text('Could not load requests: $e')),
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(child: Text('No requests assigned yet.'));
          }

          final tabs = <({String label, List<CustomRequestModel> requests})>[
            (
              label: 'New',
              requests: requests.where((r) => r.status == 'pending').toList(),
            ),
            (
              label: 'Assigned',
              requests: requests.where((r) => r.status == 'assigned').toList(),
            ),
            (
              label: 'In Progress',
              requests: requests
                  .where((r) => r.status == 'in_progress')
                  .toList(),
            ),
            (
              label: 'Completed',
              requests: requests.where((r) => r.status == 'completed').toList(),
            ),
            (
              label: 'Rejected',
              requests: requests.where((r) => r.status == 'rejected').toList(),
            ),
          ];

          return DefaultTabController(
            length: tabs.length,
            child: Column(
              children: [
                Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textSecondary,
                    indicatorColor: AppColors.primary,
                    tabs: [for (final tab in tabs) Tab(text: tab.label)],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final tab in tabs)
                        _RequestsTabList(
                          requests: tab.requests,
                          emptyMessage:
                              'No ${tab.label.toLowerCase()} requests yet.',
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RequestsTabList extends StatelessWidget {
  const _RequestsTabList({required this.requests, required this.emptyMessage});

  final List<CustomRequestModel> requests;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(child: Text(emptyMessage));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: requests.length,
      itemBuilder: (context, index) => _RequestTile(request: requests[index]),
    );
  }
}

class _RequestTile extends ConsumerWidget {
  final CustomRequestModel request;

  const _RequestTile({required this.request});

  Color _badgeColor(String status) {
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
        return AppColors.textHint;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productId = request.productId;
    final AsyncValue<ProductModel>? productAsync =
        (productId != null && productId.isNotEmpty)
        ? ref.watch(productProvider(productId))
        : null;

    return GestureDetector(
      onTap: () => context.pushNamed(
        'custom-request-detail',
        pathParameters: {'id': request.requestId},
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            if (productAsync != null)
              productAsync.when(
                loading: () => const LoadingShimmer(height: 52, width: 52),
                error: (error, stackTrace) => Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.image_outlined,
                    color: AppColors.textHint,
                  ),
                ),
                data: (p) => Container(
                  height: 52,
                  width: 52,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.divider),
                    image: p.thumbnailUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(p.thumbnailUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: p.thumbnailUrl.isEmpty
                      ? const Icon(
                          Icons.image_outlined,
                          color: AppColors.textHint,
                        )
                      : null,
                ),
              ),
            if (productAsync != null) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Type: ${request.type}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Desc: ${request.description.isEmpty ? 'No details' : request.description}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text('Product: ${request.productId ?? 'N/A'}'),
                  if (productAsync != null)
                    productAsync.maybeWhen(
                      data: (p) {
                        final needsModel =
                            p.isAREnabled &&
                            (p.arModelUrl == null || p.arModelUrl!.isEmpty);
                        if (!needsModel) return const SizedBox.shrink();
                        return const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'AR enabled — model not uploaded yet',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _badgeColor(request.status).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                request.status.replaceAll('_', ' '),
                style: TextStyle(color: _badgeColor(request.status)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
