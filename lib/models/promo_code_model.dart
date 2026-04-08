import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class PromoCodeModel extends Equatable {
  final String promoId;
  final String code;
  final String type; // 'percentage' | 'fixed'
  final double value; // percentage (0-100) or fixed amount in LKR
  final double? minOrderValue; // minimum order value to apply
  final double? maxDiscount; // maximum discount for percentage codes
  final DateTime? expiryDate;
  final int? usageLimit;
  final int usageCount;
  final bool isActive;
  final DateTime createdAt;

  const PromoCodeModel({
    required this.promoId,
    required this.code,
    required this.type,
    required this.value,
    this.minOrderValue,
    this.maxDiscount,
    this.expiryDate,
    this.usageLimit,
    required this.usageCount,
    required this.isActive,
    required this.createdAt,
  });

  factory PromoCodeModel.fromMap(Map<String, dynamic> map, String id) {
    return PromoCodeModel(
      promoId: id,
      code: map['code'] as String? ?? '',
      type: map['type'] as String? ?? 'percentage',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (map['minOrderValue'] as num?)?.toDouble(),
      maxDiscount: (map['maxDiscount'] as num?)?.toDouble(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      usageLimit: map['usageLimit'] as int?,
      usageCount: map['usageCount'] as int? ?? 0,
      isActive: map['isActive'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'code': code,
    'type': type,
    'value': value,
    if (minOrderValue != null) 'minOrderValue': minOrderValue,
    if (maxDiscount != null) 'maxDiscount': maxDiscount,
    if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
    if (usageLimit != null) 'usageLimit': usageLimit,
    'usageCount': usageCount,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  bool get isValid {
    if (!isActive) return false;
    if (expiryDate != null && DateTime.now().isAfter(expiryDate!)) return false;
    if (usageLimit != null && usageCount >= usageLimit!) return false;
    return true;
  }

  double calculateDiscount(double orderTotal) {
    if (!isValid) return 0.0;

    if (minOrderValue != null && orderTotal < minOrderValue!) return 0.0;

    switch (type) {
      case 'percentage':
        final discount = orderTotal * (value / 100);
        return maxDiscount != null
            ? discount.clamp(0.0, maxDiscount!)
            : discount;
      case 'fixed':
        return value.clamp(0.0, orderTotal);
      default:
        return 0.0;
    }
  }

  PromoCodeModel copyWith({
    String? promoId,
    String? code,
    String? type,
    double? value,
    double? minOrderValue,
    double? maxDiscount,
    DateTime? expiryDate,
    int? usageLimit,
    int? usageCount,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PromoCodeModel(
      promoId: promoId ?? this.promoId,
      code: code ?? this.code,
      type: type ?? this.type,
      value: value ?? this.value,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      expiryDate: expiryDate ?? this.expiryDate,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    promoId,
    code,
    type,
    value,
    minOrderValue,
    maxDiscount,
    expiryDate,
    usageLimit,
    usageCount,
    isActive,
    createdAt,
  ];
}
