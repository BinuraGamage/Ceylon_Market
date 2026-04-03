import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/custom_request_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customization_provider.dart';
import 'custom_request_detail_screen.dart';

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
        title: const Text('Designer Dashboard'),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: incoming.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load requests: $e')),
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(child: Text('No requests assigned yet.'));
          }

          final categorized = {
            'new': requests.where((r) => r.status == 'pending').toList(),
            'assigned': requests.where((r) => r.status == 'assigned').toList(),
            'in_progress': requests.where((r) => r.status == 'in_progress').toList(),
            'completed': requests.where((r) => r.status == 'completed').toList(),
            'rejected': requests.where((r) => r.status == 'rejected').toList(),
          };

          return ListView(
            padding: const EdgeInsets.all(12),
            children: categorized.entries
                .where((entry) => entry.value.isNotEmpty)
                .expand((entry) {
                  return [
                    Text(
                      entry.key.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ...entry.value.map((req) => _RequestTile(request: req)),
                    const SizedBox(height: 16),
                  ];
                })
                .toList(),
          );
        },
      ),
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
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CustomRequestDetailScreen(requestId: request.requestId),
      )),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Type: ${request.type}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Desc: ${request.description.isEmpty ? 'No details' : request.description}',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Product: ${request.productId ?? 'N/A'}'),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _badgeColor(request.status).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(request.status.replaceAll('_', ' '), style: TextStyle(color: _badgeColor(request.status))),
            )
          ],
        ),
      ),
    );
  }
}
