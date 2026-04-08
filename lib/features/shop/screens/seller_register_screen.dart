import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../providers/shop_provider.dart';

/// Seller registration form screen.
/// M3 owns this file. Located at features/shop/screens/seller_register_screen.dart
class SellerRegisterScreen extends ConsumerStatefulWidget {
  const SellerRegisterScreen({super.key});

  @override
  ConsumerState<SellerRegisterScreen> createState() =>
      _SellerRegisterScreenState();
}

class _SellerRegisterScreenState extends ConsumerState<SellerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _shopNameController = TextEditingController();
  final _storyController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  final List<String> _selectedCategories = [];
  File? _logoFile;
  File? _bannerFile;

  static const _allCategories = [
    'crafts',
    'clothing',
    'furniture',
    'food',
    'statues',
    'clay',
    'bottled',
    'metal',
    'paintings',
    'other',
  ];

  @override
  void dispose() {
    _shopNameController.dispose();
    _storyController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isLogo}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;
      setState(() {
        if (isLogo) {
          _logoFile = File(picked.path);
        } else {
          _bannerFile = File(picked.path);
        }
      });
    } catch (e) {
      debugPrint('[SellerRegisterScreen._pickImage] Error: $e');
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }

    await ref
        .read(sellerRegistrationProvider.notifier)
        .submit(
          shopName: _shopNameController.text.trim(),
          story: _storyController.text.trim(),
          categories: List.from(_selectedCategories),
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
          contactPhone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          contactEmail: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          logoFile: _logoFile,
          bannerFile: _bannerFile,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sellerRegistrationProvider);

    // Navigate to dashboard on success
    ref.listen(sellerRegistrationProvider, (_, next) {
      if (next.isSuccess) {
        context.goNamed('seller-dashboard');
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const AppLogoTitle(
          title: 'Become a Seller',
          textStyle: AppTextStyles.heading2,
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Intro ─────────────────────────────────────────────────
              Text('Set up your shop', style: AppTextStyles.heading1),
              const SizedBox(height: 4),
              Text(
                'Tell buyers about your craft and products.',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // ── Error Banner ──────────────────────────────────────────
              if (state.errorMessage != null) ...[
                ErrorBanner(message: state.errorMessage!),
                const SizedBox(height: 16),
              ],

              // ── Logo ──────────────────────────────────────────────────
              Text('Shop Logo', style: AppTextStyles.label),
              const SizedBox(height: 8),
              _ImagePickerTile(
                file: _logoFile,
                label: 'Upload Logo',
                icon: Icons.store,
                onTap: () => _pickImage(isLogo: true),
                height: 120,
                isCircle: true,
              ),
              const SizedBox(height: 16),

              // ── Banner ────────────────────────────────────────────────
              Text('Shop Banner (optional)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              _ImagePickerTile(
                file: _bannerFile,
                label: 'Upload Banner',
                icon: Icons.panorama,
                onTap: () => _pickImage(isLogo: false),
                height: 140,
                isCircle: false,
              ),
              const SizedBox(height: 20),

              // ── Shop Name ─────────────────────────────────────────────
              AppTextField(
                controller: _shopNameController,
                label: 'Shop Name',
                hint: 'e.g. Wood Meniya',
                validator: Validators.required,
              ),
              const SizedBox(height: 16),

              // ── Story ─────────────────────────────────────────────────
              AppTextField(
                controller: _storyController,
                label: 'Your Story',
                hint:
                    'Tell buyers about your craft, heritage, and inspiration...',
                maxLines: 4,
                validator: Validators.required,
              ),
              const SizedBox(height: 16),

              // ── Categories ────────────────────────────────────────────
              Text('Categories', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allCategories.map((cat) {
                  final selected = _selectedCategories.contains(cat);
                  return FilterChip(
                    label: Text(
                      cat[0].toUpperCase() + cat.substring(1),
                      style: AppTextStyles.caption.copyWith(
                        color: selected
                            ? AppColors.textOnPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                    selected: selected,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedCategories.add(cat);
                        } else {
                          _selectedCategories.remove(cat);
                        }
                      });
                    },
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    checkmarkColor: AppColors.textOnPrimary,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ── Address ───────────────────────────────────────────────
              AppTextField(
                controller: _addressController,
                label: 'Address',
                hint: 'e.g. 45 Galle Road',
                validator: Validators.required,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _cityController,
                label: 'City',
                hint: 'e.g. Colombo',
                validator: Validators.required,
              ),
              const SizedBox(height: 16),

              // ── Contact ───────────────────────────────────────────────
              AppTextField(
                controller: _phoneController,
                label: 'Contact Phone (optional)',
                hint: '+94 77 123 4567',
                keyboardType: TextInputType.phone,
                validator: Validators.optionalPhone,
              ),
              const SizedBox(height: 16),

              AppTextField(
                controller: _emailController,
                label: 'Contact Email (optional)',
                hint: 'shop@example.com',
                keyboardType: TextInputType.emailAddress,
                validator: Validators.optionalEmail,
              ),
              const SizedBox(height: 12),

              // ── Disclaimer ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '⚠️  Your shop will be in "Pending" status until approved by our admin team. You\'ll be notified once approved.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Submit ────────────────────────────────────────────────
              AppButton(
                label: state.isLoading ? 'Submitting...' : 'Submit Application',
                onPressed: state.isLoading ? null : _submit,
                isLoading: state.isLoading,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Private image picker tile — only used within this file.
class _ImagePickerTile extends StatelessWidget {
  const _ImagePickerTile({
    required this.file,
    required this.label,
    required this.icon,
    required this.onTap,
    required this.height,
    required this.isCircle,
  });

  final File? file;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double height;
  final bool isCircle;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (file != null) {
      child = ClipRRect(
        borderRadius: isCircle
            ? BorderRadius.circular(60)
            : BorderRadius.circular(12),
        child: Image.file(
          file!,
          fit: BoxFit.cover,
          width: isCircle ? 120 : double.infinity,
          height: height,
        ),
      );
    } else {
      child = Container(
        width: isCircle ? 120 : double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: isCircle
              ? BorderRadius.circular(60)
              : BorderRadius.circular(12),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: isCircle
          ? Center(child: Stack(children: [child, _editBadge()]))
          : child,
    );
  }

  Widget _editBadge() => Positioned(
    bottom: 0,
    right: 0,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(Icons.edit, size: 14, color: AppColors.textOnPrimary),
    ),
  );
}
