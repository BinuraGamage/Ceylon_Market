import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ShopModel extends Equatable {
  final String shopId;
  final String ownerId; // userId of seller
  final String name;
  final String story; // The artisan's background story
  final String? bannerUrl;
  final String? logoUrl;
  final List<String> categories; // e.g. ['crafts', 'furniture']
  final GeoPoint location;
  final String address;
  final String city;
  final String? contactPhone;
  final String? contactEmail;
  final double avgRating; // Maintained by aggregation
  final int reviewCount;
  final String status; // 'pending' | 'approved' | 'active' | 'suspended'
  final DateTime createdAt;

  const ShopModel({
    required this.shopId,
    required this.ownerId,
    required this.name,
    required this.story,
    this.bannerUrl,
    this.logoUrl,
    required this.categories,
    required this.location,
    required this.address,
    required this.city,
    this.contactPhone,
    this.contactEmail,
    required this.avgRating,
    required this.reviewCount,
    required this.status,
    required this.createdAt,
  });

  /// Whether this shop is visible and purchasable from.
  bool get isActive => status == ShopStatus.active;

  /// Formatted rating string for display.
  String get formattedRating => avgRating.toStringAsFixed(1);

  factory ShopModel.fromMap(Map<String, dynamic> map, String id) {
    return ShopModel(
      shopId: id,
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      story: map['story'] as String? ?? '',
      bannerUrl: map['bannerUrl'] as String?,
      logoUrl: map['logoUrl'] as String?,
      categories: List<String>.from(map['categories'] as List? ?? []),
      location: map['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      address: map['address'] as String? ?? '',
      city: map['city'] as String? ?? '',
      contactPhone: map['contactPhone'] as String?,
      contactEmail: map['contactEmail'] as String?,
      avgRating: (map['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] as int? ?? 0,
      status: map['status'] as String? ?? ShopStatus.pending,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Note: shopId is never included in toMap() — it is the Firestore doc ID.
  Map<String, dynamic> toMap() => {
        'ownerId': ownerId,
        'name': name,
        'story': story,
        if (bannerUrl != null) 'bannerUrl': bannerUrl,
        if (logoUrl != null) 'logoUrl': logoUrl,
        'categories': categories,
        'location': location,
        'address': address,
        'city': city,
        if (contactPhone != null) 'contactPhone': contactPhone,
        if (contactEmail != null) 'contactEmail': contactEmail,
        'avgRating': avgRating,
        'reviewCount': reviewCount,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  ShopModel copyWith({
    String? shopId,
    String? ownerId,
    String? name,
    String? story,
    String? bannerUrl,
    String? logoUrl,
    List<String>? categories,
    GeoPoint? location,
    String? address,
    String? city,
    String? contactPhone,
    String? contactEmail,
    double? avgRating,
    int? reviewCount,
    String? status,
    DateTime? createdAt,
  }) {
    return ShopModel(
      shopId: shopId ?? this.shopId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      story: story ?? this.story,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      categories: categories ?? this.categories,
      location: location ?? this.location,
      address: address ?? this.address,
      city: city ?? this.city,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        shopId,
        ownerId,
        name,
        status,
        avgRating,
      ];
}

/// Valid status strings for ShopModel.
class ShopStatus {
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String active = 'active';
  static const String suspended = 'suspended';
}