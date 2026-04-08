import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ProductModel extends Equatable {
  final String productId;
  final String shopId;
  final String name;
  final String description;
  final double price; // Always in LKR
  final double? originalPrice;
  final String? activeOfferId;
  final String category; // See AppConstants.productCategories
  final List<String> images; // Firebase Storage URLs — first is thumbnail
  final List<String> tags;
  final List<String>? materials;
  final List<String>? sizes;
  final List<String>? colors;
  final int stock;
  final bool isActive;
  final bool customizable;
  final bool isAREnabled;
  final String? arModelUrl; // Firebase Storage URL for .glb model
  final double avgRating;
  final int reviewCount;
  final int viewCount;
  final DateTime createdAt;

  const ProductModel({
    required this.productId,
    required this.shopId,
    required this.name,
    required this.description,
    required this.price,
    this.originalPrice,
    this.activeOfferId,
    required this.category,
    required this.images,
    required this.tags,
    this.materials,
    this.sizes,
    this.colors,
    required this.stock,
    required this.isActive,
    required this.customizable,
    required this.isAREnabled,
    this.arModelUrl,
    required this.avgRating,
    required this.reviewCount,
    required this.viewCount,
    required this.createdAt,
  });

  /// Thumbnail is always the first image in the list.
  String get thumbnailUrl => images.isNotEmpty ? images.first : '';

  /// Whether this product is available for purchase.
  bool get isAvailable => isActive && stock > 0;

  /// Formatted LKR price string — always use this for display.
  String get formattedPrice => 'LKR ${price.toStringAsFixed(2)}';

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      productId: id,
      shopId: map['shopId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: map['originalPrice'] != null
          ? (map['originalPrice'] as num).toDouble()
          : null,
      activeOfferId: map['activeOfferId'] as String?,
      category: map['category'] as String? ?? 'other',
      images: List<String>.from(map['images'] as List? ?? []),
      tags: List<String>.from(map['tags'] as List? ?? []),
      materials: map['materials'] != null
          ? List<String>.from(map['materials'] as List)
          : null,
      sizes: map['sizes'] != null
          ? List<String>.from(map['sizes'] as List)
          : null,
      colors: map['colors'] != null
          ? List<String>.from(map['colors'] as List)
          : null,
      stock: map['stock'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? false,
      customizable: map['customizable'] as bool? ?? false,
      isAREnabled: map['isAREnabled'] as bool? ?? false,
      arModelUrl: map['arModelUrl'] as String?,
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] as int? ?? 0,
      viewCount: map['viewCount'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Note: productId is never included in toMap() — it is the Firestore doc ID.
  Map<String, dynamic> toMap() => {
    'shopId': shopId,
    'name': name,
    'description': description,
    'price': price,
    if (originalPrice != null) 'originalPrice': originalPrice,
    if (activeOfferId != null) 'activeOfferId': activeOfferId,
    'category': category,
    'images': images,
    'tags': tags,
    if (materials != null) 'materials': materials,
    if (sizes != null) 'sizes': sizes,
    if (colors != null) 'colors': colors,
    'stock': stock,
    'isActive': isActive,
    'customizable': customizable,
    'isAREnabled': isAREnabled,
    if (arModelUrl != null) 'arModelUrl': arModelUrl,
    'avgRating': avgRating,
    'reviewCount': reviewCount,
    'viewCount': viewCount,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  ProductModel copyWith({
    String? productId,
    String? shopId,
    String? name,
    String? description,
    double? price,
    double? originalPrice,
    String? activeOfferId,
    String? category,
    List<String>? images,
    List<String>? tags,
    List<String>? materials,
    List<String>? sizes,
    List<String>? colors,
    int? stock,
    bool? isActive,
    bool? customizable,
    bool? isAREnabled,
    String? arModelUrl,
    double? avgRating,
    int? reviewCount,
    int? viewCount,
    DateTime? createdAt,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      shopId: shopId ?? this.shopId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      activeOfferId: activeOfferId ?? this.activeOfferId,
      category: category ?? this.category,
      images: images ?? this.images,
      tags: tags ?? this.tags,
      materials: materials ?? this.materials,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      customizable: customizable ?? this.customizable,
      isAREnabled: isAREnabled ?? this.isAREnabled,
      arModelUrl: arModelUrl ?? this.arModelUrl,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    shopId,
    name,
    price,
    category,
    stock,
    isActive,
    avgRating,
  ];
}

/// Valid category strings — always use these constants, never hardcode strings.
/// Matches the AGENTS.md spec and Firestore schema.
class ProductCategory {
  static const String crafts = 'crafts';
  static const String clothing = 'clothing';
  static const String furniture = 'furniture';
  static const String food = 'food';
  static const String statues = 'statues';
  static const String clay = 'clay';
  static const String bottled = 'bottled';
  static const String metal = 'metal';
  static const String paintings = 'paintings';
  static const String other = 'other';

  static const List<String> all = [
    crafts,
    clothing,
    furniture,
    food,
    statues,
    clay,
    bottled,
    metal,
    paintings,
    other,
  ];

  /// Normalizes category text from Firestore/UI into a canonical key.
  /// This keeps category browse working even when old data uses labels
  /// like "Clay Products" instead of canonical keys like "clay".
  static String normalizeCategoryKey(String raw) {
    final value = raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');

    switch (value) {
      case 'craft':
      case 'crafts':
        return crafts;
      case 'clothes':
      case 'clothing':
      case 'apparel':
        return clothing;
      case 'furniture':
        return furniture;
      case 'food':
      case 'foods':
        return food;
      case 'statue':
      case 'statues':
        return statues;
      case 'clay':
      case 'clay product':
      case 'clay products':
        return clay;
      case 'bottled':
      case 'bottled product':
      case 'bottled products':
        return bottled;
      case 'metal':
      case 'metal craft':
      case 'metal crafts':
        return metal;
      case 'painting':
      case 'paintings':
        return paintings;
      case 'other':
        return other;
      default:
        if (all.contains(value)) return value;
        return value;
    }
  }

  /// Human-readable label for UI display.
  static String label(String category) {
    switch (normalizeCategoryKey(category)) {
      case crafts:
        return 'Crafts';
      case clothing:
        return 'Clothing';
      case furniture:
        return 'Furniture';
      case food:
        return 'Food';
      case statues:
        return 'Statues';
      case clay:
        return 'Clay Products';
      case bottled:
        return 'Bottled Products';
      case metal:
        return 'Metal Crafts';
      case paintings:
        return 'Paintings';
      default:
        return 'Other';
    }
  }
}
