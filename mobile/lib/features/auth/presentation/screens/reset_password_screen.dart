import 'dart:async';
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

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String phone;
  final String? devCode;

  const ResetPasswordScreen({
    super.key,
    required this.phone,
    this.devCode,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  int _secondsLeft = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    if (widget.devCode != null) {
      _codeController.text = widget.devCode!;
    }
  }

  void _startTimer() {
    _secondsLeft = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resend() async {
    final ok = await ref
        .read(authProvider.notifier)
        .forgotPassword(phone: widget.phone);
    if (!mounted) return;
    if (ok) {
      final newDev = ref.read(authProvider).pendingDevCode;
      if (newDev != null) {
        _codeController.text = newDev;
      }
      _startTimer();
    } else {
      _showError(ref.read(authProvider).errorMessage ?? 'Ошибка');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final role = await ref.read(authProvider.notifier).resetPassword(
          phone: widget.phone,
          code: _codeController.text.trim(),
          newPassword: _passwordController.text,
        );

    if (!mounted) return;

    if (role != null) {
      await _navigateByRole(role);
    } else {
      _showError(
        ref.read(authProvider).errorMessage ?? 'Не удалось сбросить пароль',
      );
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
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider).status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Новый пароль', style: AppTextStyles.headingLarge),
                const SizedBox(height: 8),
                Text(
                  'Введите код из SMS и придумайте новый пароль для ${widget.phone}',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary),
                ),
                if (widget.devCode != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'DEV: код ${widget.devCode}',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                _label('Код из SMS'),
                const SizedBox(height: 8),
                _codeField(),
                const SizedBox(height: 12),
                Center(
                  child: _secondsLeft > 0
                      ? Text(
                          'Отправить повторно через $_secondsLeft сек',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        )
                      : GestureDetector(
                          onTap: _resend,
                          child: Text(
                            'Отправить код повторно',
                            style: AppTextStyles.labelBold
                                .copyWith(color: AppColors.primaryBlue),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                _label('Новый пароль'),
                const SizedBox(height: 8),
                _passwordField(
                  controller: _passwordController,
                  obscure: _obscurePassword,
                  toggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Минимум 6 символов';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _label('Повторите пароль'),
                const SizedBox(height: 8),
                _passwordField(
                  controller: _confirmController,
                  obscure: _obscureConfirm,
                  toggle: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  validator: (v) {
                    if (v != _passwordController.text) {
                      return 'Пароли не совпадают';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                GradientButton(
                  text: 'Сбросить пароль',
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: AppTextStyles.labelBold.copyWith(color: AppColors.textPrimary),
      );

  Widget _codeField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: TextFormField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 6,
        style: AppTextStyles.bodyLarge,
        validator: (v) {
          if (v == null || v.trim().length != 6) return 'Введите 6-значный код';
          return null;
        },
        decoration: InputDecoration(
          hintText: '------',
          hintStyle:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(PhosphorIconsRegular.chatCircleText,
                color: AppColors.primaryBlue, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: InputBorder.none,
          counterText: '',
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback toggle,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: AppTextStyles.bodyLarge,
        validator: validator,
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
            onPressed: toggle,
            icon: Icon(
              obscure
                  ? PhosphorIconsRegular.eye
                  : PhosphorIconsRegular.eyeSlash,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
