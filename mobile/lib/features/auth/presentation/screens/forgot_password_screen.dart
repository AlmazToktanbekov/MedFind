import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '+996${_phoneController.text.trim()}';
    final ok = await ref.read(authProvider.notifier).forgotPassword(phone: phone);

    if (!mounted) return;

    if (ok) {
      final devCode = ref.read(authProvider).pendingDevCode;
      context.push('/reset-password', extra: {
        'phone': phone,
        'devCode': ?devCode,
      });
    } else {
      final error =
          ref.read(authProvider).errorMessage ?? 'Не удалось отправить код';
      _showError(error);
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
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppColors.btnGradient,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: const Icon(
                    PhosphorIconsFill.lockKey,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 24),
                Text('Забыли пароль?', style: AppTextStyles.headingLarge),
                const SizedBox(height: 8),
                Text(
                  'Введите номер телефона — мы отправим код для сброса пароля',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),
                Text(
                  'Номер телефона',
                  style: AppTextStyles.labelBold
                      .copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                _buildPhoneField(),
                const SizedBox(height: 40),
                GradientButton(
                  text: 'Получить код',
                  onPressed: isLoading ? null : _sendCode,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
          counterText: '',
        ),
      ),
    );
  }
}
