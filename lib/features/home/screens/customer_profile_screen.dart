import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../widgets/customer_bottom_nav_bar.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _postalCodeController = TextEditingController();

  bool _isSaving = false;
  bool _didHydrate = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _line1Controller.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _hydrateFields() {
    final user = ref.read(currentUserProvider);
    if (_didHydrate || user == null) return;

    _displayNameController.text = user.displayName;
    _emailController.text = user.email;
    _line1Controller.text = user.shippingAddress['line1'] ?? '';
    _cityController.text = user.shippingAddress['city'] ?? '';
    _districtController.text = user.shippingAddress['district'] ?? '';
    _postalCodeController.text = user.shippingAddress['postalCode'] ?? '';
    _didHydrate = true;
  }

  Future<void> _saveProfile() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final shippingAddress = {
        'line1': _line1Controller.text.trim(),
        'city': _cityController.text.trim(),
        'district': _districtController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
      };

      await FirestoreService.instance.updateUserProfile(
        uid: user.uid,
        displayName: _displayNameController.text.trim(),
        shippingAddress: shippingAddress,
      );

      ref.read(currentUserProvider.notifier).state = user.copyWith(
        displayName: _displayNameController.text.trim(),
        shippingAddress: Map<String, String>.from(shippingAddress),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile and address saved'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    _hydrateFields();

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('My Profile'),
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please log in to view your profile.'),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Go to Login',
                  onPressed: () => context.goNamed('login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.15,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.role.toUpperCase(),
                            style: AppTextStyles.caption,
                          ),
                          Text(user.displayName, style: AppTextStyles.heading3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account', style: AppTextStyles.heading3),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _displayNameController,
                      label: 'Display Name',
                      hint: 'Your full name',
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      readOnly: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default Shipping Address',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This address will auto-fill at checkout.',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _line1Controller,
                      label: 'Address Line 1',
                      hint: 'Street address',
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _cityController,
                      label: 'City',
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _districtController,
                            label: 'District',
                            validator: Validators.required,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTextField(
                            controller: _postalCodeController,
                            label: 'Postal Code',
                            validator: Validators.required,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              label: 'Save Profile',
              onPressed: _isSaving ? null : _saveProfile,
              isLoading: _isSaving,
              icon: Icons.save_outlined,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const CustomerBottomNavBar(currentIndex: -1),
    );
  }
}
