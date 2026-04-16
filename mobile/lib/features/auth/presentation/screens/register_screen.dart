import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedRole;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  final _roles = [
    _RoleOption(
      role: 'patient',
      title: 'Пациент',
      subtitle: 'Ищу врачей, клиники\nи аптеки',
      icon: PhosphorIconsFill.userCircle,
      color: AppColors.primaryBlue,
    ),
    _RoleOption(
      role: 'doctor',
      title: 'Врач',
      subtitle: 'Принимаю пациентов\nи веду расписание',
      icon: PhosphorIconsFill.stethoscope,
      color: const Color(0xFF2979FF),
    ),
    _RoleOption(
      role: 'clinic',
      title: 'Клиника',
      subtitle: 'Представляю\nмедицинское учреждение',
      icon: PhosphorIconsFill.hospital,
      color: AppColors.success,
    ),
    _RoleOption(
      role: 'pharmacy',
      title: 'Аптека',
      subtitle: 'Продаём лекарства\nи медтовары',
      icon: PhosphorIconsFill.pill,
      color: AppColors.warning,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      body: Stack(
        children: [
          // Градиентный декор сверху
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primaryBlue.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        PhosphorIconsRegular.arrowLeft,
                        color: AppColors.textPrimary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Кто вы?', style: AppTextStyles.headingLarge),
                        const SizedBox(height: 8),
                        Text(
                          'Выберите роль для регистрации',
                          style: AppTextStyles.bodyLarge
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Карточки ролей
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.88,
                        ),
                        itemCount: _roles.length,
                        itemBuilder: (context, i) {
                          final role = _roles[i];
                          final isSelected = _selectedRole == role.role;
                          return _RoleCard(
                            option: role,
                            isSelected: isSelected,
                            delay: i * 80,
                            onTap: () =>
                                setState(() => _selectedRole = role.role),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Кнопка продолжить
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    child: AnimatedOpacity(
                      opacity: _selectedRole != null ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 200),
                      child: _ContinueButton(
                        enabled: _selectedRole != null,
                        onTap: () {
                          if (_selectedRole != null) {
                            context.push(
                              '/register/form',
                              extra: _selectedRole,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Role option model ─────────────────────────────────────────────────────

class _RoleOption {
  final String role;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _RoleOption({
    required this.role,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

// ─── Role card ─────────────────────────────────────────────────────────────

class _RoleCard extends StatefulWidget {
  final _RoleOption option;
  final bool isSelected;
  final int delay;
  final VoidCallback onTap;

  const _RoleCard({
    required this.option,
    required this.isSelected,
    required this.delay,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut),
    );
    _fadeAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? widget.option.color.withValues(alpha: 0.08)
                  : AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.isSelected
                    ? widget.option.color
                    : Colors.transparent,
                width: 2,
              ),
              boxShadow: widget.isSelected
                  ? [
                      BoxShadow(
                        color: widget.option.color.withValues(alpha: 0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : AppColors.cardShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Иконка в кружке
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: widget.option.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      widget.option.icon,
                      color: widget.option.color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.option.title,
                    style: AppTextStyles.labelBold.copyWith(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.option.subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary, height: 1.4),
                  ),
                  const Spacer(),
                  // Галочка при выборе
                  if (widget.isSelected)
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: widget.option.color,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Continue button ───────────────────────────────────────────────────────

class _ContinueButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ContinueButton({required this.enabled, required this.onTap});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.96).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _ctrl.forward() : null,
      onTapUp: widget.enabled
          ? (_) {
              _ctrl.reverse();
              widget.onTap();
            }
          : null,
      onTapCancel: widget.enabled ? () => _ctrl.reverse() : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.enabled
                ? AppColors.btnGradient
                : const LinearGradient(
                    colors: [Color(0xFFBBBBBB), Color(0xFFCCCCCC)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.enabled ? AppColors.cardShadow : [],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Продолжить',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  PhosphorIconsRegular.arrowRight,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
