import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class OrderModel extends Equatable {
  final String orderId;
  final String customerId;
  final String shopId;
  final List<Map<String, dynamic>> items; // Snapshot of cart items at checkout
  final double totalLKR;
  final double discountLKR;
  final String? promoCode;
  final String status; // 'pending' | 'confirmed' | 'processing' | 'shipped' | 'delivered' | 'cancelled'
  final String paymentStatus; // 'unpaid' | 'paid' | 'refunded'
  final String? paymentRef; // Gateway transaction reference
  final Map<String, dynamic> shippingAddress; // {line1, city, district, postalCode}
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderModel({
    required this.orderId,
    required this.customerId,
    required this.shopId,
    required this.items,
    required this.totalLKR,
    required this.discountLKR,
    this.promoCode,
    required this.status,
    required this.paymentStatus,
    this.paymentRef,
    required this.shippingAddress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      orderId: id,
      customerId: map['customerId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] as List? ?? []),
      totalLKR: (map['totalLKR'] as num?)?.toDouble() ?? 0.0,
      discountLKR: (map['discountLKR'] as num?)?.toDouble() ?? 0.0,
      promoCode: map['promoCode'] as String?,
      status: map['status'] as String? ?? 'pending',
      paymentStatus: map['paymentStatus'] as String? ?? 'unpaid',
      paymentRef: map['paymentRef'] as String?,
      shippingAddress: Map<String, dynamic>.from(map['shippingAddress'] as Map? ?? {}),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'customerId': customerId,
        'shopId': shopId,
        'items': items,
        'totalLKR': totalLKR,
        'discountLKR': discountLKR,
        if (promoCode != null) 'promoCode': promoCode,
        'status': status,
        'paymentStatus': paymentStatus,
        if (paymentRef != null) 'paymentRef': paymentRef,
        'shippingAddress': shippingAddress,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  OrderModel copyWith({
    String? orderId,
    String? customerId,
    String? shopId,
    List<Map<String, dynamic>>? items,
    double? totalLKR,
    double? discountLKR,
    String? promoCode,
    String? status,
    String? paymentStatus,
    String? paymentRef,
    Map<String, dynamic>? shippingAddress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      orderId: orderId ?? this.orderId,
      customerId: customerId ?? this.customerId,
      shopId: shopId ?? this.shopId,
      items: items ?? this.items,
      totalLKR: totalLKR ?? this.totalLKR,
      discountLKR: discountLKR ?? this.discountLKR,
      promoCode: promoCode ?? this.promoCode,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentRef: paymentRef ?? this.paymentRef,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        orderId,
        customerId,
        shopId,
        items,
        totalLKR,
        discountLKR,
        promoCode,
        status,
        paymentStatus,
        paymentRef,
        shippingAddress,
        createdAt,
        updatedAt,
      ];
}