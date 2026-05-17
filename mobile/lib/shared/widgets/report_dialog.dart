import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/network/api_client.dart';
import '../../core/theme/app_colors.dart';

/// target_type: "doctor" | "clinic" | "pharmacy_branch" | "review"
class ReportDialog extends StatefulWidget {
  final String targetType;
  final int targetId;
  final String? targetTitle;

  const ReportDialog({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetTitle,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String targetType,
    required int targetId,
    String? targetTitle,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ReportDialog(
        targetType: targetType,
        targetId: targetId,
        targetTitle: targetTitle,
      ),
    );
  }

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  static const _reasons = <_Reason>[
    _Reason('wrong_info', 'Недостоверная информация'),
    _Reason('rude_behavior', 'Грубое поведение'),
    _Reason('fraud', 'Мошенничество'),
    _Reason('spam', 'Спам / реклама'),
    _Reason('fake', 'Поддельный профиль / отзыв'),
    _Reason('other', 'Другое'),
  ];

  String? _selectedReason;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) return;
    setState(() => _isSubmitting = true);
    try {
      await ApiClient().dio.post('/complaints', data: {
        'target_type': widget.targetType,
        'target_id': widget.targetId,
        'reason': _selectedReason,
        if (_commentCtrl.text.trim().isNotEmpty) 'comment': _commentCtrl.text.trim(),
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Жалоба отправлена. Спасибо!'),
          backgroundColor: AppColors.success,
        ),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final detail = e.response?.data is Map ? e.response?.data['detail'] : null;
      String msg = 'Не удалось отправить жалобу';
      if (detail == 'already_reported') {
        msg = 'Вы уже отправили жалобу на этот объект';
      } else if (detail == 'target_not_found') {
        msg = 'Объект не найден';
      } else if (e.response?.statusCode == 401) {
        msg = 'Войдите, чтобы оставить жалобу';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка соединения')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
              Row(
                children: [
                  const Icon(PhosphorIconsFill.flag, color: AppColors.error, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Пожаловаться',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.targetTitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  widget.targetTitle!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                'Укажите причину',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ..._reasons.map((r) => _ReasonTile(
                    reason: r,
                    selected: _selectedReason == r.code,
                    onTap: () => setState(() => _selectedReason = r.code),
                  )),
              const SizedBox(height: 16),
              TextField(
                controller: _commentCtrl,
                maxLines: 4,
                maxLength: 2000,
                decoration: InputDecoration(
                  hintText: 'Комментарий (необязательно)',
                  filled: true,
                  fillColor: const Color(0xFFEEF2FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_selectedReason == null || _isSubmitting) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.error.withValues(alpha: 0.3),
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
                          'Отправить жалобу',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
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

class _Reason {
  final String code;
  final String label;
  const _Reason(this.code, this.label);
}

class _ReasonTile extends StatelessWidget {
  final _Reason reason;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primaryBlue : AppColors.textSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                reason.label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
