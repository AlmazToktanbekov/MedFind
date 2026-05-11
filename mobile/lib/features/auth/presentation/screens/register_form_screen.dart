import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';

class RegisterFormScreen extends ConsumerStatefulWidget {
  final String role;

  const RegisterFormScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterFormScreen> createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends ConsumerState<RegisterFormScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String get _roleTitle => switch (widget.role) {
        'patient' => 'Пациент',
        'doctor' => 'Врач',
        'clinic' => 'Клиника',
        'pharmacy' => 'Аптека',
        _ => 'Пользователь',
      };

  Color get _roleColor => switch (widget.role) {
        'doctor' => const Color(0xFF2979FF),
        'clinic' => AppColors.success,
        'pharmacy' => AppColors.warning,
        _ => AppColors.primaryBlue,
      };

  IconData get _roleIcon => switch (widget.role) {
        'doctor' => PhosphorIconsFill.stethoscope,
        'clinic' => PhosphorIconsFill.hospital,
        'pharmacy' => PhosphorIconsFill.pill,
        _ => PhosphorIconsFill.userCircle,
      };

  String get _nameLabel => switch (widget.role) {
        'clinic' => 'Название клиники',
        'pharmacy' => 'Название компании',
        'doctor' => 'ФИО',
        _ => 'Имя и фамилия',
      };

  String get _nameHint => switch (widget.role) {
        'clinic' => 'Например: МедЦентр Бишкек',
        'pharmacy' => 'Например: АлтынФарм',
        'doctor' => 'Алиев Азамат Бекович',
        _ => 'Иванов Иван',
      };

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = '+996${_phoneController.text.trim()}';
    final role = await ref.read(authProvider.notifier).register(
          phone: phone,
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          role: widget.role,
        );

    if (!mounted) return;

    if (role != null) {
      _navigateByRole(role);
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Ошибка регистрации';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _navigateByRole(String role) {
    final dest = switch (role) {
      'doctor' => '/provider/setup',
      'clinic' => '/provider/clinic-intro',
      'pharmacy' => '/provider/pharmacy-setup',
      _ => '/main',
    };
    context.go(dest);
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
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _roleColor.withValues(alpha: 0.12),
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
                        const SizedBox(height: 28),

                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _roleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(_roleIcon, color: _roleColor, size: 28),
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Регистрация\nкак «$_roleTitle»',
                          style: AppTextStyles.headingLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Заполните данные для создания аккаунта',
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 36),

                        // Имя / Название
                        _buildLabel(_nameLabel),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _nameController,
                          hint: _nameHint,
                          icon: widget.role == 'clinic' || widget.role == 'pharmacy'
                              ? PhosphorIconsRegular.buildings
                              : PhosphorIconsRegular.user,
                          textCapitalization: TextCapitalization.words,
                          validator: (v) {
                            if (v == null || v.trim().length < 2) {
                              return 'Введите не менее 2 символов';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Телефон
                        _buildLabel('Номер телефона'),
                        const SizedBox(height: 8),
                        _buildPhoneField(),
                        const SizedBox(height: 20),

                        // Пароль
                        _buildLabel('Пароль'),
                        const SizedBox(height: 8),
                        _buildPasswordField(
                          controller: _passwordController,
                          hint: 'Минимум 6 символов',
                          obscure: _obscurePassword,
                          onToggle: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                          validator: (v) {
                            if (v == null || v.length < 6) {
                              return 'Минимум 6 символов';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Подтверждение пароля
                        _buildLabel('Подтвердите пароль'),
                        const SizedBox(height: 8),
                        _buildPasswordField(
                          controller: _confirmController,
                          hint: 'Повторите пароль',
                          obscure: _obscureConfirm,
                          onToggle: () => setState(
                              () => _obscureConfirm = !_obscureConfirm),
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Пароли не совпадают';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 40),

                        GradientButton(
                          text: 'Создать аккаунт',
                          onPressed: isLoading ? null : _register,
                          isLoading: isLoading,
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Уже есть аккаунт? ',
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/login'),
                              child: Text(
                                'Войти',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.bodyLarge,
        textCapitalization: textCapitalization,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(icon, color: AppColors.primaryBlue, size: 20),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
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
          hintText: hint,
          hintStyle:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: Icon(PhosphorIconsRegular.lock,
                color: AppColors.primaryBlue, size: 20),
          ),
          prefixIconConstraints: const BoxConstraints(),
          suffixIcon: IconButton(
            onPressed: onToggle,
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
