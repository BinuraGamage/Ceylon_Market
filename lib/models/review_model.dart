import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String reviewId;
  final String productId;
  final String customerId;
  final String customerName;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;

  const ReviewModel({
    required this.reviewId,
    required this.productId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String id) {
    return ReviewModel(
      reviewId: id,
      productId: map['productId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? 'Customer',
      rating: (map['rating'] as num?)?.toInt() ?? 0,
      comment: map['comment'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Note: reviewId is never included in toMap() - it is the Firestore doc ID.
  Map<String, dynamic> toMap() => {
    'productId': productId,
    'customerId': customerId,
    'customerName': customerName,
    'rating': rating,
    'comment': comment,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  @override
  List<Object?> get props => [reviewId, productId, customerId, rating, comment];
}
