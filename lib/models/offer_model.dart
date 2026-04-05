import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class OfferModel extends Equatable {
  final String id;
  final String shopId;
  final String title;
  final List<String> productIds;
  final bool isPercentage;
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final int? minQty;

  const OfferModel({
    required this.id,
    required this.shopId,
    required this.title,
    required this.productIds,
    required this.isPercentage,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    this.minQty,
  });

  String get status {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 'Scheduled';
    if (now.isAfter(endDate)) return 'Expired';
    return 'Active';
  }

  factory OfferModel.fromMap(Map<String, dynamic> map, String docId) {
    return OfferModel(
      id: docId,
      shopId: map['shopId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      productIds: List<String>.from(map['productIds'] as List? ?? []),
      isPercentage: map['isPercentage'] as bool? ?? false,
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      minQty: map['minQty'] as int?,
    );
  }

  Map<String, dynamic> toMap() => {
    'shopId': shopId,
    'title': title,
    'productIds': productIds,
    'isPercentage': isPercentage,
    'discountValue': discountValue,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    if (minQty != null) 'minQty': minQty,
  };

  @override
  List<Object?> get props => [
    id,
    shopId,
    title,
    productIds,
    isPercentage,
    discountValue,
    startDate,
    endDate,
    minQty,
  ];
}
