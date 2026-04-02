import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';
import '../../../models/shop_analytics_model.dart';
import '../../../providers/shop_provider.dart';

/// Selling Insights screen — analytics dashboard for the shop owner.
/// M3 owns this file. Located at features/shop/screens/seller_insights_screen.dart
class SellerInsightsScreen extends ConsumerWidget {
  const SellerInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(shopAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Selling Insights', style: AppTextStyles.heading1),
      ),
      body: analyticsAsync.when(
        loading: () => const Center(child: LoadingShimmer()),
        error: (e, _) => Center(
          child: ErrorBanner(
            message: e.toString(),
            onRetry: () => ref.invalidate(shopAnalyticsProvider),
          ),
        ),
        data: (analytics) => analytics.totalOrders == 0
            ? _EmptyInsights()
            : _InsightsContent(analytics: analytics),
      ),
    );
  }
}

class _InsightsContent extends ConsumerWidget {
  const _InsightsContent({required this.analytics});
  final ShopAnalyticsModel analytics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(analyticsRangeProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── KPI Cards ─────────────────────────────────────────────
          _KpiRow(analytics: analytics),
          const SizedBox(height: 20),

          // ── Sales Over Time Chart ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sales Over Time (Last 7 Days)',
                      style: AppTextStyles.label,
                    ),
                    // Weekly / Monthly toggle
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          _RangeToggle(
                            label: 'Weekly',
                            selected: range == 'weekly',
                            onTap: () =>
                                ref
                                        .read(analyticsRangeProvider.notifier)
                                        .state =
                                    'weekly',
                          ),
                          _RangeToggle(
                            label: 'Monthly',
                            selected: range == 'monthly',
                            onTap: () =>
                                ref
                                        .read(analyticsRangeProvider.notifier)
                                        .state =
                                    'monthly',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 160,
                  child: _SalesLineChart(data: analytics.salesOverTime),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Top & Low Performing Products ─────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ProductListCard(
                  title: 'Top Performing Products',
                  products: analytics.topProducts,
                  isTop: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ProductListCard(
                  title: 'Low Performing Products',
                  products: analytics.lowProducts,
                  isTop: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── AI Insights ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI-Powered Insights', style: AppTextStyles.label),
                const SizedBox(height: 10),
                ...analytics.aiInsights.map(
                  (insight) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '"$insight"',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Customer Behavior ─────────────────────────────────────
          _CustomerBehaviorCard(behavior: analytics.customerBehavior),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── KPI Row ────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.analytics});
  final ShopAnalyticsModel analytics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiCard(
          icon: Icons.visibility_outlined,
          label: 'Total Views',
          value: '${analytics.totalViews}',
          sub: 'Views',
        ),
        const SizedBox(width: 8),
        _KpiCard(
          icon: Icons.shopping_cart_outlined,
          label: 'Total Orders',
          value: '${analytics.totalOrders}',
          sub: 'Orders',
        ),
        const SizedBox(width: 8),
        _KpiCard(
          icon: Icons.layers_outlined,
          label: 'Total Revenue',
          value: 'LKR ${_formatRevenue(analytics.totalRevenueLKR)}',
          sub: 'Revenue',
        ),
        const SizedBox(width: 8),
        _KpiCard(
          icon: Icons.star_outline_rounded,
          label: 'Avg Rating',
          value: analytics.avgRating.toStringAsFixed(1),
          sub: 'Rating',
          iconColor: AppColors.starColor,
        ),
      ],
    );
  }

  String _formatRevenue(double rev) {
    if (rev >= 1000) {
      return '${(rev / 1000).toStringAsFixed(0)}k';
    }
    return rev.toStringAsFixed(0);
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: _cardDecoration(),
        child: Column(
          children: [
            Icon(icon, size: 22, color: iconColor ?? AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              sub,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sales Line Chart ───────────────────────────────────────────────────────

class _SalesLineChart extends StatelessWidget {
  const _SalesLineChart({required this.data});
  final List<DailySales> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No sales data'));
    }

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.revenueLKR);
    }).toList();

    final maxY = data.map((d) => d.revenueLKR).reduce((a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) =>
              FlLine(color: AppColors.border, strokeWidth: 0.8),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, _) => Text(
                'LKR ${(value / 1000).toStringAsFixed(0)}k',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final idx = value.toInt();
                if (idx < 0 || idx >= data.length) return const SizedBox();
                return Text(
                  DateFormat('MMM d').format(data[idx].date),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primary,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product List Cards ─────────────────────────────────────────────────────

class _ProductListCard extends StatelessWidget {
  const _ProductListCard({
    required this.title,
    required this.products,
    required this.isTop,
  });
  final String title;
  final List<TopProduct> products;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.label),
          const SizedBox(height: 10),
          if (products.isEmpty)
            Text(
              'None',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...products.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _MiniProductRow(product: p, isTop: isTop),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniProductRow extends StatelessWidget {
  const _MiniProductRow({required this.product, required this.isTop});
  final TopProduct product;
  final bool isTop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: product.thumbnailUrl != null
              ? Image.network(
                  product.thumbnailUrl!,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(width: 36, height: 36, color: AppColors.border),
                )
              : Container(
                  width: 36,
                  height: 36,
                  color: AppColors.border,
                  child: const Icon(Icons.image_outlined, size: 16),
                ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      product.name,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (product.hasWarning)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text('⚠️', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
              if (isTop)
                Text(
                  'LKR ${product.revenueLKR.toStringAsFixed(0)} Revenue\n(${product.sales} sales)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                )
              else
                Text(
                  '${product.views} views, ${product.sales} sales\n– Low Conversion',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Customer Behavior Card ─────────────────────────────────────────────────

class _CustomerBehaviorCard extends StatelessWidget {
  const _CustomerBehaviorCard({required this.behavior});
  final CustomerBehavior behavior;

  @override
  Widget build(BuildContext context) {
    final hourEntries = List.generate(24, (h) {
      return MapEntry(h, behavior.activeByHour[h] ?? 0);
    });
    final maxCount = hourEntries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Behavior Insights', style: AppTextStyles.label),
          const SizedBox(height: 12),

          // Active hours bar chart (simplified)
          Text(
            'Most Active Time:',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: hourEntries
                  .where((e) => e.key % 3 == 0) // Show every 3rd hour
                  .map((e) {
                    final ratio = maxCount > 0 ? e.value / maxCount : 0.0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: 50 * ratio + 4,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(
                                  0.7 + 0.3 * ratio,
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${e.key}',
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 8,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Top category
          Row(
            children: [
              Text(
                'Top Viewed Category:',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
              _CategoryBadge(category: behavior.topViewedCategory),
            ],
          ),
          const SizedBox(height: 14),

          // Repeat customer rate
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repeat Customer Rate:',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(behavior.repeatCustomerRate * 100).toStringAsFixed(0)}%',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Donut chart
              SizedBox(
                width: 60,
                height: 60,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: behavior.repeatCustomerRate * 100,
                        color: AppColors.primary,
                        radius: 10,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (1 - behavior.repeatCustomerRate) * 100,
                        color: AppColors.border,
                        radius: 10,
                        showTitle: false,
                      ),
                    ],
                    centerSpaceRadius: 22,
                    sectionsSpace: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({required this.category});
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category[0].toUpperCase() + category.substring(1),
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart_outlined,
            size: 64,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text('No insights yet', style: AppTextStyles.heading2),
          const SizedBox(height: 8),
          Text(
            'Start selling to see your analytics here.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Shared decoration helper ───────────────────────────────────────────────

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: AppColors.border),
);
