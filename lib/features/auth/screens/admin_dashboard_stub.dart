import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/order_model.dart';
import '../../../models/product_model.dart';
import '../../../models/shop_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_logo.dart';

final NumberFormat _currencyLkr = NumberFormat.currency(
  locale: 'en_LK',
  symbol: 'LKR ',
  decimalDigits: 2,
);
final NumberFormat _compactNumber = NumberFormat.compact();
final DateFormat _dateShort = DateFormat('dd MMM');
final DateFormat _dateTimeShort = DateFormat('dd MMM, hh:mm a');

class AdminDashboardStub extends ConsumerStatefulWidget {
  const AdminDashboardStub({super.key});

  @override
  ConsumerState<AdminDashboardStub> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboardStub>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final _AdminRepository _repo;
  late Future<AdminDashboardData> _dashboardFuture;

  bool _isSigningOut = false;
  int _reportWindowDays = 30;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _repo = _AdminRepository(FirebaseFirestore.instance);
    _dashboardFuture = _repo.fetchDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Sora',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _refreshDashboard() {
    setState(() {
      _dashboardFuture = _repo.fetchDashboard();
    });
  }

  Future<void> _runAction({
    required Future<void> Function() action,
    required String successMessage,
    String? errorPrefix,
  }) async {
    try {
      await action();
      _showSnack(successMessage, AppColors.success);
      _refreshDashboard();
    } catch (e) {
      _showSnack(
        '${errorPrefix ?? 'Action failed'}: $e',
        AppColors.error,
      );
    }
  }

  Future<void> _updateUserStatus(String uid, String status) async {
    await _runAction(
      action: () => _repo.updateUserStatus(uid: uid, status: status),
      successMessage: 'User status updated to $status.',
      errorPrefix: 'Unable to update user status',
    );
  }

  Future<void> _updateUserRole(String uid, String role) async {
    await _runAction(
      action: () => _repo.updateUserRole(uid: uid, role: role),
      successMessage: 'User role changed to $role.',
      errorPrefix: 'Unable to update role',
    );
  }

  Future<void> _approveStore(AdminStorePerformance store) async {
    await _runAction(
      action: () => _repo.approveShop(store),
      successMessage: 'Store approved and activated.',
      errorPrefix: 'Unable to approve store',
    );
  }

  Future<void> _updateShopStatus(String shopId, String status) async {
    await _runAction(
      action: () => _repo.updateShopStatus(shopId: shopId, status: status),
      successMessage: 'Store status updated to $status.',
      errorPrefix: 'Unable to update store status',
    );
  }

  Future<void> _deactivateFlaggedProduct(String productId) async {
    await _runAction(
      action: () => _repo.deactivateFlaggedProduct(productId),
      successMessage: 'Flagged product deactivated.',
      errorPrefix: 'Unable to deactivate product',
    );
  }

  Future<void> _showRoleDialog(AdminUserPerformance userPerformance) async {
    String selectedRole = userPerformance.user.role;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Change Role', style: AppTextStyles.heading2),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userPerformance.user.displayName, style: AppTextStyles.body),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final role in const [
                        'customer',
                        'seller',
                        'designer',
                        'admin',
                      ])
                        ChoiceChip(
                          selected: selectedRole == role,
                          label: Text(_titleCase(role)),
                          onSelected: (_) {
                            setDialogState(() {
                              selectedRole = role;
                            });
                          },
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSave == true && selectedRole != userPerformance.user.role) {
      await _updateUserRole(userPerformance.user.uid, selectedRole);
    }
  }

  Future<void> _copyReportText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _showSnack('Report copied to clipboard.', AppColors.success);
  }

  Future<void> _logout() async {
    if (_isSigningOut) return;
    setState(() => _isSigningOut = true);

    try {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (mounted) {
        context.goNamed('login');
      }
    } catch (e) {
      _showSnack('Failed to sign out: $e', AppColors.error);
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const AppLogoTitle(
          title: 'Admin Console',
          textStyle: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _isSigningOut ? null : _logout,
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout, color: AppColors.textSecondary),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Financial'),
            Tab(text: 'Stores'),
            Tab(text: 'Users'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: FutureBuilder<AdminDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load admin dashboard.',
                      style: AppTextStyles.heading3,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: AppTextStyles.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshDashboard,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(
              child: Text(
                'No dashboard data available.',
                style: AppTextStyles.body,
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _AdminOverviewTab(data: data),
              _AdminFinancialTab(data: data),
              _AdminStoresTab(
                data: data,
                onApproveStore: _approveStore,
                onShopStatusChange: _updateShopStatus,
                onDeactivateFlaggedProduct: _deactivateFlaggedProduct,
              ),
              _AdminUsersTab(
                data: data,
                onStatusChange: _updateUserStatus,
                onRoleChangeRequested: _showRoleDialog,
              ),
              _AdminReportsTab(
                data: data,
                selectedWindowDays: _reportWindowDays,
                onWindowChanged: (days) {
                  setState(() {
                    _reportWindowDays = days;
                  });
                },
                onCopyReport: _copyReportText,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    final topStores = data.topStoresByRevenue.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiCard(
              title: 'Users',
              value: _compactNumber.format(data.totalUsers),
              subtitle: '${data.activeUsers} active',
              icon: Icons.people_outline,
              accent: AppColors.info,
            ),
            _KpiCard(
              title: 'Stores',
              value: _compactNumber.format(data.totalShops),
              subtitle: '${data.pendingShops} pending approvals',
              icon: Icons.storefront_outlined,
              accent: AppColors.primary,
            ),
            _KpiCard(
              title: 'Orders',
              value: _compactNumber.format(data.totalOrders),
              subtitle: '${(data.fulfillmentRate * 100).toStringAsFixed(1)}% fulfilled',
              icon: Icons.shopping_bag_outlined,
              accent: AppColors.warning,
            ),
            _KpiCard(
              title: 'Collected',
              value: _currencyLkr.format(data.collectedRevenueLKR),
              subtitle: 'Paid revenue',
              icon: Icons.payments_outlined,
              accent: AppColors.success,
            ),
            _KpiCard(
              title: 'Pending Actions',
              value: '${data.pendingShops + data.pendingSellerUsers + data.flaggedProducts.length}',
              subtitle: 'Queue across stores and users',
              icon: Icons.pending_actions_outlined,
              accent: AppColors.warning,
            ),
            _KpiCard(
              title: 'Flagged Products',
              value: '${data.flaggedProducts.length}',
              subtitle: 'Require moderation',
              icon: Icons.flag_outlined,
              accent: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Action Queue',
          subtitle: 'Operational items requiring admin attention right now.',
          child: Column(
            children: [
              _QueueItem(
                label: 'Pending seller applications',
                count: data.pendingSellerUsers,
              ),
              _QueueItem(label: 'Pending shop approvals', count: data.pendingShops),
              _QueueItem(
                label: 'Suspended stores',
                count: data.suspendedShops,
                isCritical: data.suspendedShops > 0,
              ),
              _QueueItem(
                label: 'Banned users',
                count: data.bannedUsers,
                isCritical: data.bannedUsers > 0,
              ),
              _QueueItem(
                label: 'Flagged active products',
                count: data.flaggedProducts.length,
                isCritical: data.flaggedProducts.isNotEmpty,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Admin Insights',
          subtitle: 'Automatically generated guidance from platform activity.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final insight in data.insights)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.bolt,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(insight, style: AppTextStyles.body)),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Top Stores by Revenue',
          subtitle: 'Use this to identify strategic partners and at-risk stores.',
          child: topStores.isEmpty
              ? const _EmptyStateText('No store performance data yet.')
              : Column(
                  children: [
                    for (final store in topStores)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    store.shop.name,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${store.orderCount} orders • ${store.activeProductCount} active products',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _currencyLkr.format(store.revenueLKR),
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.priceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AdminFinancialTab extends StatelessWidget {
  const _AdminFinancialTab({required this.data});

  final AdminDashboardData data;

  @override
  Widget build(BuildContext context) {
    final recentDays = data.dailySnapshots.reversed.take(10).toList();
    final topCustomers = data.topUsersBySpend.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _KpiCard(
              title: 'Gross Revenue',
              value: _currencyLkr.format(data.grossRevenueLKR),
              subtitle: 'Excludes cancelled orders',
              icon: Icons.account_balance_wallet_outlined,
              accent: AppColors.primary,
            ),
            _KpiCard(
              title: 'Collected',
              value: _currencyLkr.format(data.collectedRevenueLKR),
              subtitle: '${data.paidOrders} paid orders',
              icon: Icons.check_circle_outline,
              accent: AppColors.success,
            ),
            _KpiCard(
              title: 'Outstanding',
              value: _currencyLkr.format(data.outstandingRevenueLKR),
              subtitle: '${data.unpaidOrders} unpaid orders',
              icon: Icons.hourglass_bottom_outlined,
              accent: AppColors.warning,
            ),
            _KpiCard(
              title: 'Refunded',
              value: _currencyLkr.format(data.refundedRevenueLKR),
              subtitle: '${data.refundedOrders} refunded orders',
              icon: Icons.replay_circle_filled_outlined,
              accent: AppColors.error,
            ),
            _KpiCard(
              title: 'Average Order Value',
              value: _currencyLkr.format(data.averageOrderValueLKR),
              subtitle: 'Across ${data.totalOrders} orders',
              icon: Icons.auto_graph_outlined,
              accent: AppColors.info,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Payment Status Breakdown',
          subtitle: 'Track monetization quality and settlement risks.',
          child: Column(
            children: [
              _ProgressMeter(
                label: 'Paid',
                count: data.paidOrders,
                total: math.max(1, data.totalOrders),
                color: AppColors.success,
              ),
              const SizedBox(height: 10),
              _ProgressMeter(
                label: 'Unpaid',
                count: data.unpaidOrders,
                total: math.max(1, data.totalOrders),
                color: AppColors.warning,
              ),
              const SizedBox(height: 10),
              _ProgressMeter(
                label: 'Refunded',
                count: data.refundedOrders,
                total: math.max(1, data.totalOrders),
                color: AppColors.error,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Revenue Trend (Recent Days)',
          subtitle: 'Daily performance snapshot for rapid financial monitoring.',
          child: recentDays.isEmpty
              ? const _EmptyStateText('No daily trend data available.')
              : Column(
                  children: [
                    for (final day in recentDays)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 64,
                              child: Text(
                                _dateShort.format(day.day),
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${day.orders} orders',
                                style: AppTextStyles.body,
                              ),
                            ),
                            Text(
                              _currencyLkr.format(day.revenueLKR),
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.priceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Top Customers by Spend',
          subtitle: 'Useful for loyalty and retention targeting.',
          child: topCustomers.isEmpty
              ? const _EmptyStateText('No customer spend data yet.')
              : Column(
                  children: [
                    for (final customer in topCustomers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer.user.displayName,
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  Text(
                                    '${customer.orderCount} orders',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _currencyLkr.format(customer.spendLKR),
                              style: AppTextStyles.label.copyWith(
                                color: AppColors.priceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _AdminStoresTab extends StatefulWidget {
  const _AdminStoresTab({
    required this.data,
    required this.onApproveStore,
    required this.onShopStatusChange,
    required this.onDeactivateFlaggedProduct,
  });

  final AdminDashboardData data;
  final Future<void> Function(AdminStorePerformance store) onApproveStore;
  final Future<void> Function(String shopId, String status) onShopStatusChange;
  final Future<void> Function(String productId) onDeactivateFlaggedProduct;

  @override
  State<_AdminStoresTab> createState() => _AdminStoresTabState();
}

class _AdminStoresTabState extends State<_AdminStoresTab> {
  String _statusFilter = 'all';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filteredStores = widget.data.stores.where((store) {
      if (_statusFilter != 'all' && store.shop.status != _statusFilter) {
        return false;
      }

      if (_query.trim().isEmpty) {
        return true;
      }

      final q = _query.trim().toLowerCase();
      final ownerName = store.owner?.displayName.toLowerCase() ?? '';
      final ownerEmail = store.owner?.email.toLowerCase() ?? '';
      return store.shop.name.toLowerCase().contains(q) ||
          ownerName.contains(q) ||
          ownerEmail.contains(q) ||
          store.shop.city.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        if (a.shop.status == ShopStatus.pending && b.shop.status != ShopStatus.pending) {
          return -1;
        }
        if (a.shop.status != ShopStatus.pending && b.shop.status == ShopStatus.pending) {
          return 1;
        }
        return b.revenueLKR.compareTo(a.revenueLKR);
      });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Panel(
          title: 'Store Management',
          subtitle: 'Approve, suspend, and monitor store performance in one place.',
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by store, owner, email, or city',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final filter in const [
                      'all',
                      'pending',
                      'approved',
                      'active',
                      'suspended',
                    ])
                      ChoiceChip(
                        selected: _statusFilter == filter,
                        label: Text(_titleCase(filter)),
                        onSelected: (_) {
                          setState(() {
                            _statusFilter = filter;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (filteredStores.isEmpty)
          const _Panel(
            title: 'Stores',
            subtitle: 'Matching results',
            child: _EmptyStateText('No stores found for this filter.'),
          )
        else
          ...filteredStores.map(
            (store) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _StoreCard(
                store: store,
                onApprove: () => widget.onApproveStore(store),
                onShopStatusChange: widget.onShopStatusChange,
              ),
            ),
          ),
        const SizedBox(height: 4),
        _Panel(
          title: 'Flagged Product Moderation',
          subtitle: 'Products flagged by users and still active in the catalog.',
          child: widget.data.flaggedProducts.isEmpty
              ? const _EmptyStateText('No flagged active products.')
              : Column(
                  children: [
                    for (final product in widget.data.flaggedProducts)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      product.imageUrl!,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          _placeholderImage(),
                                    )
                                  : _placeholderImage(),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(product.name, style: AppTextStyles.bodyMedium),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Store: ${product.shopName ?? product.shopId}',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                  Text(
                                    _currencyLkr.format(product.price),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.priceColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => widget.onDeactivateFlaggedProduct(product.productId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(color: AppColors.error),
                              ),
                              child: const Text('Deactivate'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.surfaceVariant,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.textHint,
        size: 20,
      ),
    );
  }
}

class _AdminUsersTab extends StatefulWidget {
  const _AdminUsersTab({
    required this.data,
    required this.onStatusChange,
    required this.onRoleChangeRequested,
  });

  final AdminDashboardData data;
  final Future<void> Function(String uid, String status) onStatusChange;
  final Future<void> Function(AdminUserPerformance user) onRoleChangeRequested;

  @override
  State<_AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<_AdminUsersTab> {
  String _roleFilter = 'all';
  String _statusFilter = 'all';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filteredUsers = widget.data.usersPerformance.where((entry) {
      if (_roleFilter != 'all' && entry.user.role != _roleFilter) return false;
      if (_statusFilter != 'all' && entry.user.status != _statusFilter) {
        return false;
      }

      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return entry.user.displayName.toLowerCase().contains(q) ||
          entry.user.email.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.user.createdAt.compareTo(a.user.createdAt));

    final roleFilters = [
      'all',
      ...widget.data.roleCounts.keys.toList()..sort(),
    ];
    final statusFilters = [
      'all',
      ...widget.data.userStatusCounts.keys.toList()..sort(),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Panel(
          title: 'Categorized User Management',
          subtitle: 'Filter by role and status, then apply moderation actions quickly.',
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    _query = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Role filter',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final role in roleFilters)
                      ChoiceChip(
                        selected: _roleFilter == role,
                        label: Text(
                          role == 'all'
                              ? 'All (${widget.data.totalUsers})'
                              : '${_titleCase(role)} (${widget.data.roleCounts[role] ?? 0})',
                        ),
                        onSelected: (_) {
                          setState(() {
                            _roleFilter = role;
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Status filter',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final status in statusFilters)
                      ChoiceChip(
                        selected: _statusFilter == status,
                        label: Text(
                          status == 'all'
                              ? 'All (${widget.data.totalUsers})'
                              : '${_titleCase(status)} (${widget.data.userStatusCounts[status] ?? 0})',
                        ),
                        onSelected: (_) {
                          setState(() {
                            _statusFilter = status;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filteredUsers.isEmpty)
          const _Panel(
            title: 'Users',
            subtitle: 'Filtered result',
            child: _EmptyStateText('No users match the selected filters.'),
          )
        else
          ...filteredUsers.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _UserPerformanceCard(
                user: user,
                onChangeRole: () => widget.onRoleChangeRequested(user),
                onBan: () => widget.onStatusChange(user.user.uid, 'banned'),
                onUnban: () => widget.onStatusChange(user.user.uid, 'active'),
                onActivate: () => widget.onStatusChange(user.user.uid, 'active'),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminReportsTab extends StatelessWidget {
  const _AdminReportsTab({
    required this.data,
    required this.selectedWindowDays,
    required this.onWindowChanged,
    required this.onCopyReport,
  });

  final AdminDashboardData data;
  final int selectedWindowDays;
  final ValueChanged<int> onWindowChanged;
  final Future<void> Function(String text) onCopyReport;

  @override
  Widget build(BuildContext context) {
    final metrics = data.metricsForWindow(selectedWindowDays);
    final reportText = data.generateReport(windowDays: selectedWindowDays);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Panel(
          title: 'Admin Reports',
          subtitle: 'Generate strategic summaries from the latest platform snapshot.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final days in const [7, 30, 90])
                    ChoiceChip(
                      selected: selectedWindowDays == days,
                      label: Text('Last $days days'),
                      onSelected: (_) => onWindowChanged(days),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _ReportMetricCard(
                    title: 'Revenue',
                    value: _currencyLkr.format(metrics.revenue),
                    delta: _formatDelta(metrics.revenueGrowthPct),
                  ),
                  _ReportMetricCard(
                    title: 'Orders',
                    value: '${metrics.orders}',
                    delta: _formatDelta(metrics.orderGrowthPct),
                  ),
                  _ReportMetricCard(
                    title: 'New Users',
                    value: '${metrics.newUsers}',
                    delta: _formatDelta(metrics.newUsersGrowthPct),
                  ),
                  _ReportMetricCard(
                    title: 'New Stores',
                    value: '${metrics.newShops}',
                    delta: _formatDelta(metrics.newShopsGrowthPct),
                  ),
                  _ReportMetricCard(
                    title: 'Refunded Orders',
                    value: '${metrics.refunds}',
                    delta: _formatDelta(metrics.refundGrowthPct),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Generated Executive Report',
          subtitle: 'Share this with business stakeholders or leadership.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(reportText, style: AppTextStyles.body),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => onCopyReport(reportText),
                icon: const Icon(Icons.copy_all_outlined),
                label: const Text('Copy report'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StoreCard extends StatelessWidget {
  const _StoreCard({
    required this.store,
    required this.onApprove,
    required this.onShopStatusChange,
  });

  final AdminStorePerformance store;
  final Future<void> Function() onApprove;
  final Future<void> Function(String shopId, String status) onShopStatusChange;

  @override
  Widget build(BuildContext context) {
    final status = store.shop.status;

    return _Panel(
      title: store.shop.name,
      subtitle:
          'Owner: ${store.owner?.displayName ?? 'Unknown'} • ${store.shop.city}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusPill(label: _titleCase(status), color: _shopStatusColor(status)),
              _StatusPill(
                label: '${store.shop.categories.length} categories',
                color: AppColors.info,
              ),
              _StatusPill(
                label: 'Rating ${store.shop.avgRating.toStringAsFixed(1)}',
                color: AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MiniMetric(
                label: 'Revenue',
                value: _currencyLkr.format(store.revenueLKR),
              ),
              _MiniMetric(label: 'Orders', value: '${store.orderCount}'),
              _MiniMetric(
                label: 'Products',
                value: '${store.activeProductCount}/${store.productCount}',
              ),
              _MiniMetric(
                label: 'Last Order',
                value: store.lastOrderAt == null
                    ? 'N/A'
                    : _dateShort.format(store.lastOrderAt!),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (status == ShopStatus.pending)
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.verified_outlined),
                  label: const Text('Approve & Activate'),
                ),
              if (status == ShopStatus.approved)
                ElevatedButton.icon(
                  onPressed: () => onShopStatusChange(store.shop.shopId, ShopStatus.active),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Activate'),
                ),
              if (status == ShopStatus.active)
                OutlinedButton.icon(
                  onPressed: () => onShopStatusChange(store.shop.shopId, ShopStatus.suspended),
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('Suspend'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                ),
              if (status == ShopStatus.suspended)
                OutlinedButton.icon(
                  onPressed: () => onShopStatusChange(store.shop.shopId, ShopStatus.active),
                  icon: const Icon(Icons.replay_circle_filled_outlined),
                  label: const Text('Reactivate'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.success,
                    side: const BorderSide(color: AppColors.success),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserPerformanceCard extends StatelessWidget {
  const _UserPerformanceCard({
    required this.user,
    required this.onChangeRole,
    required this.onBan,
    required this.onUnban,
    required this.onActivate,
  });

  final AdminUserPerformance user;
  final Future<void> Function() onChangeRole;
  final Future<void> Function() onBan;
  final Future<void> Function() onUnban;
  final Future<void> Function() onActivate;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: user.user.displayName,
      subtitle: user.user.email,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusPill(
                      label: _titleCase(user.user.role),
                      color: _roleColor(user.user.role),
                    ),
                    _StatusPill(
                      label: _titleCase(user.user.status),
                      color: _userStatusColor(user.user.status),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Orders: ${user.orderCount}  •  Spend: ${_currencyLkr.format(user.spendLKR)}',
                  style: AppTextStyles.bodySmall,
                ),
                Text(
                  'Joined: ${_dateShort.format(user.user.createdAt)}${user.lastOrderAt != null ? '  •  Last order: ${_dateTimeShort.format(user.lastOrderAt!)}' : ''}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
            onSelected: (value) {
              switch (value) {
                case 'role':
                  onChangeRole();
                  break;
                case 'ban':
                  onBan();
                  break;
                case 'unban':
                  onUnban();
                  break;
                case 'activate':
                  onActivate();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'role',
                child: Text('Change role'),
              ),
              if (user.user.status != 'banned')
                const PopupMenuItem<String>(
                  value: 'ban',
                  child: Text('Ban user'),
                )
              else
                const PopupMenuItem<String>(
                  value: 'unban',
                  child: Text('Unban user'),
                ),
              if (user.user.status != 'active')
                const PopupMenuItem<String>(
                  value: 'activate',
                  child: Text('Set active'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading3),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 44) / 2;
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textPrimary,
              fontSize: 17,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  const _QueueItem({
    required this.label,
    required this.count,
    this.isCritical = false,
  });

  final String label;
  final int count;
  final bool isCritical;

  @override
  Widget build(BuildContext context) {
    final color = isCritical ? AppColors.error : AppColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMeter extends StatelessWidget {
  const _ProgressMeter({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  final String label;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : count / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: AppTextStyles.body)),
            Text(
              '$count (${(progress * 100).toStringAsFixed(1)}%)',
              style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.surfaceVariant,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReportMetricCard extends StatelessWidget {
  const _ReportMetricCard({
    required this.title,
    required this.value,
    required this.delta,
  });

  final String title;
  final String value;
  final String delta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodySmall),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 2),
          Text(
            delta,
            style: AppTextStyles.bodySmall.copyWith(
              color: delta.startsWith('+')
                  ? AppColors.success
                  : (delta == '0.0%' ? AppColors.textSecondary : AppColors.error),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateText extends StatelessWidget {
  const _EmptyStateText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.bodySmall);
  }
}

class _AdminRepository {
  _AdminRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<AdminDashboardData> fetchDashboard() async {
    final usersSnap = await _firestore.collection(FirestorePaths.users).get();
    final shopsSnap = await _firestore.collection(FirestorePaths.shops).get();
    final ordersSnap = await _firestore.collection(FirestorePaths.orders).get();
    final productsSnap = await _firestore.collection(FirestorePaths.products).get();

    final users = <UserModel>[];
    for (final doc in usersSnap.docs) {
      try {
        users.add(UserModel.fromMap(_asMap(doc.data()), doc.id));
      } catch (_) {
        // Skip malformed user docs to avoid breaking the admin dashboard.
      }
    }

    final shops = <ShopModel>[];
    for (final doc in shopsSnap.docs) {
      try {
        shops.add(ShopModel.fromMap(_asMap(doc.data()), doc.id));
      } catch (_) {
        // Skip malformed shop docs to keep dashboard resilient.
      }
    }

    final orders = <OrderModel>[];
    for (final doc in ordersSnap.docs) {
      try {
        orders.add(OrderModel.fromMap(_asMap(doc.data()), doc.id));
      } catch (_) {
        // Skip malformed order docs.
      }
    }

    final products = <ProductModel>[];
    final flaggedProducts = <AdminProductModerationItem>[];
    for (final doc in productsSnap.docs) {
      final map = _asMap(doc.data());
      try {
        products.add(ProductModel.fromMap(map, doc.id));
      } catch (_) {
        // Skip malformed product docs for performance aggregations.
      }

      final isFlagged = map['isFlagged'] as bool? ?? false;
      final isActive = map['isActive'] as bool? ?? true;
      if (isFlagged && isActive) {
        flaggedProducts.add(
          AdminProductModerationItem(
            productId: doc.id,
            shopId: map['shopId'] as String? ?? '',
            name: map['name'] as String? ?? 'Unnamed product',
            imageUrl: (map['images'] as List?)?.isNotEmpty == true
                ? (map['images'] as List).first as String?
                : null,
            price: (map['price'] as num?)?.toDouble() ?? 0,
          ),
        );
      }
    }

    return AdminDashboardData.fromRaw(
      users: users,
      shops: shops,
      orders: orders,
      products: products,
      flaggedProducts: flaggedProducts,
      generatedAt: DateTime.now(),
    );
  }

  Future<void> updateUserStatus({required String uid, required String status}) {
    return _firestore.doc(FirestorePaths.userDoc(uid)).update({'status': status});
  }

  Future<void> updateUserRole({required String uid, required String role}) {
    return _firestore.doc(FirestorePaths.userDoc(uid)).update({'role': role});
  }

  Future<void> approveShop(AdminStorePerformance store) async {
    final batch = _firestore.batch();
    batch.update(_firestore.doc(FirestorePaths.shopDoc(store.shop.shopId)), {
      'status': ShopStatus.active,
    });
    final owner = store.owner;
    if (owner != null) {
      batch.update(_firestore.doc(FirestorePaths.userDoc(owner.uid)), {
        'role': 'seller',
        'status': 'active',
      });
    }
    await batch.commit();
  }

  Future<void> updateShopStatus({required String shopId, required String status}) {
    return _firestore.doc(FirestorePaths.shopDoc(shopId)).update({'status': status});
  }

  Future<void> deactivateFlaggedProduct(String productId) {
    return _firestore.doc(FirestorePaths.productDoc(productId)).update({
      'isActive': false,
      'isFlagged': false,
    });
  }
}

class AdminDashboardData {
  const AdminDashboardData({
    required this.generatedAt,
    required this.users,
    required this.shops,
    required this.orders,
    required this.products,
    required this.flaggedProducts,
    required this.stores,
    required this.usersPerformance,
    required this.dailySnapshots,
    required this.roleCounts,
    required this.userStatusCounts,
    required this.shopStatusCounts,
    required this.paymentStatusCounts,
    required this.orderStatusCounts,
    required this.insights,
  });

  final DateTime generatedAt;
  final List<UserModel> users;
  final List<ShopModel> shops;
  final List<OrderModel> orders;
  final List<ProductModel> products;
  final List<AdminProductModerationItem> flaggedProducts;
  final List<AdminStorePerformance> stores;
  final List<AdminUserPerformance> usersPerformance;
  final List<AdminDailySnapshot> dailySnapshots;
  final Map<String, int> roleCounts;
  final Map<String, int> userStatusCounts;
  final Map<String, int> shopStatusCounts;
  final Map<String, int> paymentStatusCounts;
  final Map<String, int> orderStatusCounts;
  final List<String> insights;

  factory AdminDashboardData.fromRaw({
    required DateTime generatedAt,
    required List<UserModel> users,
    required List<ShopModel> shops,
    required List<OrderModel> orders,
    required List<ProductModel> products,
    required List<AdminProductModerationItem> flaggedProducts,
  }) {
    final usersById = {for (final user in users) user.uid: user};

    final productsByShop = <String, List<ProductModel>>{};
    for (final product in products) {
      productsByShop.putIfAbsent(product.shopId, () => []).add(product);
    }

    final ordersByShop = <String, List<OrderModel>>{};
    final ordersByCustomer = <String, List<OrderModel>>{};
    for (final order in orders) {
      ordersByShop.putIfAbsent(order.shopId, () => []).add(order);
      ordersByCustomer.putIfAbsent(order.customerId, () => []).add(order);
    }

    final stores = shops
        .map((shop) {
          final shopOrders = ordersByShop[shop.shopId] ?? const <OrderModel>[];
          final shopProducts = productsByShop[shop.shopId] ?? const <ProductModel>[];
          final revenue = shopOrders
              .where((order) => order.status != 'cancelled')
              .fold<double>(0, (totalValue, order) => totalValue + order.totalLKR);

          DateTime? lastOrderAt;
          for (final order in shopOrders) {
            if (lastOrderAt == null || order.createdAt.isAfter(lastOrderAt)) {
              lastOrderAt = order.createdAt;
            }
          }

          return AdminStorePerformance(
            shop: shop,
            owner: usersById[shop.ownerId],
            productCount: shopProducts.length,
            activeProductCount: shopProducts.where((p) => p.isActive).length,
            orderCount: shopOrders.length,
            paidOrderCount: shopOrders.where((o) => o.paymentStatus == 'paid').length,
            revenueLKR: revenue,
            lastOrderAt: lastOrderAt,
          );
        })
        .toList()
      ..sort((a, b) => b.revenueLKR.compareTo(a.revenueLKR));

    final usersPerformance = users
        .map((user) {
          final userOrders = ordersByCustomer[user.uid] ?? const <OrderModel>[];
          final spend = userOrders
              .where((order) => order.paymentStatus == 'paid')
              .fold<double>(0, (totalValue, order) => totalValue + order.totalLKR);

          DateTime? lastOrderAt;
          for (final order in userOrders) {
            if (lastOrderAt == null || order.createdAt.isAfter(lastOrderAt)) {
              lastOrderAt = order.createdAt;
            }
          }

          return AdminUserPerformance(
            user: user,
            orderCount: userOrders.length,
            spendLKR: spend,
            lastOrderAt: lastOrderAt,
          );
        })
        .toList()
      ..sort((a, b) => b.spendLKR.compareTo(a.spendLKR));

    final roleCounts = _countBy(users.map((user) => user.role));
    final userStatusCounts = _countBy(users.map((user) => user.status));
    final shopStatusCounts = _countBy(shops.map((shop) => shop.status));
    final paymentStatusCounts = _countBy(
      orders.map((order) => order.paymentStatus),
    );
    final orderStatusCounts = _countBy(orders.map((order) => order.status));

    final dailySnapshots = _buildDailySnapshots(
      orders: orders,
      users: users,
      shops: shops,
      days: 14,
    );

    final pendingShops = shops.where((shop) => shop.status == ShopStatus.pending).length;
    final bannedUsers = users.where((user) => user.status == 'banned').length;
    final pendingSellers = users
        .where((user) => user.role == 'seller' && user.status == 'pending')
        .length;
    final refundedOrders = orders
        .where((order) => order.paymentStatus == 'refunded')
        .length;

    final insights = <String>[
      if (pendingShops > 0)
        '$pendingShops stores are waiting for approval. Clearing this queue can accelerate seller onboarding.',
      if (pendingSellers > 0)
        '$pendingSellers seller accounts remain in pending state and may need profile or KYC verification.',
      if (flaggedProducts.isNotEmpty)
        '${flaggedProducts.length} active products are flagged and should be moderated to protect marketplace trust.',
      if (refundedOrders > 0)
        '$refundedOrders refunded orders detected. Review payment workflows and product quality controls.',
      if (stores.isNotEmpty)
        'Top revenue store: ${stores.first.shop.name} (${_currencyLkr.format(stores.first.revenueLKR)}). Consider featuring it in campaigns.',
      if (bannedUsers > 0)
        '$bannedUsers users are currently banned. Monitor repeated abuse signals and false positives.',
    ];

    if (insights.isEmpty) {
      insights.add('Platform health looks stable. Keep monitoring growth and operational queues.');
    }

    return AdminDashboardData(
      generatedAt: generatedAt,
      users: users,
      shops: shops,
      orders: orders,
      products: products,
      flaggedProducts: flaggedProducts,
      stores: stores,
      usersPerformance: usersPerformance,
      dailySnapshots: dailySnapshots,
      roleCounts: roleCounts,
      userStatusCounts: userStatusCounts,
      shopStatusCounts: shopStatusCounts,
      paymentStatusCounts: paymentStatusCounts,
      orderStatusCounts: orderStatusCounts,
      insights: insights,
    );
  }

  int get totalUsers => users.length;
  int get activeUsers => userStatusCounts['active'] ?? 0;
  int get bannedUsers => userStatusCounts['banned'] ?? 0;
  int get pendingSellerUsers => users
      .where((user) => user.role == 'seller' && user.status == 'pending')
      .length;

  int get totalShops => shops.length;
  int get pendingShops => shopStatusCounts[ShopStatus.pending] ?? 0;
  int get activeShops => shopStatusCounts[ShopStatus.active] ?? 0;
  int get suspendedShops => shopStatusCounts[ShopStatus.suspended] ?? 0;

  int get totalOrders => orders.length;
  int get paidOrders => paymentStatusCounts['paid'] ?? 0;
  int get unpaidOrders => paymentStatusCounts['unpaid'] ?? 0;
  int get refundedOrders => paymentStatusCounts['refunded'] ?? 0;

  double get grossRevenueLKR => orders
      .where((order) => order.status != 'cancelled')
      .fold<double>(0, (totalValue, order) => totalValue + order.totalLKR);

  double get collectedRevenueLKR => orders
      .where((order) => order.paymentStatus == 'paid')
      .fold<double>(0, (totalValue, order) => totalValue + order.totalLKR);

  double get refundedRevenueLKR => orders
      .where((order) => order.paymentStatus == 'refunded')
      .fold<double>(0, (totalValue, order) => totalValue + order.totalLKR);

  double get outstandingRevenueLKR => math.max(
    0,
    grossRevenueLKR - collectedRevenueLKR,
  );

  double get averageOrderValueLKR =>
      totalOrders == 0 ? 0 : grossRevenueLKR / totalOrders;

  double get fulfillmentRate {
    if (totalOrders == 0) return 0;
    final fulfilled = orders
        .where((order) =>
            order.status == 'shipped' || order.status == 'delivered')
        .length;
    return fulfilled / totalOrders;
  }

  List<AdminStorePerformance> get topStoresByRevenue {
    final sorted = [...stores]..sort((a, b) => b.revenueLKR.compareTo(a.revenueLKR));
    return sorted;
  }

  List<AdminUserPerformance> get topUsersBySpend {
    final sorted = [...usersPerformance]
      ..sort((a, b) => b.spendLKR.compareTo(a.spendLKR));
    return sorted;
  }

  AdminWindowMetrics metricsForWindow(int windowDays) {
    final end = DateTime.now();
    final currentStart = end.subtract(Duration(days: windowDays));
    final previousStart = currentStart.subtract(Duration(days: windowDays));

    final currentOrders = orders
        .where((order) => order.createdAt.isAfter(currentStart))
        .toList();
    final previousOrders = orders
        .where(
          (order) =>
              order.createdAt.isAfter(previousStart) &&
              order.createdAt.isBefore(currentStart),
        )
        .toList();

    final currentUsers = users
        .where((user) => user.createdAt.isAfter(currentStart))
        .length;
    final previousUsers = users
        .where(
          (user) =>
              user.createdAt.isAfter(previousStart) &&
              user.createdAt.isBefore(currentStart),
        )
        .length;

    final currentShops = shops
        .where((shop) => shop.createdAt.isAfter(currentStart))
        .length;
    final previousShops = shops
        .where(
          (shop) =>
              shop.createdAt.isAfter(previousStart) &&
              shop.createdAt.isBefore(currentStart),
        )
        .length;

    final revenue = currentOrders
        .where((order) => order.status != 'cancelled')
      .fold<double>(0, (totalValue, order) => totalValue + order.totalLKR);
    final previousRevenue = previousOrders
        .where((order) => order.status != 'cancelled')
      .fold<double>(0, (totalValue, order) => totalValue + order.totalLKR);

    final refunds = currentOrders
        .where((order) => order.paymentStatus == 'refunded')
        .length;
    final previousRefunds = previousOrders
        .where((order) => order.paymentStatus == 'refunded')
        .length;

    return AdminWindowMetrics(
      windowDays: windowDays,
      orders: currentOrders.length,
      previousOrders: previousOrders.length,
      revenue: revenue,
      previousRevenue: previousRevenue,
      newUsers: currentUsers,
      previousNewUsers: previousUsers,
      newShops: currentShops,
      previousNewShops: previousShops,
      refunds: refunds,
      previousRefunds: previousRefunds,
    );
  }

  String generateReport({required int windowDays}) {
    final metrics = metricsForWindow(windowDays);
    final topStore = topStoresByRevenue.isEmpty ? null : topStoresByRevenue.first;
    final topCustomer = topUsersBySpend.isEmpty ? null : topUsersBySpend.first;

    final buffer = StringBuffer()
      ..writeln('CEYLON MARKETPLACE - ADMIN REPORT')
      ..writeln('Generated: ${_dateTimeShort.format(generatedAt)}')
      ..writeln('Window: Last $windowDays days')
      ..writeln('')
      ..writeln('1) EXECUTIVE SUMMARY')
      ..writeln('- Revenue: ${_currencyLkr.format(metrics.revenue)} (${_formatDelta(metrics.revenueGrowthPct)})')
      ..writeln('- Orders: ${metrics.orders} (${_formatDelta(metrics.orderGrowthPct)})')
      ..writeln('- New users: ${metrics.newUsers} (${_formatDelta(metrics.newUsersGrowthPct)})')
      ..writeln('- New stores: ${metrics.newShops} (${_formatDelta(metrics.newShopsGrowthPct)})')
      ..writeln('- Refunded orders: ${metrics.refunds} (${_formatDelta(metrics.refundGrowthPct)})')
      ..writeln('')
      ..writeln('2) FINANCIAL OVERVIEW')
      ..writeln('- Gross revenue to date: ${_currencyLkr.format(grossRevenueLKR)}')
      ..writeln('- Collected revenue to date: ${_currencyLkr.format(collectedRevenueLKR)}')
      ..writeln('- Outstanding revenue to date: ${_currencyLkr.format(outstandingRevenueLKR)}')
      ..writeln('- Average order value: ${_currencyLkr.format(averageOrderValueLKR)}')
      ..writeln('')
      ..writeln('3) STORE MANAGEMENT')
      ..writeln('- Total stores: $totalShops')
      ..writeln('- Active stores: $activeShops')
      ..writeln('- Pending stores: $pendingShops')
      ..writeln('- Suspended stores: $suspendedShops')
      ..writeln('- Flagged active products: ${flaggedProducts.length}')
      ..writeln('')
      ..writeln('4) USER MANAGEMENT')
      ..writeln('- Total users: $totalUsers')
      ..writeln('- Active users: $activeUsers')
      ..writeln('- Banned users: $bannedUsers')
      ..writeln('- Pending seller accounts: $pendingSellerUsers')
      ..writeln('')
      ..writeln('5) TOP PERFORMERS');

    if (topStore != null) {
      buffer.writeln(
        '- Store: ${topStore.shop.name} • ${_currencyLkr.format(topStore.revenueLKR)} • ${topStore.orderCount} orders',
      );
    } else {
      buffer.writeln('- Store: No data');
    }

    if (topCustomer != null) {
      buffer.writeln(
        '- Customer: ${topCustomer.user.displayName} • ${_currencyLkr.format(topCustomer.spendLKR)} • ${topCustomer.orderCount} orders',
      );
    } else {
      buffer.writeln('- Customer: No data');
    }

    buffer
      ..writeln('')
      ..writeln('6) INSIGHTS')
      ..writeln(insights.map((insight) => '- $insight').join('\n'));

    return buffer.toString();
  }

  static Map<String, int> _countBy(Iterable<String> values) {
    final map = <String, int>{};
    for (final value in values) {
      map[value] = (map[value] ?? 0) + 1;
    }
    return map;
  }

  static List<AdminDailySnapshot> _buildDailySnapshots({
    required List<OrderModel> orders,
    required List<UserModel> users,
    required List<ShopModel> shops,
    required int days,
  }) {
    final now = DateTime.now();
    final dayBuckets = <DateTime, AdminDailySnapshot>{};
    for (int i = 0; i < days; i++) {
      final day = DateTime(now.year, now.month, now.day - i);
      dayBuckets[day] = AdminDailySnapshot(
        day: day,
        orders: 0,
        revenueLKR: 0,
        newUsers: 0,
        newShops: 0,
      );
    }

    for (final order in orders) {
      final day = DateTime(
        order.createdAt.year,
        order.createdAt.month,
        order.createdAt.day,
      );
      final snapshot = dayBuckets[day];
      if (snapshot == null) continue;
      dayBuckets[day] = snapshot.copyWith(
        orders: snapshot.orders + 1,
        revenueLKR: snapshot.revenueLKR + order.totalLKR,
      );
    }

    for (final user in users) {
      final day = DateTime(user.createdAt.year, user.createdAt.month, user.createdAt.day);
      final snapshot = dayBuckets[day];
      if (snapshot == null) continue;
      dayBuckets[day] = snapshot.copyWith(newUsers: snapshot.newUsers + 1);
    }

    for (final shop in shops) {
      final day = DateTime(shop.createdAt.year, shop.createdAt.month, shop.createdAt.day);
      final snapshot = dayBuckets[day];
      if (snapshot == null) continue;
      dayBuckets[day] = snapshot.copyWith(newShops: snapshot.newShops + 1);
    }

    final list = dayBuckets.values.toList()
      ..sort((a, b) => a.day.compareTo(b.day));
    return list;
  }
}

class AdminStorePerformance {
  const AdminStorePerformance({
    required this.shop,
    required this.owner,
    required this.productCount,
    required this.activeProductCount,
    required this.orderCount,
    required this.paidOrderCount,
    required this.revenueLKR,
    required this.lastOrderAt,
  });

  final ShopModel shop;
  final UserModel? owner;
  final int productCount;
  final int activeProductCount;
  final int orderCount;
  final int paidOrderCount;
  final double revenueLKR;
  final DateTime? lastOrderAt;
}

class AdminUserPerformance {
  const AdminUserPerformance({
    required this.user,
    required this.orderCount,
    required this.spendLKR,
    required this.lastOrderAt,
  });

  final UserModel user;
  final int orderCount;
  final double spendLKR;
  final DateTime? lastOrderAt;
}

class AdminProductModerationItem {
  const AdminProductModerationItem({
    required this.productId,
    required this.shopId,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.shopName,
  });

  final String productId;
  final String shopId;
  final String name;
  final String? imageUrl;
  final double price;
  final String? shopName;
}

class AdminDailySnapshot {
  const AdminDailySnapshot({
    required this.day,
    required this.orders,
    required this.revenueLKR,
    required this.newUsers,
    required this.newShops,
  });

  final DateTime day;
  final int orders;
  final double revenueLKR;
  final int newUsers;
  final int newShops;

  AdminDailySnapshot copyWith({
    DateTime? day,
    int? orders,
    double? revenueLKR,
    int? newUsers,
    int? newShops,
  }) {
    return AdminDailySnapshot(
      day: day ?? this.day,
      orders: orders ?? this.orders,
      revenueLKR: revenueLKR ?? this.revenueLKR,
      newUsers: newUsers ?? this.newUsers,
      newShops: newShops ?? this.newShops,
    );
  }
}

class AdminWindowMetrics {
  const AdminWindowMetrics({
    required this.windowDays,
    required this.orders,
    required this.previousOrders,
    required this.revenue,
    required this.previousRevenue,
    required this.newUsers,
    required this.previousNewUsers,
    required this.newShops,
    required this.previousNewShops,
    required this.refunds,
    required this.previousRefunds,
  });

  final int windowDays;
  final int orders;
  final int previousOrders;
  final double revenue;
  final double previousRevenue;
  final int newUsers;
  final int previousNewUsers;
  final int newShops;
  final int previousNewShops;
  final int refunds;
  final int previousRefunds;

  double get orderGrowthPct => _growthPercent(orders, previousOrders);
  double get revenueGrowthPct => _growthPercent(revenue, previousRevenue);
  double get newUsersGrowthPct => _growthPercent(newUsers, previousNewUsers);
  double get newShopsGrowthPct => _growthPercent(newShops, previousNewShops);
  double get refundGrowthPct => _growthPercent(refunds, previousRefunds);

  static double _growthPercent(num current, num previous) {
    if (previous == 0) {
      return current == 0 ? 0 : 100;
    }
    return ((current - previous) / previous) * 100;
  }
}

Map<String, dynamic> _asMap(Object? raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

Color _roleColor(String role) {
  switch (role) {
    case 'admin':
      return const Color(0xFF6C3483);
    case 'seller':
      return AppColors.primary;
    case 'designer':
      return const Color(0xFF117A65);
    default:
      return const Color(0xFF1A5276);
  }
}

Color _userStatusColor(String status) {
  switch (status) {
    case 'active':
      return AppColors.success;
    case 'banned':
      return AppColors.error;
    case 'pending':
      return AppColors.warning;
    default:
      return AppColors.textSecondary;
  }
}

Color _shopStatusColor(String status) {
  switch (status) {
    case ShopStatus.active:
      return AppColors.success;
    case ShopStatus.pending:
      return AppColors.warning;
    case ShopStatus.suspended:
      return AppColors.error;
    case ShopStatus.approved:
      return AppColors.info;
    default:
      return AppColors.textSecondary;
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  final words = value.split(RegExp(r'[_\s]+'));
  return words
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

String _formatDelta(double value) {
  if (value == 0) return '0.0%';
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(1)}%';
}
