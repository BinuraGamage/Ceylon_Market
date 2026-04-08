import 'package:equatable/equatable.dart';

/// Aggregated analytics model for the Selling Insights screen.
/// Computed on the fly from orders/products — not persisted as a separate doc.
class ShopAnalyticsModel extends Equatable {
  final int totalViews;
  final int totalOrders;
  final double totalRevenueLKR;
  final double avgRating;
  final List<DailySales> salesOverTime; // Last 7 or 30 days
  final List<TopProduct> topProducts;
  final List<TopProduct> lowProducts;
  final CustomerBehavior customerBehavior;
  final List<String> aiInsights;

  const ShopAnalyticsModel({
    required this.totalViews,
    required this.totalOrders,
    required this.totalRevenueLKR,
    required this.avgRating,
    required this.salesOverTime,
    required this.topProducts,
    required this.lowProducts,
    required this.customerBehavior,
    required this.aiInsights,
  });

  factory ShopAnalyticsModel.empty() => ShopAnalyticsModel(
    totalViews: 0,
    totalOrders: 0,
    totalRevenueLKR: 0,
    avgRating: 0,
    salesOverTime: const [],
    topProducts: const [],
    lowProducts: const [],
    customerBehavior: CustomerBehavior.empty(),
    aiInsights: const [],
  );

  @override
  List<Object?> get props => [
    totalViews,
    totalOrders,
    totalRevenueLKR,
    avgRating,
  ];
}

class DailySales extends Equatable {
  final DateTime date;
  final double revenueLKR;

  const DailySales({required this.date, required this.revenueLKR});

  @override
  List<Object?> get props => [date, revenueLKR];
}

class TopProduct extends Equatable {
  final String productId;
  final String name;
  final String? thumbnailUrl;
  final double revenueLKR;
  final int sales;
  final int views;
  final bool hasWarning; // Low conversion flag

  const TopProduct({
    required this.productId,
    required this.name,
    this.thumbnailUrl,
    required this.revenueLKR,
    required this.sales,
    required this.views,
    this.hasWarning = false,
  });

  @override
  List<Object?> get props => [productId, name, revenueLKR, sales, views];
}

class CustomerBehavior extends Equatable {
  final Map<String, int> activeByHour; // hour (0–23) → visit count
  final String topViewedCategory;
  final double repeatCustomerRate; // 0.0 – 1.0

  const CustomerBehavior({
    required this.activeByHour,
    required this.topViewedCategory,
    required this.repeatCustomerRate,
  });

  factory CustomerBehavior.empty() => const CustomerBehavior(
    activeByHour: {},
    topViewedCategory: '',
    repeatCustomerRate: 0,
  );

  @override
  List<Object?> get props => [topViewedCategory, repeatCustomerRate];
}
