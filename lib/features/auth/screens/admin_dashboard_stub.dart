import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';

class AdminDashboardStub extends ConsumerStatefulWidget {
  const AdminDashboardStub({super.key});

  @override
  ConsumerState<AdminDashboardStub> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboardStub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _updateUserStatus(String uid, String status) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).update({'status': status});
  }

  Future<void> _updateUserRole(String uid, String role) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).update({'role': role});
  }

  Future<void> _approveSeller(String uid) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).update({
      'status': 'active',
      'role': 'seller',
    });
    if (mounted) {
      _showSnack('Seller approved successfully', AppColors.success);
    }
  }

  Future<void> _rejectSeller(String uid) async {
    await _firestore.doc(FirestorePaths.userDoc(uid)).update({
      'status': 'rejected',
      'role': 'customer',
    });
    if (mounted) {
      _showSnack('Seller application rejected', AppColors.error);
    }
  }

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontFamily: 'Sora', color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showRoleDialog(UserModel user) {
    String selected = user.role;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Change Role',
              style: const TextStyle(
                  fontFamily: 'Sora',
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.displayName,
                  style: const TextStyle(
                      fontFamily: 'Sora', color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              for (final role in ['customer', 'seller', 'designer', 'admin'])
                RadioListTile<String>(
                  title: Text(role,
                      style: const TextStyle(
                          fontFamily: 'Sora',
                          color: AppColors.textPrimary)),
                  value: role,
                  groupValue: selected,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setDialog(() => selected = v!),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(
                      fontFamily: 'Sora', color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateUserRole(user.uid, selected);
                if (mounted) Navigator.pop(ctx);
                _showSnack('Role updated to $selected', AppColors.success);
              },
              child: const Text('Save',
                  style: TextStyle(fontFamily: 'Sora')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final admin = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontFamily: 'Sora',
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).signOut();
              if (mounted) context.goNamed('login');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: const TextStyle(
              fontFamily: 'Sora', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Users'),
            Tab(text: 'Sellers'),
            Tab(text: 'Flagged'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UsersTab(
            firestore: _firestore,
            onRoleChange: _showRoleDialog,
            onStatusChange: _updateUserStatus,
            showSnack: _showSnack,
          ),
          _SellersTab(
            firestore: _firestore,
            onApprove: _approveSeller,
            onReject: _rejectSeller,
          ),
          _FlaggedTab(firestore: _firestore, showSnack: _showSnack),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — ALL USERS
// ═══════════════════════════════════════════════════════════════════════════════
class _UsersTab extends StatelessWidget {
  final FirebaseFirestore firestore;
  final void Function(UserModel) onRoleChange;
  final Future<void> Function(String uid, String status) onStatusChange;
  final void Function(String, Color) showSnack;

  const _UsersTab({
    required this.firestore,
    required this.onRoleChange,
    required this.onStatusChange,
    required this.showSnack,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection(FirestorePaths.users)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No users found.',
                style: TextStyle(fontFamily: 'Sora',
                    color: AppColors.textSecondary)),
          );
        }

        final users = snapshot.data!.docs.map((doc) {
          return UserModel.fromMap(
              doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, i) => _UserCard(
            user: users[i],
            onRoleChange: onRoleChange,
            onStatusChange: onStatusChange,
            showSnack: showSnack,
          ),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final void Function(UserModel) onRoleChange;
  final Future<void> Function(String, String) onStatusChange;
  final void Function(String, Color) showSnack;

  const _UserCard({
    required this.user,
    required this.onRoleChange,
    required this.onStatusChange,
    required this.showSnack,
  });

  Color get _roleColor {
    switch (user.role) {
      case 'admin':    return const Color(0xFF6C3483);
      case 'seller':   return AppColors.primary;
      case 'designer': return const Color(0xFF117A65);
      default:         return const Color(0xFF1A5276);
    }
  }

  Color get _statusColor =>
      user.status == 'active' ? AppColors.success :
      user.status == 'banned' ? AppColors.error : AppColors.warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: _roleColor.withOpacity(0.15),
              radius: 24,
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                    fontFamily: 'Sora',
                    fontWeight: FontWeight.w700,
                    color: _roleColor,
                    fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.displayName,
                      style: const TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: const TextStyle(
                          fontFamily: 'Sora',
                          color: AppColors.textSecondary,
                          fontSize: 12)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _Tag(label: user.role, color: _roleColor),
                      const SizedBox(width: 6),
                      _Tag(label: user.status, color: _statusColor),
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert,
                  color: AppColors.textSecondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (action) async {
                if (action == 'role') {
                  onRoleChange(user);
                } else if (action == 'ban') {
                  await onStatusChange(user.uid, 'banned');
                  showSnack('${user.displayName} banned', AppColors.error);
                } else if (action == 'unban') {
                  await onStatusChange(user.uid, 'active');
                  showSnack('${user.displayName} unbanned', AppColors.success);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'role',
                  child: Row(children: [
                    Icon(Icons.manage_accounts, size: 18,
                        color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('Change Role',
                        style: TextStyle(fontFamily: 'Sora', fontSize: 13)),
                  ]),
                ),
                if (user.status != 'banned')
                  const PopupMenuItem(
                    value: 'ban',
                    child: Row(children: [
                      Icon(Icons.block, size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Ban User',
                          style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 13,
                              color: AppColors.error)),
                    ]),
                  ),
                if (user.status == 'banned')
                  const PopupMenuItem(
                    value: 'unban',
                    child: Row(children: [
                      Icon(Icons.check_circle_outline,
                          size: 18, color: AppColors.success),
                      SizedBox(width: 8),
                      Text('Unban User',
                          style: TextStyle(
                              fontFamily: 'Sora',
                              fontSize: 13,
                              color: AppColors.success)),
                    ]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — PENDING SELLERS
// ═══════════════════════════════════════════════════════════════════════════════
class _SellersTab extends StatelessWidget {
  final FirebaseFirestore firestore;
  final Future<void> Function(String) onApprove;
  final Future<void> Function(String) onReject;

  const _SellersTab({
    required this.firestore,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection(FirestorePaths.users)
          .where('role', isEqualTo: 'seller')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    size: 56, color: AppColors.success.withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text('No pending seller applications',
                    style: TextStyle(
                        fontFamily: 'Sora',
                        color: AppColors.textSecondary,
                        fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final user = UserModel.fromMap(
                docs[i].data() as Map<String, dynamic>, docs[i].id);
            return _SellerApprovalCard(
                user: user, onApprove: onApprove, onReject: onReject);
          },
        );
      },
    );
  }
}

class _SellerApprovalCard extends StatelessWidget {
  final UserModel user;
  final Future<void> Function(String) onApprove;
  final Future<void> Function(String) onReject;

  const _SellerApprovalCard({
    required this.user,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  radius: 22,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        fontFamily: 'Sora',
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 16),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.displayName,
                          style: const TextStyle(
                              fontFamily: 'Sora',
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              fontSize: 14)),
                      Text(user.email,
                          style: const TextStyle(
                              fontFamily: 'Sora',
                              color: AppColors.textSecondary,
                              fontSize: 12)),
                    ],
                  ),
                ),
                _Tag(label: 'Pending', color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => onReject(user.uid),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reject',
                        style: TextStyle(
                            fontFamily: 'Sora',
                            color: AppColors.error,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => onApprove(user.uid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Approve',
                        style: TextStyle(
                            fontFamily: 'Sora',
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — FLAGGED PRODUCTS
// ═══════════════════════════════════════════════════════════════════════════════
class _FlaggedTab extends StatelessWidget {
  final FirebaseFirestore firestore;
  final void Function(String, Color) showSnack;

  const _FlaggedTab({
    required this.firestore,
    required this.showSnack,
  });

  Future<void> _removeProduct(
      BuildContext context, FirebaseFirestore firestore,
      String productId, void Function(String, Color) showSnack) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Product?',
            style: TextStyle(
                fontFamily: 'Sora',
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: const Text(
            'This will deactivate the product. The seller will no longer see it listed.',
            style: TextStyle(
                fontFamily: 'Sora', color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(
                    fontFamily: 'Sora', color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove',
                style: TextStyle(fontFamily: 'Sora', color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await firestore
          .collection('products')
          .doc(productId)
          .update({'isActive': false, 'isFlagged': false});
      showSnack('Product removed successfully', AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('products')
          .where('isFlagged', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_outlined,
                    size: 56, color: AppColors.success.withOpacity(0.5)),
                const SizedBox(height: 12),
                const Text('No flagged products',
                    style: TextStyle(
                        fontFamily: 'Sora',
                        color: AppColors.textSecondary,
                        fontSize: 14)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final productId = docs[i].id;
            return _FlaggedProductCard(
              productId: productId,
              data: data,
              onRemove: () => _removeProduct(
                  context, firestore, productId, showSnack),
            );
          },
        );
      },
    );
  }
}

class _FlaggedProductCard extends StatelessWidget {
  final String productId;
  final Map<String, dynamic> data;
  final VoidCallback onRemove;

  const _FlaggedProductCard({
    required this.productId,
    required this.data,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final images = List<String>.from(data['images'] ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: images.isNotEmpty
                  ? Image.network(images.first,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? 'Unknown Product',
                      style: const TextStyle(
                          fontFamily: 'Sora',
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                      'LKR ${(data['price'] ?? 0).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontFamily: 'Sora',
                          color: AppColors.priceColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  _Tag(label: '⚑ Flagged', color: AppColors.error),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        color: AppColors.background,
        child: const Icon(Icons.image_outlined,
            color: AppColors.textHint, size: 24),
      );
}

// ── Shared tag widget ──────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontFamily: 'Sora',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color),
      ),
    );
  }
}