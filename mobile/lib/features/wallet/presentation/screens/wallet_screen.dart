import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/wallet_model.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(walletProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walletProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Мой счёт',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: state.isLoading && state.wallet == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(walletProvider.notifier).load(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _BalanceCard(wallet: state.wallet),
                  const SizedBox(height: 20),
                  Text(
                    'История операций',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.transactions.isEmpty)
                    _EmptyHistory()
                  else
                    ...state.transactions.map((t) => _TransactionTile(tx: t)),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final WalletModel? wallet;
  const _BalanceCard({required this.wallet});

  @override
  Widget build(BuildContext context) {
    final usd = wallet?.balanceUsd ?? 0;
    final kgs = wallet?.balanceKgs ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.btnGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Баланс',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '\$${usd.toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '≈ ${kgs.toStringAsFixed(0)} ₸',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => context.push('/wallet/topup'),
              icon: const Icon(PhosphorIconsRegular.plus, size: 18),
              label: Text(
                'Пополнить счёт',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Icon(
            PhosphorIconsRegular.receipt,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Операций пока нет',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WalletTransactionModel tx;
  const _TransactionTile({required this.tx});

  (IconData, Color, String) get _visuals {
    if (tx.status == 'cancelled') {
      return (PhosphorIconsRegular.xCircle, AppColors.error, 'Отклонено');
    }
    if (tx.status == 'pending') {
      return (PhosphorIconsRegular.clock, AppColors.warning, 'Ожидает');
    }
    // success
    switch (tx.type) {
      case 'topup':
        return (PhosphorIconsRegular.arrowDown, AppColors.success, 'Пополнение');
      case 'purchase':
        return (PhosphorIconsRegular.crown, AppColors.primaryBlue, 'Подписка');
      case 'refund':
        return (PhosphorIconsRegular.arrowUUpLeft, AppColors.success, 'Возврат');
      case 'credit':
        return (PhosphorIconsRegular.gift, AppColors.success, 'Зачисление');
      default:
        return (PhosphorIconsRegular.circle, AppColors.textSecondary, tx.type);
    }
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _visuals;
    final isCredit = tx.isCredit;
    final amountStr = '${isCredit ? '+' : '-'}\$${tx.amountUsd.toStringAsFixed(2)}';
    final amountColor = tx.status == 'success'
        ? (isCredit ? AppColors.success : AppColors.textPrimary)
        : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(tx.createdAt),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (tx.paymentCode != null && tx.status == 'pending') ...[
                  const SizedBox(height: 4),
                  Text(
                    'Код: ${tx.paymentCode}',
                    style: GoogleFonts.firaCode(
                      fontSize: 11,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (tx.comment != null && tx.status == 'cancelled') ...[
                  const SizedBox(height: 4),
                  Text(
                    tx.comment!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.error,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Text(
            amountStr,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }
}
