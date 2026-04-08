import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/cart_item_model.dart';
import '../../../models/product_model.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.cartItem,
    required this.product,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItemModel cartItem;
  final ProductModel product;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: product.thumbnailUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const LoadingShimmer(width: 80, height: 80),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.surfaceVariant,
                  child: Icon(Icons.broken_image, color: AppColors.outline),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    product.name,
                    style: AppTextStyles.bodyLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Selected Options
                  if (cartItem.selectedColor != null ||
                      cartItem.selectedSize != null ||
                      cartItem.selectedMaterial != null)
                    _SelectedOptions(cartItem: cartItem),

                  // Custom Note
                  if (cartItem.customNote != null &&
                      cartItem.customNote!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Note: ${cartItem.customNote}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.outline,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(height: 8),

                  // Price and Quantity Controls
                  Row(
                    children: [
                      // Price
                      Expanded(
                        child: Text(
                          product.formattedPrice,
                          style: AppTextStyles.price,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Quantity Controls
                      _QuantityControls(
                        quantity: cartItem.quantity,
                        onChanged: onQuantityChanged,
                      ),

                      const SizedBox(width: 4),

                      // Remove Button
                      IconButton(
                        onPressed: onRemove,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 28,
                          height: 28,
                        ),
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        tooltip: 'Remove item',
                      ),
                    ],
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

class _SelectedOptions extends StatelessWidget {
  const _SelectedOptions({required this.cartItem});

  final CartItemModel cartItem;

  @override
  Widget build(BuildContext context) {
    final options = <String>[];

    if (cartItem.selectedColor != null) {
      options.add('Color: ${cartItem.selectedColor}');
    }
    if (cartItem.selectedSize != null) {
      options.add('Size: ${cartItem.selectedSize}');
    }
    if (cartItem.selectedMaterial != null) {
      options.add('Material: ${cartItem.selectedMaterial}');
    }

    return Text(
      options.join(' • '),
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
    );
  }
}

class _QuantityControls extends StatelessWidget {
  const _QuantityControls({required this.quantity, required this.onChanged});

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decrease Button
        IconButton(
          onPressed: quantity > 1 ? () => onChanged(quantity - 1) : null,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          icon: Icon(
            Icons.remove,
            size: 16,
            color: quantity > 1 ? AppColors.primary : AppColors.outline,
          ),
        ),

        // Quantity Display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.outline),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(quantity.toString(), style: AppTextStyles.body),
        ),

        // Increase Button
        IconButton(
          onPressed: () => onChanged(quantity + 1),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 28, height: 28),
          icon: Icon(Icons.add, size: 16, color: AppColors.primary),
        ),
      ],
    );
  }
}
