import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../models/product_model.dart';
import '../../../providers/product_provider.dart';
import '../../../providers/shop_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final String? productId;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _tagsController = TextEditingController();
  final _materialsController = TextEditingController();
  final _sizesController = TextEditingController();
  final _colorsController = TextEditingController();
  final _arUrlController = TextEditingController();

  final List<File> _newImages = [];
  String _category = ProductCategory.other;
  bool _customizable = false;
  bool _isAREnabled = false;

  bool get _isEdit => widget.productId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _tagsController.dispose();
    _materialsController.dispose();
    _sizesController.dispose();
    _colorsController.dispose();
    _arUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 80);
    if (files.isEmpty) return;

    setState(() {
      _newImages.addAll(files.map((e) => File(e.path)));
    });
  }

  List<String> _splitCsv(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _submit({ProductModel? existing}) async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isEdit && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one product image.'),
        ),
      );
      return;
    }

    try {
      final name = _nameController.text.trim();
      final description = _descriptionController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final stock = int.parse(_stockController.text.trim());
      final tags = _splitCsv(_tagsController.text);
      final materials = _splitCsv(_materialsController.text);
      final sizes = _splitCsv(_sizesController.text);
      final colors = _splitCsv(_colorsController.text);
      final arUrl = _arUrlController.text.trim().isEmpty
          ? null
          : _arUrlController.text.trim();

      if (_isEdit && existing != null) {
        await ref
            .read(sellerProductFormProvider.notifier)
            .updateProduct(
              existing: existing,
              name: name,
              description: description,
              price: price,
              category: _category,
              stock: stock,
              tags: tags,
              materials: materials,
              sizes: sizes,
              colors: colors,
              customizable: _customizable,
              isAREnabled: _isAREnabled,
              arModelUrl: arUrl,
              newImageFiles: _newImages,
            );
      } else {
        await ref
            .read(sellerProductFormProvider.notifier)
            .createProduct(
              name: name,
              description: description,
              price: price,
              category: _category,
              stock: stock,
              tags: tags,
              materials: materials,
              sizes: sizes,
              colors: colors,
              customizable: _customizable,
              isAREnabled: _isAREnabled,
              arModelUrl: arUrl,
              imageFiles: _newImages,
            );
      }

      final state = ref.read(sellerProductFormProvider);
      if (state.isSuccess && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Product updated' : 'Product created'),
          ),
        );
        Navigator.of(context).pop();
      }
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter valid numeric values for price and stock.',
          ),
        ),
      );
    }
  }

  void _applyInitial(ProductModel product) {
    _nameController.text = product.name;
    _descriptionController.text = product.description;
    _priceController.text = product.price.toStringAsFixed(2);
    _stockController.text = product.stock.toString();
    _tagsController.text = product.tags.join(', ');
    _materialsController.text = (product.materials ?? []).join(', ');
    _sizesController.text = (product.sizes ?? []).join(', ');
    _colorsController.text = (product.colors ?? []).join(', ');
    _arUrlController.text = product.arModelUrl ?? '';
    _category = product.category;
    _customizable = product.customizable;
    _isAREnabled = product.isAREnabled;
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(sellerProductFormProvider);
    final categories = ref.watch(productCategoriesProvider);
    final shopAsync = ref.watch(myShopProvider);

    // For create form: check if seller has a shop
    if (!_isEdit) {
      return shopAsync.when(
        loading: () => const Scaffold(
          body: Center(child: LoadingShimmer(height: 120, width: 120)),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Create Product')),
          body: ErrorBanner(
            message: 'Error loading shop: ${e.toString()}',
            onRetry: () => ref.invalidate(myShopProvider),
          ),
        ),
        data: (shop) {
          if (shop == null) {
            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: const Text('Create Product'),
                backgroundColor: AppColors.background,
              ),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.storefront_rounded,
                        size: 50,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Shop Not Found',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please complete your shop registration before adding products.',
                        style: AppTextStyles.body,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return _buildScaffold(
            context: context,
            categories: categories,
            formState: formState,
            existing: null,
          );
        },
      );
    }

    final productAsync = ref.watch(productProvider(widget.productId!));
    return productAsync.when(
      loading: () => const Scaffold(
        body: Center(child: LoadingShimmer(height: 120, width: 120)),
      ),
      error: (e, _) => Scaffold(body: ErrorBanner(message: e.toString())),
      data: (product) {
        if (_nameController.text.isEmpty) {
          _applyInitial(product);
        }
        return _buildScaffold(
          context: context,
          categories: categories,
          formState: formState,
          existing: product,
        );
      },
    );
  }

  Widget _buildScaffold({
    required BuildContext context,
    required List<String> categories,
    required SellerProductFormState formState,
    required ProductModel? existing,
  }) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Create Product'),
        backgroundColor: AppColors.background,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppTextField(
              controller: _nameController,
              label: 'Product name',
              hint: 'e.g. Handcrafted Wooden Mask',
              validator: Validators.required,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 4,
              validator: Validators.required,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _priceController,
                    label: 'Price (LKR)',
                    keyboardType: TextInputType.number,
                    validator: Validators.lkrAmount,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _stockController,
                    label: 'Stock',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Stock is required';
                      }
                      final parsed = int.tryParse(value.trim());
                      if (parsed == null || parsed < 0) {
                        return 'Enter a valid stock';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Category', style: AppTextStyles.label),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(),
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(ProductCategory.label(c)),
                    ),
                  )
                  .toList(),
              onChanged: (value) =>
                  setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _tagsController,
              label: 'Tags (comma separated)',
              hint: 'traditional, handmade, wooden',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _materialsController,
              label: 'Materials (comma separated)',
              hint: 'wood, cotton, clay',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _sizesController,
              label: 'Sizes (comma separated)',
              hint: 'S, M, L',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _colorsController,
              label: 'Colors (comma separated)',
              hint: 'black, brown, red',
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _customizable,
              onChanged: (value) => setState(() => _customizable = value),
              title: const Text('Customizable'),
              activeThumbColor: AppColors.primary,
            ),
            SwitchListTile(
              value: _isAREnabled,
              onChanged: (value) => setState(() => _isAREnabled = value),
              title: const Text('AR enabled'),
              activeThumbColor: AppColors.primary,
            ),
            if (_isAREnabled) ...[
              AppTextField(
                controller: _arUrlController,
                label: 'AR model URL',
                hint: 'https://.../model.glb',
                validator: Validators.required,
              ),
              const SizedBox(height: 12),
            ],
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(
                _newImages.isEmpty
                    ? 'Pick product images'
                    : '${_newImages.length} image(s) selected',
              ),
            ),
            if (!_isEdit && _newImages.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Add at least one image to create a product.',
                  style: AppTextStyles.caption,
                ),
              ),
            if (formState.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                formState.errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 18),
            AppButton(
              label: _isEdit ? 'Save Changes' : 'Create Product',
              isLoading: formState.isSubmitting,
              onPressed: () => _submit(existing: existing),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
