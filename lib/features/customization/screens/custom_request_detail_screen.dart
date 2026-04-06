import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/custom_request_message_model.dart';
import '../../../models/custom_request_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customization_provider.dart';
import '../../home/widgets/customer_bottom_nav_bar.dart';

class CustomRequestDetailScreen extends ConsumerStatefulWidget {
  final String requestId;

  const CustomRequestDetailScreen({super.key, required this.requestId});

  @override
  ConsumerState<CustomRequestDetailScreen> createState() =>
      _CustomRequestDetailScreenState();
}

class _CustomRequestDetailScreenState
    extends ConsumerState<CustomRequestDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(CustomRequestModel request) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);

    final message = CustomRequestMessageModel(
      messageId: '',
      requestId: request.requestId,
      senderId: currentUser.uid,
      senderName: currentUser.displayName,
      message: text,
      sentAt: DateTime.now(),
    );
    try {
      await ref
          .read(customizationNotifierProvider.notifier)
          .sendRequestMessage(requestId: request.requestId, message: message);
      _messageController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not send message: $e'),
        backgroundColor: AppColors.error,
      ));
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _changeStatus(CustomRequestModel request, String newStatus) async {
    try {
      await ref.read(customizationNotifierProvider.notifier).updateRequestStatus(
            requestId: request.requestId,
            status: newStatus,
            designerId: (ref.read(currentUserProvider)?.role == 'designer')
                ? ref.read(currentUserProvider)!.uid
                : request.designerId,
          );
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Status updated.'),
        backgroundColor: AppColors.primary,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not update status: $e'),
        backgroundColor: AppColors.error,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(customRequestByIdProvider(widget.requestId));
    final messagesAsync = ref.watch(customRequestMessagesProvider(widget.requestId));
    final currentUser = ref.watch(currentUserProvider);
    final showCustomerNavBar = currentUser?.role == 'customer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      backgroundColor: AppColors.background,
      body: requestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading request: $e')),
        data: (request) {
          final isDesigner = currentUser?.role == 'designer';
          final isSeller = currentUser?.role == 'seller';
          final actions = <Widget>[];
          if (isDesigner && request.status == 'pending') {
            actions.addAll([
              ElevatedButton(
                onPressed: () => _changeStatus(request, 'assigned'),
                child: const Text('Accept'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => _changeStatus(request, 'rejected'),
                child: const Text('Decline'),
              ),
            ]);
          }
          if ((isDesigner || isSeller) && request.status == 'assigned') {
            actions.addAll([
              ElevatedButton(
                onPressed: () => _changeStatus(request, 'in_progress'),
                child: const Text('In Progress'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () => _changeStatus(request, 'completed'),
                child: const Text('Mark Complete'),
              ),
            ]);
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Card(
                      elevation: 0,
                      color: AppColors.surface,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Request ID: ${request.requestId}'),
                            const SizedBox(height: 6),
                            Text('Type: ${request.type}'),
                            const SizedBox(height: 6),
                            Text('Status: ${request.status}'),
                            const SizedBox(height: 6),
                            Text('Description: ${request.description.isEmpty ? 'N/A' : request.description}'),
                            if (request.imageUrl != null) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 160,
                                child: Image.network(request.imageUrl!, fit: BoxFit.cover),
                              ),
                            ],
                            if (request.productId != null) ...[
                              const SizedBox(height: 6),
                              Text('Product ID: ${request.productId}'),
                            ],
                            const SizedBox(height: 6),
                            Text('Requested color: ${request.selectedColor ?? 'Any'}'),
                            Text('Requested size: ${request.selectedSize ?? 'Any'}'),
                            Text('Requested material: ${request.selectedMaterial ?? 'Any'}'),
                          ],
                        ),
                      ),
                    ),
                    if (actions.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Wrap(spacing: 8, children: actions),
                      ),
                    const SizedBox(height: 12),
                    const Text('Conversation', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    messagesAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Could not load messages: $e'),
                      data: (messages) {
                        if (messages.isEmpty) {
                          return const Text('No messages yet.');
                        }
                        return Column(
                          children: messages.map((message) {
                            final isSelf = message.senderId == currentUser?.uid;
                            return Align(
                              alignment: isSelf ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelf ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.divider),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${message.senderName} • ${message.sentAt.toLocal().toString().split('.').first}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                                    const SizedBox(height: 4),
                                    Text(message.message),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 90),
                  ],
                ),
              ),
              Container(
                color: AppColors.surface,
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                  top: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: _isSending
                          ? const CircularProgressIndicator()
                          : const Icon(Icons.send, color: AppColors.primary),
                      onPressed: _isSending ? null : () => _sendMessage(request),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: showCustomerNavBar
          ? const CustomerBottomNavBar(currentIndex: 4)
          : null,
    );
  }
}
