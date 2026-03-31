import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).loginWithEmail(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    final authState = ref.read(authNotifierProvider);
    authState.whenOrNull(
      error: (e, _) => _showError(e.toString()),
    );
  }

  Future<void> _handleGoogleLogin() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();

    final authState = ref.read(authNotifierProvider);
    authState.whenOrNull(
      error: (e, _) => _showError(e.toString()),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── Logo / Title ──────────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: AppColors.surface,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ceylon Marketplace',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Sora',
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in to continue',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontFamily: 'Sora',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ── Email Field ───────────────────────────────────────────
                const Text(
                  'Email',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Sora',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Enter your email',
                    prefixIcon: Icon(Icons.email_outlined,
                        color: AppColors.textSecondary),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // ── Password Field ────────────────────────────────────────
                const Text(
                  'Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    fontFamily: 'Sora',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(
                    fontFamily: 'Sora',
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.textSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // ── Forgot Password ───────────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontFamily: 'Sora',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Login Button ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleEmailLogin,
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: AppColors.surface,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Sora',
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Divider ───────────────────────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'or continue with',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontFamily: 'Sora',
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),

                const SizedBox(height: 24),

                // ── Google Sign-In Button ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _handleGoogleLogin,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColors.surface,
                    ),
                    icon: Image.network(
                      'https://www.google.com/favicon.ico',
                      width: 20,
                      height: 20,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.g_mobiledata, size: 24),
                    ),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Sora',
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Register Link ─────────────────────────────────────────
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontFamily: 'Sora',
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // TODO: Navigate to RegisterScreen
                        },
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Sora',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}