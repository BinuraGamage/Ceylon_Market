import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/custom_request_model.dart';
import '../../../models/shop_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customization_provider.dart';
import '../../../services/storage_service.dart';
import '../../home/widgets/customer_bottom_nav_bar.dart';
import '../../../shared/widgets/app_logo.dart';

class CustomInquiryScreen extends ConsumerStatefulWidget {
  const CustomInquiryScreen({super.key});

  @override
  ConsumerState<CustomInquiryScreen> createState() =>
      _CustomInquiryScreenState();
}

class _CustomInquiryScreenState extends ConsumerState<CustomInquiryScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  File? _pickedImage;
  bool _isSubmitting = false;
  ShopModel? _selectedShop;

  @override
  void dispose() {
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (result != null) {
      setState(() => _pickedImage = File(result.path));
    }
  }

  Future<void> _submitInquiry() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to send custom inquiries.'),
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty && _pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an image or description.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      String? imageUrl;
      if (_pickedImage != null) {
        imageUrl = await StorageService.instance.uploadRequestImage(
          file: _pickedImage!,
          customerId: currentUser.uid,
        );
      }

      final request = CustomRequestModel(
        requestId: '',
        customerId: currentUser.uid,
        shopId: _selectedShop?.shopId,
        type: 'inquiry',
        productId: null,
        selectedColor: null,
        selectedSize: null,
        selectedMaterial: null,
        description: _descriptionController.text.trim(),
        imageUrl: imageUrl,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref
          .read(customizationNotifierProvider.notifier)
          .submitInquiryRequest(request: request);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inquiry submitted successfully.'),
          backgroundColor: AppColors.primary,
        ),
      );

      _descriptionController.clear();
      _tagsController.clear();
      setState(() {
        _pickedImage = null;
        _selectedShop = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit inquiry: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final shopsAsync = ref.watch(shopSuggestionsProvider(selectedTags));

    return Scaffold(
      appBar: AppBar(
        title: const AppLogoTitle(title: 'Custom Product Inquiry'),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
        centerTitle: false,
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Tell us what you need',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: _pickedImage == null
                  ? const Center(child: Text('Tap to add reference image'))
                  : Image.file(_pickedImage!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tagsController,
            decoration: const InputDecoration(
              labelText: 'Product tags / categories (comma-separated)',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          const Text(
            'Suggested shops (auto-match)',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          shopsAsync.when(
            data: (shops) {
              if (shops.isEmpty) {
                return const Text('No matching shops found yet.');
              }
              return Column(
                children: shops.map((shop) {
                  final selected = _selectedShop?.shopId == shop.shopId;
                  return ListTile(
                    title: Text(shop.name),
                    subtitle: Text(
                      '${shop.city} · ${shop.categories.join(', ')}',
                    ),
                    trailing: selected
                        ? const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () => setState(() => _selectedShop = shop),
                  );
                }).toList(),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Error: $error'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitInquiry,
            child: Text(_isSubmitting ? 'Submitting...' : 'Submit Inquiry'),
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: -1),
    );
  }
}
