import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/wallet_model.dart';
import '../../providers/wallet_provider.dart';

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
  WalletTransactionModel? _createdRequest;

  @override
  void dispose() {
    _customCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  int? get _effectiveAmount {
    if (_selectedAmount != null) return _selectedAmount;
    final v = int.tryParse(_customCtrl.text.trim());
    return v;
  }

  Future<void> _submit(PaymentInfo info) async {
    final amount = _effectiveAmount;
    if (amount == null) return;
    if (amount < info.minAmountUsd || amount > info.maxAmountUsd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          'Сумма должна быть от \$${info.minAmountUsd} до \$${info.maxAmountUsd}',
        )),
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
      setState(() {
        _createdRequest = tx;
        _isSubmitting = false;
      });
      // Обновим список транзакций
      ref.read(walletProvider.notifier).load();
    } catch (e) {
      setState(() => _isSubmitting = false);
      String msg = 'Ошибка: $e';
      // Попробуем достать message из DioException → response.data.detail.message
      final s = e.toString();
      if (s.contains('pending_request_exists')) {
        msg = 'У вас уже есть активная заявка на пополнение';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final infoAsync = ref.watch(paymentInfoProvider);

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
      body: infoAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (info) => _createdRequest == null
            ? _TopupForm(
                info: info,
                selectedAmount: _selectedAmount,
                customCtrl: _customCtrl,
                commentCtrl: _commentCtrl,
                isSubmitting: _isSubmitting,
                onSelectAmount: (v) => setState(() {
                  _selectedAmount = v;
                  _customCtrl.clear();
                }),
                onCustomChanged: () => setState(() => _selectedAmount = null),
                onSubmit: () => _submit(info),
              )
            : _RequestCreated(
                tx: _createdRequest!,
                info: info,
                onDone: () => context.pop(),
              ),
      ),
    );
  }
}

class _TopupForm extends StatelessWidget {
  final PaymentInfo info;
  final int? selectedAmount;
  final TextEditingController customCtrl;
  final TextEditingController commentCtrl;
  final bool isSubmitting;
  final ValueChanged<int> onSelectAmount;
  final VoidCallback onCustomChanged;
  final VoidCallback onSubmit;

  const _TopupForm({
    required this.info,
    required this.selectedAmount,
    required this.customCtrl,
    required this.commentCtrl,
    required this.isSubmitting,
    required this.onSelectAmount,
    required this.onCustomChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    const presets = [20, 50, 100, 200];
    final canSubmit = !isSubmitting && (
      selectedAmount != null || (int.tryParse(customCtrl.text.trim()) ?? 0) > 0
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Сумма пополнения',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: presets.map((p) {
            final selected = selectedAmount == p;
            return GestureDetector(
              onTap: () => onSelectAmount(p),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryBlue : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? AppColors.primaryBlue : Colors.transparent,
                    width: 1.5,
                  ),
                  boxShadow: AppColors.cardShadow,
                ),
                child: Column(
                  children: [
                    Text(
                      '\$$p',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '≈ ${(p * info.usdToKgsRate).toStringAsFixed(0)} ₸',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: selected ? Colors.white.withValues(alpha: 0.85) : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: customCtrl,
          onChanged: (_) => onCustomChanged(),
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
          'Минимум \$${info.minAmountUsd}, максимум \$${info.maxAmountUsd}',
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: commentCtrl,
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
        const SizedBox(height: 24),
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
              const Icon(PhosphorIconsRegular.info, color: AppColors.primaryBlue, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'После нажатия кнопки вы получите уникальный код платежа и реквизиты MedFind. '
                  'Переведите сумму в своём банке, указав код в назначении платежа. '
                  'Баланс зачисляется в течение 24 часов после подтверждения админом.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textPrimary.withValues(alpha: 0.75),
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
            onPressed: canSubmit ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: isSubmitting
                ? const SizedBox(
                    width: 22, height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(
                    'Получить код и реквизиты',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}

class _RequestCreated extends StatelessWidget {
  final WalletTransactionModel tx;
  final PaymentInfo info;
  final VoidCallback onDone;
  const _RequestCreated({required this.tx, required this.info, required this.onDone});

  void _copy(BuildContext ctx, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(content: Text('$label скопировано'), duration: const Duration(seconds: 1)),
    );
  }

  String get _fullRequisites {
    return [
      'Получатель: ${info.companyName}',
      'ИНН: ${info.inn}',
      'Банк: ${info.bankName}',
      'Счёт: ${info.bankAccount}',
      'БИК: ${info.bankBik}',
      'Сумма: \$${tx.amountUsd.toStringAsFixed(0)}',
      'Назначение: ${tx.paymentCode}',
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Код платежа крупно
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            children: [
              Text('ВАШ КОД ПЛАТЕЖА',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  )),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _copy(context, tx.paymentCode ?? '', 'Код'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tx.paymentCode ?? '',
                        style: GoogleFonts.firaCode(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(PhosphorIconsRegular.copy, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(PhosphorIconsFill.warning, color: Colors.amber.shade300, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Обязательно укажите этот код в назначении платежа',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Реквизиты
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppColors.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Реквизиты MedFind',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      )),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _copy(context, _fullRequisites, 'Реквизиты'),
                    icon: const Icon(PhosphorIconsRegular.copy, size: 16),
                    label: Text('Скопировать всё',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const Divider(),
              _RequisiteRow(label: 'Получатель', value: info.companyName),
              _RequisiteRow(label: 'ИНН', value: info.inn),
              _RequisiteRow(label: 'Банк', value: info.bankName),
              _RequisiteRow(label: 'Счёт', value: info.bankAccount),
              _RequisiteRow(label: 'БИК', value: info.bankBik),
              _RequisiteRow(label: 'Сумма', value: '\$${tx.amountUsd.toStringAsFixed(0)}'),
              _RequisiteRow(label: 'Назначение', value: tx.paymentCode ?? '', highlight: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Что дальше
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(PhosphorIconsFill.checkCircle, color: AppColors.success, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Заявка создана. После того как переведёте деньги в банке, админ MedFind '
                  'подтвердит платёж в течение 24 часов. Вы получите уведомление.',
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
          height: 50,
          child: ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(
              'Готово',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequisiteRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _RequisiteRow({required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? AppColors.primaryBlue : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
