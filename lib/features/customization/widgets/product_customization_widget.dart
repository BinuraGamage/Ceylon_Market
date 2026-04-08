import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/custom_request_model.dart';
import '../../../models/product_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/customization_provider.dart';

class ProductCustomizationWidget extends ConsumerStatefulWidget {
  final ProductModel product;

  const ProductCustomizationWidget({super.key, required this.product});

  @override
  ConsumerState<ProductCustomizationWidget> createState() =>
      _ProductCustomizationWidgetState();
}

class _ProductCustomizationWidgetState
    extends ConsumerState<ProductCustomizationWidget> {
  String? _selectedColor;
  String? _selectedSize;
  String? _selectedMaterial;
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to submit customization requests.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final request = CustomRequestModel(
      requestId: '',
      customerId: currentUser.uid,
      shopId: widget.product.shopId,
      type: 'customization',
      productId: widget.product.productId,
      selectedColor: _selectedColor,
      selectedSize: _selectedSize,
      selectedMaterial: _selectedMaterial,
      description: _notesController.text.trim(),
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await ref
          .read(customizationNotifierProvider.notifier)
          .submitCustomizationRequest(request: request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customization request sent to seller.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }

      setState(() {
        _selectedColor = null;
        _selectedSize = null;
        _selectedMaterial = null;
        _notesController.text = '';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customize this product',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          if (widget.product.colors?.isNotEmpty == true)
            _buildDropdown<String>(
              label: 'Color',
              value: _selectedColor,
              items: widget.product.colors!,
              onChanged: (value) => setState(() => _selectedColor = value),
            ),
          if (widget.product.sizes?.isNotEmpty == true)
            _buildDropdown<String>(
              label: 'Size',
              value: _selectedSize,
              items: widget.product.sizes!,
              onChanged: (value) => setState(() => _selectedSize = value),
            ),
          if (widget.product.materials?.isNotEmpty == true)
            _buildDropdown<String>(
              label: 'Material',
              value: _selectedMaterial,
              items: widget.product.materials!,
              onChanged: (value) => setState(() => _selectedMaterial = value),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Custom notes / requirements',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                child: Text(
                  _isSubmitting ? 'Submitting...' : 'Request Customization',
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        setState(() {
                          _selectedColor = null;
                          _selectedSize = null;
                          _selectedMaterial = null;
                          _notesController.clear();
                        });
                      },
                child: const Text('Clear'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('No preference')),
              ...items.map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text(item.toString())),
              ),
            ],
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
