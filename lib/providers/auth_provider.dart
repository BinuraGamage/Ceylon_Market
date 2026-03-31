import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// ── AuthService instance ───────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ── Raw Firebase auth state stream ────────────────────────────────────────
// Used to check if user is logged in or not
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// ── Current UserModel from Firestore ──────────────────────────────────────
// Use this anywhere you need the full user data (role, status, etc.)
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

// ── Auth Notifier — handles login, register, logout actions ───────────────
class AuthNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async => null;

  Future<void> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(authServiceProvider).registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      ),
    );
    // Sync to currentUserProvider
    ref.read(currentUserProvider.notifier).state = state.value;
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(authServiceProvider).loginWithEmail(
        email: email,
        password: password,
      ),
    );
    ref.read(currentUserProvider.notifier).state = state.value;
  }

  Future<void> signInWithGoogle({String role = 'customer'}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
      ref.read(authServiceProvider).signInWithGoogle(role: role),
    );
    ref.read(currentUserProvider.notifier).state = state.value;
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    state = const AsyncData(null);
    ref.read(currentUserProvider.notifier).state = null;
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);