import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/customer_home_screen.dart';
import '../../features/customization/screens/custom_inquiry_screen.dart';
import '../../features/customization/screens/designer_dashboard_screen.dart';
import '../../features/customization/screens/my_requests_screen.dart';
import '../../features/customization/screens/custom_request_detail_screen.dart';
import '../../features/auth/screens/admin_dashboard_stub.dart';
import '../../features/home/screens/product_detail_screen.dart';
import '../../features/home/screens/search_screen.dart';
import '../../features/home/screens/image_search_screen.dart';
import '../../features/home/screens/category_browse_screen.dart';
import '../../features/home/screens/wishlist_screen.dart';
import '../../features/home/screens/customer_profile_screen.dart';
import '../../features/checkout/screens/cart_screen.dart';
import '../../features/checkout/screens/checkout_screen.dart';
import '../../features/checkout/screens/order_history_screen.dart';
import '../../features/checkout/screens/seller_order_management_screen.dart';
import '../../features/checkout/screens/order_confirmation_screen.dart';
import '../../features/checkout/screens/order_detail_screen.dart';
import '../../features/products/screens/product_form_screen.dart';
import '../../features/products/screens/product_reviews_screen.dart';
import '../../features/products/screens/seller_products_screen.dart';
import '../../providers/auth_provider.dart';
import '../../features/shop/screens/seller_register_screen.dart';
import '../../features/shop/screens/seller_dashboard_screen.dart';
import '../../features/shop/screens/seller_insights_screen.dart';
import '../../features/shop/screens/store_room_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (previous, next) => notifyListeners());
    _ref.listen(currentUserProvider, (previous, next) => notifyListeners());
  }
  final Ref _ref;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final currentUser = ref.read(currentUserProvider);

      final location = state.matchedLocation;
      final isOnAuthScreen = location == '/login' || location == '/register';

      // Still loading Firebase auth — wait
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;

      // Not logged in — send to login
      if (!isLoggedIn) {
        return isOnAuthScreen ? null : '/login';
      }

      // Logged in but app user profile not set yet — stay on login until explicit auth flow completes
      if (currentUser == null) {
        return isOnAuthScreen ? null : '/login';
      }

      // Logged in and on an auth screen — redirect to their home
      if (isOnAuthScreen) {
        return _homeRouteForRole(currentUser.role);
      }

      // ── Role guards ──────────────────────────────────────────────────────
      // Prevent non-sellers from accessing seller-only routes
      final isSellerRoute = location.startsWith('/seller');
      if (isSellerRoute && currentUser.role != 'seller') {
        return _homeRouteForRole(currentUser.role);
      }

      // Prevent non-admins from accessing the admin panel
      if (location.startsWith('/admin') && currentUser.role != 'admin') {
        return _homeRouteForRole(currentUser.role);
      }

      return null;
    },
    routes: [
      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'register',
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // ── Customer (M2) ─────────────────────────────────────────────────────
      GoRoute(
        name: 'customer-home',
        path: '/customer',
        builder: (context, state) => const CustomerHomeScreen(),
      ),

      // ── Seller (M3) ───────────────────────────────────────────────────────
      GoRoute(
        name: 'seller-register',
        path: '/seller/register',
        builder: (context, state) => const SellerRegisterScreen(),
      ),
      GoRoute(
        name: 'seller-dashboard',
        path: '/seller/dashboard',
        builder: (context, state) => const SellerDashboardScreen(),
      ),
      GoRoute(
        name: 'seller-insights',
        path: '/seller/insights',
        builder: (context, state) => const SellerInsightsScreen(),
      ),
      GoRoute(
        name: 'seller-products',
        path: '/seller/products',
        builder: (context, state) => const SellerProductsScreen(),
      ),
      GoRoute(
        name: 'seller-product-create',
        path: '/seller/products/new',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        name: 'seller-product-edit',
        path: '/seller/products/edit/:id',
        builder: (context, state) =>
            ProductFormScreen(productId: state.pathParameters['id']!),
      ),

      // ── Shop / Store Room (M3 — public) ──────────────────────────────────
      GoRoute(
        name: 'shop',
        path: '/shop/:id',
        builder: (context, state) =>
            StoreRoomScreen(shopId: state.pathParameters['id']!),
      ),
      GoRoute(
        name: 'shop-about',
        path: '/shop/:id/about',
        builder: (context, state) =>
            StoreRoomScreen(shopId: state.pathParameters['id']!),
      ),

      // ── Designer (M6) ────────────────────────────────────────────────────
      GoRoute(
        name: 'designer-home',
        path: '/designer',
        builder: (context, state) => const DesignerDashboardScreen(),
      ),
      GoRoute(
        name: 'custom-inquiry',
        path: '/custom-inquiry',
        builder: (context, state) => const CustomInquiryScreen(),
      ),
      GoRoute(
        name: 'my-requests',
        path: '/my-requests',
        builder: (context, state) => const MyRequestsScreen(),
      ),
      GoRoute(
        name: 'custom-request-detail',
        path: '/custom-request/:id',
        builder: (context, state) => CustomRequestDetailScreen(
          requestId: state.pathParameters['id']!,
        ),
      ),

      // ── Admin ────────────────────────────────────────────────────────────
      GoRoute(
        name: 'admin',
        path: '/admin',
        builder: (context, state) => const AdminDashboardStub(),
      ),

      // ── Products (M4) ────────────────────────────────────────────────────
      GoRoute(
        name: 'product-detail',
        path: '/product/:id',
        builder: (context, state) => ProductDetailScreen(
          productId: state.pathParameters['id']!,
          // M6 passes customizationWidget via state.extra when product.customizable == true
          customizationWidget: state.extra as Widget?,
        ),
      ),
      GoRoute(
        name: 'product-reviews',
        path: '/product/:id/reviews',
        builder: (context, state) =>
            ProductReviewsScreen(productId: state.pathParameters['id']!),
      ),

      // ── Search (M2) ───────────────────────────────────────────────────────
      GoRoute(
        name: 'search',
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        name: 'image-search',
        path: '/search/image',
        builder: (context, state) => const ImageSearchScreen(),
      ),

      GoRoute(
        name: 'category-browse',
        path: '/category/:name',
        builder: (context, state) =>
            CategoryBrowseScreen(category: state.pathParameters['name']!),
      ),

      // ── Placeholder routes for pending features ───────────────────────
      GoRoute(
        name: 'wishlist',
        path: '/wishlist',
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        name: 'cart',
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        name: 'checkout',
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        name: 'order-confirmation',
        path: '/order-confirmation/:id',
        builder: (context, state) => OrderConfirmationScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        name: 'order-detail',
        path: '/order-detail/:id',
        builder: (context, state) => OrderDetailScreen(
          orderId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        name: 'order-history',
        path: '/order-history',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        name: 'seller-orders',
        path: '/seller/orders',
        builder: (context, state) => const SellerOrderManagementScreen(),
      ),
      GoRoute(
        name: 'profile',
        path: '/profile',
        builder: (context, state) => const CustomerProfileScreen(),
      ),
    ],
  );
});

/// Maps a user role to their default landing route.
String _homeRouteForRole(String? role) {
  switch (role) {
    case 'seller':
      return '/seller/dashboard'; // M3 — SellerDashboardScreen
    case 'designer':
      return '/designer';
    case 'admin':
      return '/admin';
    default:
      return '/customer'; // M2 — CustomerHomeScreen
  }
}
