import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/custom_request_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customization_provider.dart';
import 'custom_request_detail_screen.dart';

class MyRequestsScreen extends ConsumerWidget {
  const MyRequestsScreen({super.key});

  Widget _statusChip(String status) {
    final color = {
      'pending': AppColors.warning,
      'assigned': AppColors.primary,
      'in_progress': AppColors.info,
      'completed': AppColors.success,
      'rejected': AppColors.error,
    }[status] ?? AppColors.textHint;

    return Chip(
      label: Text(status.replaceAll('_', ' ')),
      backgroundColor: color.withOpacity(0.15),
      labelStyle: TextStyle(color: color),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Login required.')),
      );
    }

    final requestsAsync = ref.watch(customerCustomRequestsProvider(currentUser.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Custom Requests'),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: requestsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load requests: $e')),
        data: (requests) {
          if (requests.isEmpty) {
            return const Center(child: Text('No requests yet.'));
          }
          final grouped = <String, List<CustomRequestModel>>{};
          for (var r in requests) {
            grouped.putIfAbsent(r.status, () => []).add(r);
          }

          return ListView(
            padding: const EdgeInsets.all(12),
            children: grouped.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...entry.value.map((req) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title: Text('${req.type} ${req.productId != null ? 'for ${req.productId}' : ''}'),
                        subtitle: Text(req.description.isNotEmpty
                            ? req.description
                            : 'No description provided'),
                        trailing: _statusChip(req.status),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => CustomRequestDetailScreen(requestId: req.requestId),
                        )),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
