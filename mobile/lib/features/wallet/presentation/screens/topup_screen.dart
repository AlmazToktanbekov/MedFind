import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/wallet_model.dart';
import '../../providers/wallet_provider.dart';

const _minAmount = 10;
const _maxAmount = 1000;

class TopupScreen extends ConsumerStatefulWidget {
  const TopupScreen({super.key});

  @override
  ConsumerState<TopupScreen> createState() => _TopupScreenState();
}

class _TopupScreenState extends ConsumerState<TopupScreen> {
  int? _selectedAmount = 50;
  final _customCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;
  PaymentInfo? _paymentInfo;

  @override
  void initState() {
    super.initState();
    _loadPaymentInfo();
  }

  Future<void> _loadPaymentInfo() async {
    try {
      final info = await ref.read(walletRepositoryProvider).getPaymentInfo();
      if (mounted) setState(() => _paymentInfo = info);
    } catch (_) {}
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  int? get _effectiveAmount {
    if (_selectedAmount != null) return _selectedAmount;
    return int.tryParse(_customCtrl.text.trim());
  }

  Future<void> _submit() async {
    final amount = _effectiveAmount;
    if (amount == null) return;
    if (amount < _minAmount || amount > _maxAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Сумма должна быть от \$$_minAmount до \$$_maxAmount')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final tx = await ref.read(walletRepositoryProvider).createTopupRequest(
            amountUsd: amount,
            comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
          );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showPaymentInstructions(tx);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    }
  }

  Future<void> _showPaymentInstructions(WalletTransactionModel tx) async {
    final info = _paymentInfo;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PaymentInstructionsSheet(tx: tx, info: info),
    );
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    const presets = [20, 50, 100, 200];
    final canSubmit = !_isSubmitting && (
      _selectedAmount != null || (int.tryParse(_customCtrl.text.trim()) ?? 0) > 0
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Пополнить счёт',
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
          Text(
            'Сумма пополнения',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: presets.map((p) {
              final selected = _selectedAmount == p;
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedAmount = p;
                  _customCtrl.clear();
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryBlue : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppColors.primaryBlue : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Text(
                    '\$$p',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _customCtrl,
            onChanged: (_) => setState(() => _selectedAmount = null),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Своя сумма (USD)',
              prefixText: '\$ ',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Минимум \$$_minAmount, максимум \$$_maxAmount',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _commentCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Комментарий (необязательно)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(PhosphorIconsFill.info,
                    color: AppColors.primaryBlue, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'После нажатия «Пополнить» вы получите уникальный код и реквизиты MedFind. Переведите сумму с расчётного счёта вашей организации, указав код в назначении платежа. Баланс пополнится после подтверждения админом.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textPrimary.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      'Получить реквизиты',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentInstructionsSheet extends StatelessWidget {
  final WalletTransactionModel tx;
  final PaymentInfo? info;

  const _PaymentInstructionsSheet({required this.tx, required this.info});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Реквизиты для перевода',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Заявка №${tx.id} на \$${tx.amountUsd.toStringAsFixed(0)} создана. Переведите сумму в банке, указав код в назначении платежа.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _CodeBlock(code: tx.paymentCode ?? '—'),
              const SizedBox(height: 20),
              if (info != null) ...[
                _InfoRow(label: 'Получатель', value: info!.companyName),
                _InfoRow(label: 'ИНН', value: info!.inn),
                _InfoRow(label: 'Банк', value: info!.bankName),
                _InfoRow(label: 'Расчётный счёт', value: info!.bankAccount),
                _InfoRow(label: 'БИК', value: info!.bankBik),
                const SizedBox(height: 8),
                Text(
                  'Поддержка: ${info!.supportPhone}',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
              ] else
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Готово',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;
  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Код в назначении платежа',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code,
                  style: GoogleFonts.robotoMono(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Код скопирован')),
              );
            },
            icon: const Icon(PhosphorIconsRegular.copy, color: AppColors.primaryBlue),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label скопирован')),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(PhosphorIconsRegular.copy,
                  color: AppColors.primaryBlue, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
