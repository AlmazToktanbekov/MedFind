import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../providers/auth_provider.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String? devCode;

  const OtpScreen({super.key, required this.phone, this.devCode});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _secondsLeft = 60;
  Timer? _timer;

  String get _otp => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startTimer();

    // В dev-режиме автозаполняем код
    if (widget.devCode != null && widget.devCode!.length == 6) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fillDevCode());
    }
  }

  void _fillDevCode() {
    for (int i = 0; i < 6; i++) {
      _controllers[i].text = widget.devCode![i];
    }
    setState(() {});
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  Future<void> _resendOtp() async {
    await ref.read(authProvider.notifier).sendOtp(widget.phone);
    setState(() => _secondsLeft = 60);
    _timer?.cancel();
    _startTimer();

    final devCode = ref.read(authProvider).devCode;
    if (devCode != null) _fillDevCode();
  }

  Future<void> _verify() async {
    if (_otp.length < 6) return;

    final role = await ref
        .read(authProvider.notifier)
        .verifyAndLogin(widget.phone, _otp);

    if (!mounted) return;

    if (role != null) {
      if (role == 'doctor') {
        context.go('/provider/setup');
      } else {
        context.go('/main');
      }
    } else {
      final error = ref.read(authProvider).errorMessage ?? 'Неверный код';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        ref.watch(authProvider).status == AuthStatus.loading;
    final otpFilled = _otp.length == 6;

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Код подтверждения', style: AppTextStyles.headingLarge),
            const SizedBox(height: 8),
            Text(
              'Отправили SMS на +996 ${widget.phone}',
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (widget.devCode != null) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            const SizedBox(height: 40),
            // 6 полей для кода
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return Container(
                  width: 48,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.cardShadow,
                    border: Border.all(
                      color: _controllers[index].text.isNotEmpty
                          ? AppColors.primaryBlue
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: AppTextStyles.headingMedium,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                      setState(() {});
                      // Автоотправка когда все 6 заполнены
                      if (_otp.length == 6) _verify();
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Таймер повторной отправки
            Center(
              child: _secondsLeft > 0
                  ? Text(
                      'Повторить через $_secondsLeft сек',
                      style: AppTextStyles.bodySmall,
                    )
                  : GestureDetector(
                      onTap: _resendOtp,
                      child: Text(
                        'Отправить повторно',
                        style: AppTextStyles.labelBold,
                      ),
                    ),
            ),
            const Spacer(),
            GradientButton(
              text: 'Подтвердить',
              onPressed: (otpFilled && !isLoading) ? _verify : null,
              isLoading: isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
