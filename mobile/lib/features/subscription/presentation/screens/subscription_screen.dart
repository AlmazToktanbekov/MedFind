import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../providers/subscription_provider.dart';
import '../../../wallet/providers/wallet_provider.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).load();
      ref.read(walletProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionProvider);
    final plansAsync = ref.watch(plansProvider);
    final wallet = ref.watch(walletProvider).wallet;

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Подписка',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: state.isLoading && state.subscription == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(subscriptionProvider.notifier).load(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _CurrentPlanCard(state: state),
                  const SizedBox(height: 16),
                  // Баланс кошелька с кнопкой пополнить
                  InkWell(
                    onTap: () => context.push('/wallet'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(PhosphorIconsRegular.wallet,
                                color: AppColors.primaryBlue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Баланс счёта',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  wallet == null
                                      ? '—'
                                      : '\$${wallet.balanceUsd.toStringAsFixed(2)}  •  ≈ ${wallet.balanceKgs.toStringAsFixed(0)} ₸',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () => context.push('/wallet/topup'),
                            child: Text(
                              'Пополнить',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Доступные тарифы',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  plansAsync.when(
                    data: (plans) => Column(
                      children: plans.plans
                          .map((p) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _PlanCard(
                                  plan: p,
                                  currentPlan: state.subscription?.plan ?? 'free',
                                  onUpgrade: () {
                                    context.push(
                                      '/subscription/purchase?plan=${p.plan}&period=month',
                                    );
                                  },
                                ),
                              ))
                          .toList(),
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Ошибка загрузки тарифов: $e'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CurrentPlanCard extends StatelessWidget {
  final SubscriptionState state;
  const _CurrentPlanCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final sub = state.subscription;
    final plan = sub?.plan ?? 'free';
    final isTrial = sub?.isTrial ?? false;
    final daysLeft = sub?.daysLeft;

    final Color badgeColor;
    final String badgeLabel;
    switch (plan) {
      case 'premium':
        badgeColor = const Color(0xFFFFB300);
        badgeLabel = 'PREMIUM';
        break;
      case 'pro':
        badgeColor = AppColors.primaryBlue;
        badgeLabel = isTrial ? 'PRO • ПРОБНЫЙ' : 'PRO';
        break;
      default:
        badgeColor = AppColors.textPrimary.withValues(alpha: 0.6);
        badgeLabel = 'FREE';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badgeLabel,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (isTrial && daysLeft != null)
                Text(
                  'Осталось $daysLeft дн.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isTrial
                ? 'Пробный период Pro активен'
                : plan == 'free'
                    ? 'Бесплатный тариф'
                    : 'Подписка активна',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          if (sub != null && sub.expiresAt != null)
            Text(
              'Действует до ${_formatDate(sub.expiresAt!)}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary.withValues(alpha: 0.7),
              ),
            ),
          const SizedBox(height: 16),
          if (sub != null) _UsageRow(sub: sub),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }
}

class _UsageRow extends StatelessWidget {
  final dynamic sub;
  const _UsageRow({required this.sub});

  @override
  Widget build(BuildContext context) {
    if (sub.ownerType == 'clinic') {
      final current = sub.currentDoctors ?? 0;
      final limit = sub.doctorLimit;
      return _UsageChip(
        icon: PhosphorIconsRegular.stethoscope,
        label: 'Врачей: $current${limit == null ? ' / ∞' : ' / $limit'}',
      );
    }
    if (sub.ownerType == 'pharmacy') {
      final current = sub.currentBranches ?? 0;
      final limit = sub.branchLimit;
      return _UsageChip(
        icon: PhosphorIconsRegular.storefront,
        label: 'Филиалов: $current${limit == null ? ' / ∞' : ' / $limit'}',
      );
    }
    return const SizedBox.shrink();
  }
}

class _UsageChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _UsageChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final dynamic plan;
  final String currentPlan;
  final VoidCallback onUpgrade;
  const _PlanCard({
    required this.plan,
    required this.currentPlan,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrent = plan.plan == currentPlan;
    final isFree = plan.plan == 'free';
    final isPremium = plan.plan == 'premium';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
        border: isCurrent ? Border.all(color: AppColors.primaryBlue, width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plan.plan.toString().toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isPremium ? const Color(0xFFFFB300) : AppColors.primaryBlue,
                ),
              ),
              if (isPremium) ...[
                const SizedBox(width: 8),
                Icon(PhosphorIconsFill.crown, size: 18, color: const Color(0xFFFFB300)),
              ],
              const Spacer(),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Текущий',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isFree) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '\$${plan.priceUsdMonth}',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  ' / мес',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '≈ ${plan.priceKgsMonth} с',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Год: \$${plan.priceUsdYear} (≈ ${plan.priceKgsYear} с) — экономия 2 мес.',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textPrimary.withValues(alpha: 0.5),
              ),
            ),
          ] else ...[
            Text(
              'Бесплатно',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          _PlanFeatures(plan: plan),
          if (!isCurrent && !isFree) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: onUpgrade,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPremium ? const Color(0xFFFFB300) : AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Выбрать',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlanFeatures extends StatelessWidget {
  final dynamic plan;
  const _PlanFeatures({required this.plan});

  @override
  Widget build(BuildContext context) {
    final features = <String>[];
    if (plan.doctorLimit != null) {
      features.add('До ${plan.doctorLimit} активных врачей');
    } else if (plan.plan != 'free') {
      features.add('Неограниченно врачей');
    }
    if (plan.branchLimit != null) {
      features.add('До ${plan.branchLimit} филиалов');
    } else if (plan.plan != 'free') {
      features.add('Неограниченно филиалов');
    }
    if (plan.hasReports) features.add('Раздел «Отчёты» с аналитикой');
    if (plan.hasBadge) features.add('Бейдж «Премиум» и приоритет в поиске');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: features.map((f) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(PhosphorIconsFill.checkCircle, size: 18, color: AppColors.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                f,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textPrimary.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}
