import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';
import '../../../profile/providers/profile_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '+996${_phoneController.text.trim()}';
    final role = await ref
        .read(authProvider.notifier)
        .login(phone: phone, password: _passwordController.text);

    if (!mounted) return;

    if (role != null) {
      await _navigateByRole(role);
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Ошибка входа';
      _showError(error);
    }
  }

  Future<void> _navigateByRole(String role) async {
    await ref.read(profileProvider.notifier).refresh();
    if (!mounted) return;
    if (role == 'patient' || role == 'admin') {
      context.go('/main');
      return;
    }

    if (role == 'doctor') {
      final status = await ref.read(authProvider.notifier).getDoctorStatus();
      if (!mounted) return;
      switch (status) {
        case null:
        case 'rejected':
        case 'removed':
          context.go('/provider/setup');
        default:
          context.go('/main');
      }
      return;
    }

    final hasProfile =
        await ref.read(authProvider.notifier).hasProviderProfile(role);
    if (!mounted) return;

    if (hasProfile) {
      final dest = switch (role) {
        'clinic' => '/clinic/manage',
        'pharmacy' => '/main',
        _ => '/main',
      };
      context.go(dest);
    } else {
      final dest = switch (role) {
        'clinic' => '/provider/clinic-intro',
        'pharmacy' => '/provider/pharmacy-setup',
        _ => '/main',
      };
      context.go(dest);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(
                            PhosphorIconsRegular.arrowLeft,
                            color: AppColors.textPrimary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(height: 32),

                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: AppColors.btnGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: const Icon(
                            PhosphorIconsFill.heartbeat,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 24),

                        Text('Добро\nпожаловать!',
                            style: AppTextStyles.headingLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Войдите в свой аккаунт MedFind',
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 40),

                        _buildLabel('Номер телефона'),
                        const SizedBox(height: 8),
                        _buildPhoneField(),
                        const SizedBox(height: 20),

                        _buildLabel('Пароль'),
                        const SizedBox(height: 8),
                        _buildPasswordField(),
                        const SizedBox(height: 40),

                        GradientButton(
                          text: 'Войти',
                          onPressed: isLoading ? null : _login,
                          isLoading: isLoading,
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Нет аккаунта? ',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/register'),
                              child: Text(
                                'Зарегистрироваться',
                                style: AppTextStyles.labelBold
                                    .copyWith(color: AppColors.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Text(
        text,
        style: AppTextStyles.labelBold.copyWith(color: AppColors.textPrimary),
      );

  Widget _buildPhoneField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: TextFormField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 9,
        style: AppTextStyles.bodyLarge,
        validator: (v) {
          if (v == null || v.trim().length < 9) {
            return 'Введите корректный номер (9 цифр)';
          }
          return null;
        },
        decoration: InputDecoration(
          hintText: '700 000 000',
          hintStyle:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          prefixText: '+996 ',
          prefixStyle:
              AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(PhosphorIconsRegular.phone,
                color: AppColors.primaryBlue, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: InputBorder.none,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: AppTextStyles.bodyLarge,
        validator: (v) {
          if (v == null || v.length < 6) return 'Минимум 6 символов';
          return null;
        },
        decoration: InputDecoration(
          hintText: '••••••••',
          hintStyle:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(PhosphorIconsRegular.lock,
                color: AppColors.primaryBlue, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: IconButton(
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword
                  ? PhosphorIconsRegular.eye
                  : PhosphorIconsRegular.eyeSlash,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: InputBorder.none,
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
      ),
    );
  }
}
