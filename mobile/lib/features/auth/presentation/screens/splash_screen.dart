import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final role = await ref.read(authProvider.notifier).checkAuth();
    if (!mounted) return;

    if (role == null) {
      context.go('/onboarding');
      return;
    }

    // Авторизован — проверяем роль и наличие профиля
    switch (role) {
      case 'patient':
      case 'admin':
        context.go('/main');
      case 'doctor':
        final status =
            await ref.read(authProvider.notifier).getDoctorStatus();
        if (!mounted) return;
        switch (status) {
          case null:
            context.go('/provider/setup'); // нет профиля — регистрация
          case 'rejected':
          case 'removed':
            context.go('/provider/setup'); // отклонён/удалён — выбрать клинику
          default:
            context.go('/main'); // pending/active/deactivated — в приложение
        }
      case 'clinic':
        final hasProfile =
            await ref.read(authProvider.notifier).hasProviderProfile('clinic');
        if (!mounted) return;
        context.go(hasProfile ? '/clinic/manage' : '/provider/clinic-intro');
      case 'pharmacy':
        final hasProfile = await ref
            .read(authProvider.notifier)
            .hasProviderProfile('pharmacy');
        if (!mounted) return;
        context.go(hasProfile ? '/main' : '/provider/pharmacy-setup');
      default:
        context.go('/main');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        child: FadeTransition(
          opacity: _fadeIn,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnim,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      PhosphorIconsFill.heartbeat,
                      color: Colors.white,
                      size: 58,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'MedFind',
                  style: AppTextStyles.headingLarge.copyWith(
                    color: Colors.white,
                    fontSize: 38,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Здоровье начинается здесь',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 60),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
