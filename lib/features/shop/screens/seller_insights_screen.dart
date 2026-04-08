import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../models/shop_analytics_model.dart';
import '../../../providers/shop_provider.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/loading_shimmer.dart';

/// Selling Insights screen — analytics dashboard for the shop owner.
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
        actions: [
          TextButton.icon(
            onPressed: () =>
                context.pushNamed('seller-product-reviews-overview'),
            icon: const Icon(Icons.reviews_outlined, color: AppColors.primary),
            label: Text(
              'Reviews',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: analyticsAsync.when(
        loading: () =>
            const Center(child: LoadingShimmer(height: 120, width: 220)),
        error: (error, _) => Center(
          child: ErrorBanner(
            message: error.toString(),
            onRetry: () => ref.invalidate(shopAnalyticsProvider),
          ),
        ),
        data: (analytics) {
          if (analytics.totalOrders == 0 && analytics.totalViews == 0) {
            return const _EmptyInsights();
          }
          return _InsightsContent(analytics: analytics);
        },
      ),
    );
  }
}

enum _ProductInsightMetric { revenue, sales, views }

class _InsightsContent extends StatefulWidget {
  const _InsightsContent({required this.analytics});

  final ShopAnalyticsModel analytics;

  @override
  State<_InsightsContent> createState() => _InsightsContentState();
}

class _InsightsContentState extends State<_InsightsContent> {
  _ProductInsightMetric _selectedMetric = _ProductInsightMetric.revenue;
  String? _selectedProductId;

  List<TopProduct> _buildProducts() {
    final merged = <String, TopProduct>{};
    for (final product in [
      ...widget.analytics.topProducts,
      ...widget.analytics.lowProducts,
    ]) {
      merged[product.productId] = product;
    }

    final list = merged.values.toList()
      ..sort((a, b) => _metricValue(b).compareTo(_metricValue(a)));

    return list.take(8).toList();
  }

  double _metricValue(TopProduct product) {
    switch (_selectedMetric) {
      case _ProductInsightMetric.revenue:
        return product.revenueLKR;
      case _ProductInsightMetric.sales:
        return product.sales.toDouble();
      case _ProductInsightMetric.views:
        return product.views.toDouble();
    }
  }

  String _metricLabel(_ProductInsightMetric metric) {
    switch (metric) {
      case _ProductInsightMetric.revenue:
        return 'Revenue';
      case _ProductInsightMetric.sales:
        return 'Sales';
      case _ProductInsightMetric.views:
        return 'Views';
    }
  }

  String _formatHourRange(String hour) {
    final parsed = int.tryParse(hour) ?? 0;
    final next = (parsed + 1) % 24;
    final start = parsed.toString().padLeft(2, '0');
    final end = next.toString().padLeft(2, '0');
    return '$start:00-$end:00';
  }

  @override
  Widget build(BuildContext context) {
    final products = _buildProducts();
    final selectedId =
        _selectedProductId ??
        (products.isEmpty ? null : products.first.productId);
    final selectedProduct = selectedId == null
        ? null
        : products.firstWhere(
            (product) => product.productId == selectedId,
            orElse: () => products.first,
          );

    final conversionRate = widget.analytics.totalViews == 0
        ? 0.0
        : (widget.analytics.totalOrders / widget.analytics.totalViews) * 100;
    final averageOrderValue = widget.analytics.totalOrders == 0
        ? 0.0
        : widget.analytics.totalRevenueLKR / widget.analytics.totalOrders;

    final peakEntry = widget.analytics.customerBehavior.activeByHour.entries
        .fold<MapEntry<String, int>?>(null, (currentPeak, entry) {
          if (currentPeak == null || entry.value > currentPeak.value) {
            return entry;
          }
          return currentPeak;
        });

    final peakHourRange = peakEntry == null
        ? 'N/A'
        : _formatHourRange(peakEntry.key);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ExecutiveSummaryCard(
            conversionRate: conversionRate,
            averageOrderValue: averageOrderValue,
            peakHourRange: peakHourRange,
          ),
          const SizedBox(height: 14),
          _KpiGrid(analytics: widget.analytics),
          const SizedBox(height: 14),
          _SalesOverTimeCard(data: widget.analytics.salesOverTime),
          const SizedBox(height: 14),
          _ProductInsightsChartCard(
            products: products,
            selectedMetric: _selectedMetric,
            selectedProductId: selectedId,
            selectedProduct: selectedProduct,
            metricLabel: _metricLabel(_selectedMetric),
            metricValueOf: _metricValue,
            onMetricChanged: (metric) {
              setState(() {
                _selectedMetric = metric;
              });
            },
            onProductChanged: (productId) {
              setState(() {
                _selectedProductId = productId;
              });
            },
          ),
          const SizedBox(height: 14),
          _CustomerActivityByTimeCard(
            activeByHour: widget.analytics.customerBehavior.activeByHour,
          ),
          const SizedBox(height: 14),
          _CustomerBehaviorSummaryCard(
            behavior: widget.analytics.customerBehavior,
          ),
          const SizedBox(height: 14),
          _AiInsightsCard(insights: widget.analytics.aiInsights),
          const SizedBox(height: 26),
        ],
      ),
    );
  }
}

class _ExecutiveSummaryCard extends StatelessWidget {
  const _ExecutiveSummaryCard({
    required this.conversionRate,
    required this.averageOrderValue,
    required this.peakHourRange,
  });

  final double conversionRate;
  final double averageOrderValue;
  final String peakHourRange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Business Snapshot', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryPill(
                label: 'Conversion',
                value: '${conversionRate.toStringAsFixed(1)}%',
                icon: Icons.auto_graph_rounded,
              ),
              _SummaryPill(
                label: 'Avg Order Value',
                value: 'LKR ${averageOrderValue.toStringAsFixed(2)}',
                icon: Icons.payments_outlined,
              ),
              _SummaryPill(
                label: 'Peak Hour',
                value: peakHourRange,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.analytics});

  final ShopAnalyticsModel analytics;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiData(
        icon: Icons.visibility_outlined,
        label: 'Total Views',
        value: '${analytics.totalViews}',
      ),
      _KpiData(
        icon: Icons.shopping_cart_outlined,
        label: 'Total Orders',
        value: '${analytics.totalOrders}',
      ),
      _KpiData(
        icon: Icons.currency_exchange_outlined,
        label: 'Revenue',
        value: 'LKR ${analytics.totalRevenueLKR.toStringAsFixed(2)}',
      ),
      _KpiData(
        icon: Icons.star_outline_rounded,
        label: 'Avg Rating',
        value: analytics.avgRating.toStringAsFixed(1),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final card in cards)
              SizedBox(
                width: cardWidth,
                child: _KpiCard(data: card),
              ),
          ],
        );
      },
    );
  }
}

class _KpiData {
  const _KpiData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});

  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, size: 20, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(data.label, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(
            data.value,
            style: AppTextStyles.heading3.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SalesOverTimeCard extends StatelessWidget {
  const _SalesOverTimeCard({required this.data});

  final List<DailySales> data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue Trend (Last 7 Days)', style: AppTextStyles.heading3),
          const SizedBox(height: 2),
          Text(
            'Track daily performance and revenue momentum.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(height: 180, child: _SalesLineChart(data: data)),
        ],
      ),
    );
  }
}

class _SalesLineChart extends StatelessWidget {
  const _SalesLineChart({required this.data});

  final List<DailySales> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No sales data yet.',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }

    final spots = data
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.revenueLKR))
        .toList();

    final maxY = data
        .map((item) => item.revenueLKR)
        .fold<double>(0, (currentMax, next) => math.max(currentMax, next));

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY <= 0 ? 1 : maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppColors.border, strokeWidth: 0.8),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (value, meta) => Text(
                'LKR ${(value / 1000).toStringAsFixed(0)}k',
                style: AppTextStyles.caption.copyWith(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= data.length) {
                  return const SizedBox.shrink();
                }
                return Text(
                  DateFormat('MMM d').format(data[index].date),
                  style: AppTextStyles.caption.copyWith(fontSize: 9),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) {
              return spots
                  .map(
                    (spot) => LineTooltipItem(
                      'LKR ${spot.y.toStringAsFixed(2)}',
                      AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  .toList();
            },
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
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductInsightsChartCard extends StatelessWidget {
  const _ProductInsightsChartCard({
    required this.products,
    required this.selectedMetric,
    required this.selectedProductId,
    required this.selectedProduct,
    required this.metricLabel,
    required this.metricValueOf,
    required this.onMetricChanged,
    required this.onProductChanged,
  });

  final List<TopProduct> products;
  final _ProductInsightMetric selectedMetric;
  final String? selectedProductId;
  final TopProduct? selectedProduct;
  final String metricLabel;
  final double Function(TopProduct) metricValueOf;
  final ValueChanged<_ProductInsightMetric> onMetricChanged;
  final ValueChanged<String> onProductChanged;

  String _shortLabel(String name) {
    if (name.length <= 8) return name;
    return '${name.substring(0, 8)}...';
  }

  String _metricDisplay(double value) {
    switch (selectedMetric) {
      case _ProductInsightMetric.revenue:
        return 'LKR ${value.toStringAsFixed(2)}';
      case _ProductInsightMetric.sales:
      case _ProductInsightMetric.views:
        return value.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Product Insights Comparison', style: AppTextStyles.heading3),
          const SizedBox(height: 2),
          Text(
            'Compare multiple products by revenue, sales, or views and inspect each product individually.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              for (final metric in _ProductInsightMetric.values)
                ChoiceChip(
                  label: Text(switch (metric) {
                    _ProductInsightMetric.revenue => 'Revenue',
                    _ProductInsightMetric.sales => 'Sales',
                    _ProductInsightMetric.views => 'Views',
                  }),
                  selected: selectedMetric == metric,
                  onSelected: (_) => onMetricChanged(metric),
                  selectedColor: AppColors.primary,
                  labelStyle: AppTextStyles.caption.copyWith(
                    color: selectedMetric == metric
                        ? AppColors.textOnPrimary
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  side: BorderSide(
                    color: selectedMetric == metric
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                  backgroundColor: AppColors.surface,
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            Text(
              'No product analytics available yet.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else ...[
            SizedBox(
              height: 200,
              child: _ProductBarChart(
                products: products,
                selectedProductId: selectedProductId,
                metricValueOf: metricValueOf,
                metricDisplay: _metricDisplay,
                shortLabel: _shortLabel,
                onProductChanged: onProductChanged,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final product in products)
                  GestureDetector(
                    onTap: () => onProductChanged(product.productId),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selectedProductId == product.productId
                            ? AppColors.primary
                            : AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _shortLabel(product.name),
                        style: AppTextStyles.caption.copyWith(
                          color: selectedProductId == product.productId
                              ? AppColors.textOnPrimary
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            if (selectedProduct != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedProduct!.name,
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _DetailMetric(
                          label: metricLabel,
                          value: _metricDisplay(
                            metricValueOf(selectedProduct!),
                          ),
                        ),
                        _DetailMetric(
                          label: 'Sales',
                          value: '${selectedProduct!.sales}',
                        ),
                        _DetailMetric(
                          label: 'Views',
                          value: '${selectedProduct!.views}',
                        ),
                        _DetailMetric(
                          label: 'Revenue',
                          value:
                              'LKR ${selectedProduct!.revenueLKR.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _ProductBarChart extends StatelessWidget {
  const _ProductBarChart({
    required this.products,
    required this.selectedProductId,
    required this.metricValueOf,
    required this.metricDisplay,
    required this.shortLabel,
    required this.onProductChanged,
  });

  final List<TopProduct> products;
  final String? selectedProductId;
  final double Function(TopProduct) metricValueOf;
  final String Function(double value) metricDisplay;
  final String Function(String name) shortLabel;
  final ValueChanged<String> onProductChanged;

  @override
  Widget build(BuildContext context) {
    final maxValue = products
        .map(metricValueOf)
        .fold<double>(0, (currentMax, next) => math.max(currentMax, next));

    return BarChart(
      BarChartData(
        maxY: maxValue <= 0 ? 1 : maxValue * 1.2,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: AppColors.border, strokeWidth: 0.8),
        ),
        borderData: FlBorderData(show: false),
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 46,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: AppTextStyles.caption.copyWith(fontSize: 9),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= products.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    shortLabel(products[index].name),
                    style: AppTextStyles.caption.copyWith(fontSize: 9),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final product = products[groupIndex];
              return BarTooltipItem(
                '${product.name}\n${metricDisplay(metricValueOf(product))}',
                AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
          touchCallback: (event, response) {
            final groupIndex = response?.spot?.touchedBarGroupIndex;
            if (groupIndex == null || groupIndex >= products.length) {
              return;
            }
            if (event.isInterestedForInteractions) {
              onProductChanged(products[groupIndex].productId);
            }
          },
        ),
        barGroups: List.generate(products.length, (index) {
          final product = products[index];
          final isSelected = selectedProductId == product.productId;
          return BarChartGroupData(
            x: index,
            showingTooltipIndicators: isSelected ? [0] : const [],
            barRods: [
              BarChartRodData(
                toY: metricValueOf(product),
                width: 16,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _CustomerActivityByTimeCard extends StatelessWidget {
  const _CustomerActivityByTimeCard({required this.activeByHour});

  final Map<String, int> activeByHour;

  String _formatHour(int hour) => hour.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final points = List.generate(
      24,
      (hour) => MapEntry(hour, activeByHour['$hour'] ?? 0),
    );

    final peak = points.fold<MapEntry<int, int>?>(null, (currentPeak, point) {
      if (currentPeak == null || point.value > currentPeak.value) {
        return point;
      }
      return currentPeak;
    });

    final maxCount = points
        .map((point) => point.value)
        .fold<int>(0, (currentMax, next) => math.max(currentMax, next));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Activity by Time', style: AppTextStyles.heading3),
          const SizedBox(height: 2),
          Text(
            'Hourly order activity throughout the day.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 190,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: maxCount <= 0 ? 1 : maxCount * 1.2,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: AppColors.border, strokeWidth: 0.8),
                ),
                borderData: FlBorderData(show: false),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final hour = points[groupIndex].key;
                      return BarTooltipItem(
                        '${_formatHour(hour)}:00-${_formatHour((hour + 1) % 24)}:00\n${points[groupIndex].value} orders',
                        AppTextStyles.caption.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: AppTextStyles.caption.copyWith(fontSize: 9),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final hour = value.toInt();
                        if (hour < 0 || hour > 23 || hour % 3 != 0) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _formatHour(hour),
                          style: AppTextStyles.caption.copyWith(fontSize: 8),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: points
                    .map(
                      (point) => BarChartGroupData(
                        x: point.key,
                        barRods: [
                          BarChartRodData(
                            toY: point.value.toDouble(),
                            width: 6,
                            borderRadius: BorderRadius.circular(4),
                            color: peak != null && peak.key == point.key
                                ? AppColors.primary
                                : AppColors.primaryContainer,
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            peak == null || peak.value == 0
                ? 'No peak activity hour available yet.'
                : 'Peak customer activity: ${_formatHour(peak.key)}:00-${_formatHour((peak.key + 1) % 24)}:00 (${peak.value} orders)',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerBehaviorSummaryCard extends StatelessWidget {
  const _CustomerBehaviorSummaryCard({required this.behavior});

  final CustomerBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Behavior Summary', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top viewed category',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _CategoryBadge(category: behavior.topViewedCategory),
                    const SizedBox(height: 12),
                    Text(
                      'Repeat customer rate',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(behavior.repeatCustomerRate * 100).toStringAsFixed(1)}%',
                      style: AppTextStyles.heading2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 76,
                height: 76,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: behavior.repeatCustomerRate * 100,
                        color: AppColors.primary,
                        radius: 11,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: (1 - behavior.repeatCustomerRate) * 100,
                        color: AppColors.border,
                        radius: 11,
                        showTitle: false,
                      ),
                    ],
                    centerSpaceRadius: 26,
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
    final displayCategory = category.trim().isEmpty
        ? 'N/A'
        : category[0].toUpperCase() + category.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayCategory,
        style: AppTextStyles.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AiInsightsCard extends StatelessWidget {
  const _AiInsightsCard({required this.insights});

  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Actionable Suggestions', style: AppTextStyles.heading3),
          const SizedBox(height: 10),
          if (insights.isEmpty)
            Text(
              'No suggestions available yet.',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            )
          else
            ...insights.map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.primary,
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyInsights extends StatelessWidget {
  const _EmptyInsights();

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
            'Start selling to unlock professional analytics dashboards.',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(14),
  border: Border.all(color: AppColors.border),
);
