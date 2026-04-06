import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Firestore schema for /customRequests/{requestId}.
/// This is the canonical data model for both customization and inquiry requests.
class CustomRequestModel extends Equatable {
  final String requestId;
  final String customerId;
  final String? shopId; // seller target, may be null when pending matching
  final String? designerId;
  final String type; // 'customization' | 'inquiry' | 'ar_model'
  final String? productId;
  final String? selectedColor;
  final String? selectedSize;
  final String? selectedMaterial;
  final String description;
  final String? imageUrl;
  final String
  status; // 'pending' | 'assigned' | 'in_progress' | 'completed' | 'rejected'
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomRequestModel({
    required this.requestId,
    required this.customerId,
    this.shopId,
    this.designerId,
    required this.type,
    this.productId,
    this.selectedColor,
    this.selectedSize,
    this.selectedMaterial,
    required this.description,
    this.imageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return CustomRequestModel(
      requestId: id,
      customerId: map['customerId'] as String? ?? '',
      shopId: map['shopId'] as String?,
      designerId: map['designerId'] as String?,
      type: map['type'] as String? ?? 'inquiry',
      productId: map['productId'] as String?,
      selectedColor: map['selectedColor'] as String?,
      selectedSize: map['selectedSize'] as String?,
      selectedMaterial: map['selectedMaterial'] as String?,
      description: map['description'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      status: map['status'] as String? ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    if (shopId != null) 'shopId': shopId,
    if (designerId != null) 'designerId': designerId,
    'type': type,
    if (productId != null) 'productId': productId,
    if (selectedColor != null) 'selectedColor': selectedColor,
    if (selectedSize != null) 'selectedSize': selectedSize,
    if (selectedMaterial != null) 'selectedMaterial': selectedMaterial,
    'description': description,
    if (imageUrl != null) 'imageUrl': imageUrl,
    'status': status,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };

  CustomRequestModel copyWith({
    String? requestId,
    String? customerId,
    String? shopId,
    String? designerId,
    String? type,
    String? productId,
    String? selectedColor,
    String? selectedSize,
    String? selectedMaterial,
    String? description,
    String? imageUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomRequestModel(
      requestId: requestId ?? this.requestId,
      customerId: customerId ?? this.customerId,
      shopId: shopId ?? this.shopId,
      designerId: designerId ?? this.designerId,
      type: type ?? this.type,
      productId: productId ?? this.productId,
      selectedColor: selectedColor ?? this.selectedColor,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedMaterial: selectedMaterial ?? this.selectedMaterial,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    requestId,
    customerId,
    shopId,
    designerId,
    type,
    status,
    productId,
    selectedColor,
    selectedSize,
    selectedMaterial,
    description,
    imageUrl,
    createdAt,
    updatedAt,
  ];
}
