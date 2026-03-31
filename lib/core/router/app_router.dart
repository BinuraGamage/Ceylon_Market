import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/customer_home_screen.dart';
import '../../features/auth/screens/seller_home_stub.dart';
import '../../features/auth/screens/designer_home_stub.dart';
import '../../features/auth/screens/admin_dashboard_stub.dart';
import '../../features/home/screens/product_detail_screen.dart';
import '../../features/home/screens/search_screen.dart';
import '../../features/home/screens/image_search_screen.dart';
import '../../providers/auth_provider.dart';
// import '../../features/home/screens/category_browse_screen.dart'; // M2 to add
// import '../../features/shop/screens/shop_screen.dart';             // M3 to add

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
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

      final isOnAuthScreen = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      // Still loading Firebase auth — wait
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;

      // Not logged in — go to login
      if (!isLoggedIn) {
        return isOnAuthScreen ? null : '/login';
      }

      // Logged in but currentUser not loaded yet — wait
      if (currentUser == null) return null;

      // Logged in and on auth screen — redirect to correct home
      if (isOnAuthScreen) {
        return _homeRouteForRole(currentUser.role);
      }

      // Already on correct screen — do nothing
      return null;
    },
    routes: [
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
      GoRoute(
        name: 'customer-home',
        path: '/customer',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      GoRoute(
        name: 'seller-home',
        path: '/seller',
        builder: (context, state) => const SellerHomeStub(),
      ),
      GoRoute(
        name: 'designer-home',
        path: '/designer',
        builder: (context, state) => const DesignerHomeStub(),
      ),
      GoRoute(
        name: 'admin',
        path: '/admin',
        builder: (context, state) => const AdminDashboardStub(),
      ),
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
        name: 'search',
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
 
      GoRoute(
        name: 'image-search',
        path: '/search/image',
        builder: (context, state) => const ImageSearchScreen(),
      ),
 
      
      /*
      // M2 to add:
      GoRoute(
        name: 'category-browse',
        path: '/category/:name',
        builder: (context, state) => CategoryBrowseScreen(
          category: state.pathParameters['name']!,
        ),
      ),
      // M3 to add:
      // Shop route — M3 will own the ShopScreen widget; M2 just registers the route.
      GoRoute(
       name: 'shop',
       path: '/shop/:id',
       builder: (context, state) => ShopScreen(
         shopId: state.pathParameters['id']!,
        ),
    ),
     */
    ],
  );
});

String _homeRouteForRole(String? role) {
  switch (role) {
    case 'seller':
      return '/seller';
    case 'designer':
      return '/designer';
    case 'admin':
      return '/admin';
    default:
      return '/customer';
  }
}