import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class CartItemModel extends Equatable {
  final String cartItemId;
  final String productId;
  final String shopId;
  final int quantity;
  final String? selectedColor;
  final String? selectedSize;
  final String? selectedMaterial;
  final String? customNote;
  final DateTime addedAt;

  const CartItemModel({
    required this.cartItemId,
    required this.productId,
    required this.shopId,
    required this.quantity,
    this.selectedColor,
    this.selectedSize,
    this.selectedMaterial,
    this.customNote,
    required this.addedAt,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map, String id) {
    return CartItemModel(
      cartItemId: id,
      productId: map['productId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      quantity: map['quantity'] as int? ?? 1,
      selectedColor: map['selectedColor'] as String?,
      selectedSize: map['selectedSize'] as String?,
      selectedMaterial: map['selectedMaterial'] as String?,
      customNote: map['customNote'] as String?,
      addedAt: (map['addedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'shopId': shopId,
        'quantity': quantity,
        if (selectedColor != null) 'selectedColor': selectedColor,
        if (selectedSize != null) 'selectedSize': selectedSize,
        if (selectedMaterial != null) 'selectedMaterial': selectedMaterial,
        if (customNote != null) 'customNote': customNote,
        'addedAt': Timestamp.fromDate(addedAt),
      };

  CartItemModel copyWith({
    String? cartItemId,
    String? productId,
    String? shopId,
    int? quantity,
    String? selectedColor,
    String? selectedSize,
    String? selectedMaterial,
    String? customNote,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      cartItemId: cartItemId ?? this.cartItemId,
      productId: productId ?? this.productId,
      shopId: shopId ?? this.shopId,
      quantity: quantity ?? this.quantity,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedMaterial: selectedMaterial ?? this.selectedMaterial,
      customNote: customNote ?? this.customNote,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  List<Object?> get props => [
        cartItemId,
        productId,
        shopId,
        quantity,
        selectedColor,
        selectedSize,
        selectedMaterial,
        customNote,
        addedAt,
      ];
}