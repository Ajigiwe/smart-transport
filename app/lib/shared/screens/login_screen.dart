import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_provider.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/loading_route.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

/// SmartTransport GH Login Screen — Clean & Simple
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static const Duration _loaderMinDuration = Duration(milliseconds: 2000);
  DateTime? _loaderStartTime;
  Timer? _loaderTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _loaderTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).login(
          _phoneController.text.trim(),
          _passwordController.text,
        );

    if (success && mounted) {
      navigateWithLoader(
        context,
        page: const DashboardScreen(),
        loadingMessage: 'Welcome aboard!',
        replace: true,
      );
    }
  }

  bool _shouldShowLoader(AuthState authState) {
    if (!authState.isLoading || authState.error != null) return false;
    if (_loaderStartTime == null) return true;
    final elapsed = DateTime.now().difference(_loaderStartTime!);
    return elapsed < _loaderMinDuration;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading &&
        authState.error == null &&
        _loaderStartTime == null) {
      _loaderStartTime = DateTime.now();
      _loaderTimer?.cancel();
      _loaderTimer = Timer(_loaderMinDuration, () {
        if (mounted) setState(() {});
      });
    }

    final showLoader = _shouldShowLoader(authState);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: showLoader
          ? _buildLoader()
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingHorizontal,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    // Logo
                    Image.asset(
                      'assets/logo.png',
                      width: 100,
                      height: 100,
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // App name
                    Text(
                      'SmartTransport GH',
                      style: AppTypography.h1.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your smart commute starts here',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Welcome
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Welcome back', style: AppTypography.h2),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Sign in to continue your journey',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextField(
                            label: 'Phone Number',
                            hint: '024 123 4567',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            prefixIcon: Icons.phone_rounded,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          CustomTextField(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            prefixIcon: Icons.lock_rounded,
                            suffixIcon: _obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            onSuffixTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Error
                    if (authState.error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMedium),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                authState.error!,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Sign In
                    PrimaryButton(
                      text: 'Sign In',
                      isLoading: authState.isLoading,
                      onPressed: _handleLogin,
                      icon: Icons.arrow_forward_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Register
                    TextButton(
                      onPressed: () {
                        navigateWithLoader(
                          context,
                          page: const RegisterScreen(),
                          loadingMessage: 'Setting up...',
                        );
                      },
                      child: Text(
                        "Don't have an account? Create one",
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.ghanaGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/logo.png',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 24),
          Text(
            'Checking your session...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
