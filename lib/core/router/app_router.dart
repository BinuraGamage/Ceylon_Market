import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        name: 'login',
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: 'home',
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Home — Coming Soon')),
        ),
      ),
    ],
  );
});