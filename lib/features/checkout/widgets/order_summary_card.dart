import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../models/cart_item_model.dart';
import '../../models/product_model.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double discount;
  final double total;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: AppTextStyles.heading3,
            ),
            const SizedBox(height: 16),

            // Item list
            ...items.map((item) {
              final cartItem = item['cartItem'] as CartItemModel;
              final product = item['product'] as ProductModel;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${product.name} x${cartItem.quantity}',
                        style: AppTextStyles.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'LKR ${(product.price * cartItem.quantity).toStringAsFixed(2)}',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              );
            }),

            const Divider(height: 24),

            // Subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: AppTextStyles.body,
                ),
                Text(
                  'LKR ${subtotal.toStringAsFixed(2)}',
                  style: AppTextStyles.body,
                ),
              ],
            ),

            // Discount
            if (discount > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discount',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    '-LKR ${discount.toStringAsFixed(2)}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 24),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTextStyles.heading3,
                ),
                Text(
                  'LKR ${total.toStringAsFixed(2)}',
                  style: AppTextStyles.price,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}