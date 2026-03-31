import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/customer_home_stub.dart';
import '../../features/auth/screens/seller_home_stub.dart';
import '../../features/auth/screens/designer_home_stub.dart';
import '../../features/auth/screens/admin_dashboard_stub.dart';
import '../../providers/auth_provider.dart';

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
        builder: (context, state) => const CustomerHomeStub(),
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