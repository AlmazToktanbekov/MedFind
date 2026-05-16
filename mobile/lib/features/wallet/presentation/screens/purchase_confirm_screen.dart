import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../subscription/providers/subscription_provider.dart';
import '../../providers/wallet_provider.dart';

/// Экран подтверждения покупки подписки из баланса кошелька.
///
/// Параметры через extra: { plan: "pro"|"premium", period: "month"|"year" }
class PurchaseConfirmScreen extends ConsumerStatefulWidget {
  final String plan;
  final String period;
  const PurchaseConfirmScreen({super.key, required this.plan, required this.period});

  @override
  ConsumerState<PurchaseConfirmScreen> createState() => _PurchaseConfirmScreenState();
}

class _PurchaseConfirmScreenState extends ConsumerState<PurchaseConfirmScreen> {
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).load();
    });
  }

  int _priceUsd() {
    final monthly = widget.plan == 'pro' ? 20 : 40;
    return widget.period == 'year' ? monthly * 10 : monthly;
  }

  String _periodLabel() => widget.period == 'year' ? 'на год' : 'на месяц';

  Future<void> _purchase() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(walletRepositoryProvider).purchaseSubscription(
            plan: widget.plan,
            period: widget.period,
          );
      // Обновим подписку и кошелёк
      await ref.read(subscriptionProvider.notifier).load();
      await ref.read(walletProvider.notifier).load();
      if (!mounted) return;
      // Successful purchase — back to subscription screen with confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Подписка ${widget.plan.toUpperCase()} активирована'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/subscription');
    } catch (e) {
      setState(() => _isSubmitting = false);
      final s = e.toString();
      String msg = 'Не удалось купить подписку';
      if (s.contains('insufficient_funds')) {
        msg = 'Недостаточно средств на балансе';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = ref.watch(walletProvider).wallet;
    final price = _priceUsd();
    final balance = wallet?.balanceUsd ?? 0;
    final enough = balance >= price;
    final remaining = balance - price;

    final isPremium = widget.plan == 'premium';
    final accent = isPremium ? const Color(0xFFFFB300) : AppColors.primaryBlue;

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Покупка подписки',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Plan card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppColors.cardShadow,
              border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isPremium ? PhosphorIconsFill.crown : PhosphorIconsRegular.crown,
                      color: accent,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.plan.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _periodLabel(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  '\$$price',
                  style: GoogleFonts.inter(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '≈ ${(price * 89).toStringAsFixed(0)} ₸',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Balance breakdown
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              children: [
                _Row(label: 'Ваш баланс', value: '\$${balance.toStringAsFixed(2)}'),
                const Divider(),
                _Row(label: 'Спишется', value: '−\$$price', valueColor: AppColors.error),
                const Divider(),
                _Row(
                  label: 'Останется',
                  value: enough ? '\$${remaining.toStringAsFixed(2)}' : '—',
                  valueColor: enough ? AppColors.success : AppColors.error,
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (enough)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Подтвердить покупку',
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            )
          else
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(PhosphorIconsRegular.warning, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Недостаточно средств. Пополните счёт на \$${(price - balance).toStringAsFixed(2)} и более.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => context.push('/wallet/topup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Пополнить счёт',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  const _Row({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textPrimary.withValues(alpha: 0.7),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: bold ? 18 : 15,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
