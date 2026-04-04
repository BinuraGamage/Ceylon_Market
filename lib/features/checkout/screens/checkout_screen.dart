import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:stripe_payment/stripe_payment.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/error_banner.dart';
import '../../shared/widgets/loading_shimmer.dart';
import '../widgets/order_summary_card.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promoCodeController = TextEditingController();

  // Address fields
  final _line1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String? _appliedPromoCode;
  double _discountAmount = 0.0;
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    _initializeStripe();
  }

  void _initializeStripe() {
    // Initialize Stripe with test publishable key
    StripePayment.setOptions(
      StripeOptions(
        publishableKey: "pk_test_51RxQUx1MrHSdlzA0jPDunhYSjQQIdcfkI4mqagAO6qf8eL8H3K3OcQKilOsAQf5NDnjpRfyYWUD6NWTxbJVln0jD00gvcfafJJ", // Test key for LKR transactions
        merchantId: "merchant.ceylonmarket", // Optional
        androidPayMode: 'test', // Test mode for Android
      ),
    );
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    _line1Controller.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartWithProducts = ref.watch(cartWithProductsProvider);
    final cartTotal = ref.watch(cartTotalProvider);
    final currentUser = ref.watch(currentUserProvider);
    final orderNotifier = ref.watch(orderNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: cartWithProducts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorBanner(
          message: 'Failed to load cart: ${error.toString()}',
        ),
        data: (items) {
          if (items.isEmpty) {
            return const _EmptyCartView();
          }

          final finalTotal = cartTotal - _discountAmount;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Order Summary
                OrderSummaryCard(
                  items: items,
                  subtotal: cartTotal,
                  discount: _discountAmount,
                  total: finalTotal,
                ),
                const SizedBox(height: 24),

                // Promo Code Section
                _PromoCodeSection(
                  controller: _promoCodeController,
                  appliedCode: _appliedPromoCode,
                  onApply: _applyPromoCode,
                  onRemove: _removePromoCode,
                ),
                const SizedBox(height: 24),

                // Shipping Address
                _ShippingAddressSection(
                  line1Controller: _line1Controller,
                  cityController: _cityController,
                  districtController: _districtController,
                  postalCodeController: _postalCodeController,
                ),
                const SizedBox(height: 24),

                // Payment Method (placeholder for now)
                _PaymentMethodSection(),
                const SizedBox(height: 32),

                // Place Order Button
                AppButton(
                  label: _isProcessingPayment
                      ? 'Processing Payment...'
                      : 'Place Order (LKR ${finalTotal.toStringAsFixed(2)})',
                  onPressed: _isProcessingPayment
                      ? null
                      : () => _placeOrder(
                            context,
                            ref,
                            orderNotifier,
                            items,
                            finalTotal,
                            currentUser?.uid ?? '',
                          ),
                  isLoading: _isProcessingPayment,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _applyPromoCode() async {
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    // TODO: Implement promo code validation with Firestore
    // For now, just apply a simple discount for demo
    if (code == 'DISCOUNT10') {
      setState(() {
        _appliedPromoCode = code;
        _discountAmount = ref.read(cartTotalProvider) * 0.1; // 10% discount
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Promo code applied!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid promo code')),
      );
    }
  }

  void _removePromoCode() {
    setState(() {
      _appliedPromoCode = null;
      _discountAmount = 0.0;
      _promoCodeController.clear();
    });
  }

  Future<void> _placeOrder(
    BuildContext context,
    WidgetRef ref,
    OrderNotifier orderNotifier,
    List<Map<String, dynamic>> items,
    double finalTotal,
    String customerId,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    // Validate stock availability
    for (final item in items) {
      final cartItem = item['cartItem'];
      final product = item['product'];
      if (product.stock < cartItem.quantity) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Insufficient stock for ${product.name}')),
        );
        return;
      }
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      // Create order items snapshot
      final orderItems = items.map((item) {
        final cartItem = item['cartItem'];
        final product = item['product'];
        return {
          'productId': product.productId,
          'name': product.name,
          'price': product.price,
          'quantity': cartItem.quantity,
          'selectedColor': cartItem.selectedColor,
          'selectedSize': cartItem.selectedSize,
          'selectedMaterial': cartItem.selectedMaterial,
          'customNote': cartItem.customNote,
        };
      }).toList();

      // Create shipping address
      final shippingAddress = {
        'line1': _line1Controller.text,
        'city': _cityController.text,
        'district': _districtController.text,
        'postalCode': _postalCodeController.text,
      };

      // Create order
      final order = OrderModel(
        orderId: '', // Will be set by Firestore
        customerId: customerId,
        shopId: items.first['product'].shopId, // Assuming single shop for now
        items: orderItems,
        totalLKR: finalTotal,
        discountLKR: _discountAmount,
        promoCode: _appliedPromoCode,
        status: 'pending',
        paymentStatus: 'unpaid',
        shippingAddress: shippingAddress,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Process payment with Stripe
      await _processStripePayment(finalTotal, order, orderNotifier);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  Future<void> _processStripePayment(
    double amount,
    OrderModel order,
    OrderNotifier orderNotifier,
  ) async {
    try {
      // Create payment method
      final paymentMethod = await StripePayment.paymentRequestWithCardForm(
        CardFormPaymentRequest(),
      );

      // Create payment intent via Cloud Function
      final paymentIntent = await _createPaymentIntent(amount);

      // Confirm payment
      final paymentResult = await StripePayment.confirmPaymentIntent(
        PaymentIntent(
          clientSecret: paymentIntent['client_secret'],
          paymentMethodId: paymentMethod.id,
        ),
      );

      if (paymentResult.status == 'succeeded') {
        // Payment successful - create order
        final orderId = await orderNotifier.createOrder(order.copyWith(
          paymentStatus: 'paid',
          paymentRef: paymentResult.paymentIntentId,
        ));

        // Clear cart after successful order
        await ref.read(cartNotifierProvider.notifier).clearCart();

        if (mounted) {
          // Navigate to order confirmation
          context.go('/order-confirmation/$orderId');
        }
      } else {
        // Payment failed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment error: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(double amount) async {
    try {
      final functions = FirebaseFunctions.instance;

      // Call the createPaymentIntent Cloud Function
      final result = await functions
          .httpsCallable('createPaymentIntent')
          .call({
        'amount': (amount * 100).toInt(), // Convert to cents (Stripe expects smallest currency unit)
        'currency': 'lkr',
        'metadata': {
          'customer_id': ref.read(currentUserProvider)?.uid ?? '',
          'customer_email': ref.read(currentUserProvider)?.email ?? '',
        },
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      throw Exception('Failed to create payment intent: $e');
    }
  }
}

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: AppTextStyles.heading2,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Continue Shopping',
            onPressed: () => context.go('/customer'),
          ),
        ],
      ),
    );
  }
}

class _PromoCodeSection extends StatelessWidget {
  const _PromoCodeSection({
    required this.controller,
    required this.appliedCode,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final String? appliedCode;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promo Code',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 12),
            if (appliedCode != null)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Applied: $appliedCode',
                      style: AppTextStyles.body,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: onRemove,
                      icon: Icon(
                        Icons.close,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: controller,
                      label: 'Enter promo code',
                      hint: 'e.g. DISCOUNT10',
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppButton(
                    label: 'Apply',
                    onPressed: onApply,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ShippingAddressSection extends StatelessWidget {
  const _ShippingAddressSection({
    required this.line1Controller,
    required this.cityController,
    required this.districtController,
    required this.postalCodeController,
  });

  final TextEditingController line1Controller;
  final TextEditingController cityController;
  final TextEditingController districtController;
  final TextEditingController postalCodeController;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shipping Address',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: line1Controller,
              label: 'Address Line 1',
              hint: 'Street address, P.O. box',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Address is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: cityController,
              label: 'City',
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'City is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: districtController,
                    label: 'District',
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'District is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: postalCodeController,
                    label: 'Postal Code',
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Postal code is required';
                      }
                      return null;
                    },
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

class _PaymentMethodSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.credit_card,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stripe Payment',
                          style: AppTextStyles.bodyLarge,
                        ),
                        Text(
                          'Secure payment processing in LKR',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TEST MODE',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}