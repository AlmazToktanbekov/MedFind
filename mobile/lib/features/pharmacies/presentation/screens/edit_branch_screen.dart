import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../data/pharmacies_repository.dart';
import 'pharmacy_manage_screen.dart';

final _editBranchRepoProvider =
    Provider<PharmaciesRepository>((_) => PharmaciesRepository());

class EditBranchScreen extends ConsumerStatefulWidget {
  final int branchId;
  const EditBranchScreen({super.key, required this.branchId});

  @override
  ConsumerState<EditBranchScreen> createState() => _EditBranchScreenState();
}

class _EditBranchScreenState extends ConsumerState<EditBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mapLinkCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();

  bool _isOpen24h = false;
  bool _isActive = true;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;

  static const _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  late List<bool> _dayEnabled;
  late List<TimeOfDay> _startTimes;
  late List<TimeOfDay> _endTimes;

  @override
  void initState() {
    super.initState();
    _dayEnabled = List.filled(7, false)
      ..[0] = true
      ..[1] = true
      ..[2] = true
      ..[3] = true
      ..[4] = true;
    _startTimes = List.filled(7, const TimeOfDay(hour: 9, minute: 0));
    _endTimes = List.filled(7, const TimeOfDay(hour: 21, minute: 0));
    _loadBranch();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _mapLinkCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBranch() async {
    setState(() => _isLoading = true);
    try {
      final branch = await ref
          .read(_editBranchRepoProvider)
          .getBranchById(widget.branchId);
      _isActive = branch.isActive;

      final phone = branch.phone ?? '';
      _addressCtrl.text = branch.address ?? '';
      _phoneCtrl.text =
          phone.startsWith('+996') ? phone.substring(4) : phone;
      _latCtrl.text = branch.latitude?.toString() ?? '';
      _lonCtrl.text = branch.longitude?.toString() ?? '';

      // Парсим график работы
      final wh = branch.workingHours ?? '';
      if (wh == 'Круглосуточно') {
        _isOpen24h = true;
      } else if (wh.isNotEmpty) {
        _parseWorkingHours(wh);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = 'Ошибка загрузки: $e';
        _isLoading = false;
      });
    }
  }

  void _parseWorkingHours(String wh) {
    final parts = wh.split(', ');
    final dayMap = {
      'Пн': 0, 'Вт': 1, 'Ср': 2, 'Чт': 3,
      'Пт': 4, 'Сб': 5, 'Вс': 6,
    };
    _dayEnabled = List.filled(7, false);
    for (final part in parts) {
      final segments = part.split(' ');
      if (segments.length < 2) continue;
      final dayIdx = dayMap[segments[0]];
      if (dayIdx == null) continue;
      _dayEnabled[dayIdx] = true;
      final times = segments[1].split('-');
      if (times.length < 2) continue;
      _startTimes[dayIdx] = _parseTime(times[0]);
      _endTimes[dayIdx] = _parseTime(times[1]);
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    if (parts.length < 2) return const TimeOfDay(hour: 9, minute: 0);
    return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0);
  }

  String _buildHoursString() {
    final parts = <String>[];
    for (int i = 0; i < 7; i++) {
      if (!_dayEnabled[i]) continue;
      final s = _startTimes[i];
      final e = _endTimes[i];
      final sf =
          '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
      final ef =
          '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
      parts.add('${_dayLabels[i]} $sf-$ef');
    }
    return parts.join(', ');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final phone = _phoneCtrl.text.trim();
      await ref.read(_editBranchRepoProvider).updateBranch(
            branchId: widget.branchId,
            address: _addressCtrl.text.trim(),
            latitude: double.tryParse(_latCtrl.text.trim()),
            longitude: double.tryParse(_lonCtrl.text.trim()),
            phone: phone.isNotEmpty ? '+996$phone' : '',
            workingHours:
                _isOpen24h ? 'Круглосуточно' : _buildHoursString(),
            mapLink: _mapLinkCtrl.text.trim().isNotEmpty
                ? _mapLinkCtrl.text.trim()
                : null,
            isActive: _isActive,
          );

      ref.invalidate(myPharmacyCompanyProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _error = 'Ошибка сохранения: $e';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Редактировать филиал',
            style: AppTextStyles.headingMedium),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Статус активности
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isActive = !_isActive),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (_isActive
                                        ? AppColors.success
                                        : AppColors.textSecondary)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isActive
                                    ? PhosphorIconsFill.checkCircle
                                    : PhosphorIconsRegular.prohibit,
                                color: _isActive
                                    ? AppColors.success
                                    : AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Филиал активен',
                                      style: AppTextStyles.labelBold),
                                  Text(
                                    _isActive
                                        ? 'Виден пользователям'
                                        : 'Скрыт от пользователей',
                                    style: AppTextStyles.bodySmall.copyWith(
                                        color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: (v) =>
                                  setState(() => _isActive = v),
                              activeThumbColor: AppColors.success,
                              activeTrackColor:
                                  AppColors.success.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    _label('Адрес *'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _addressCtrl,
                      hint: 'г. Бишкек, ул. Токтогула, 98',
                      icon: PhosphorIconsRegular.mapPin,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Введите адрес';
                        }
                        if (v.trim().length < 5) {
                          return 'Введите корректный адрес';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Телефон филиала'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.backgroundCard,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        maxLength: 9,
                        style: AppTextStyles.bodyLarge,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          if (v.trim().length < 9) {
                            return 'Введите 9 цифр номера';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          hintText: '700 000 000',
                          hintStyle: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                          prefixText: '+996 ',
                          prefixStyle: AppTextStyles.bodyLarge
                              .copyWith(fontWeight: FontWeight.w600),
                          prefixIcon: Padding(
                            padding:
                                const EdgeInsets.only(left: 16, right: 8),
                            child: Icon(PhosphorIconsRegular.phone,
                                color: AppColors.warning, size: 20),
                          ),
                          prefixIconConstraints: const BoxConstraints(),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          border: InputBorder.none,
                          counterText: '',
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.error, width: 1),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                                color: AppColors.error, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _label('Ссылка на карту'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _mapLinkCtrl,
                      hint: 'https://2gis.kg/bishkek/...',
                      icon: PhosphorIconsRegular.mapTrifold,
                      keyboardType: TextInputType.url,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!v.trim().startsWith('https://')) {
                          return 'Ссылка должна начинаться с https://';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _label('Координаты'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _field(
                            controller: _latCtrl,
                            hint: '42.8746',
                            icon: PhosphorIconsRegular.arrowsVertical,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final d = double.tryParse(v.trim());
                              if (d == null) return 'Неверный формат';
                              if (d < -90 || d > 90) return '-90 до 90';
                              return null;
                            },
                            labelOverride: 'Широта',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            controller: _lonCtrl,
                            hint: '74.5698',
                            icon: PhosphorIconsRegular.arrowsHorizontal,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return null;
                              final d = double.tryParse(v.trim());
                              if (d == null) return 'Неверный формат';
                              if (d < -180 || d > 180) return '-180 до 180';
                              return null;
                            },
                            labelOverride: 'Долгота',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Круглосуточно
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isOpen24h = !_isOpen24h),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.warning.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(PhosphorIconsFill.moon,
                                  color: AppColors.warning, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Круглосуточно',
                                      style: AppTextStyles.labelBold),
                                  Text('24 часа, 7 дней в неделю',
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isOpen24h,
                              onChanged: (v) =>
                                  setState(() => _isOpen24h = v),
                              activeThumbColor: AppColors.warning,
                              activeTrackColor:
                                  AppColors.warning.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (!_isOpen24h) ...[
                      const SizedBox(height: 16),
                      _label('Режим работы'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundCard,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.cardShadow,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Column(
                          children: List.generate(7, (i) {
                            String fmt(TimeOfDay t) =>
                                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                            return _ScheduleRow(
                              label: _dayLabels[i],
                              enabled: _dayEnabled[i],
                              startLabel: fmt(_startTimes[i]),
                              endLabel: fmt(_endTimes[i]),
                              onToggle: (v) =>
                                  setState(() => _dayEnabled[i] = v),
                              onStartTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _startTimes[i],
                                );
                                if (picked != null) {
                                  setState(() => _startTimes[i] = picked);
                                }
                              },
                              onEndTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _endTimes[i],
                                );
                                if (picked != null) {
                                  setState(() => _endTimes[i] = picked);
                                }
                              },
                            );
                          }),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    if (_error != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_error!,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.error)),
                      ),
                      const SizedBox(height: 12),
                    ],

                    GradientButton(
                      text: 'Сохранить',
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _save,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── Schedule row ───────────────────────────────────────────────────────────

class _ScheduleRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final String startLabel;
  final String endLabel;
  final ValueChanged<bool> onToggle;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const _ScheduleRow({
    required this.label,
    required this.enabled,
    required this.startLabel,
    required this.endLabel,
    required this.onToggle,
    required this.onStartTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(label,
                style: AppTextStyles.labelBold
                    .copyWith(color: AppColors.textPrimary)),
          ),
          Switch(
            value: enabled,
            onChanged: onToggle,
            activeThumbColor: AppColors.warning,
            activeTrackColor: AppColors.warning.withValues(alpha: 0.4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (enabled) ...[
            const SizedBox(width: 8),
            _TimeChip(time: startLabel, onTap: onStartTap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('—',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            _TimeChip(time: endLabel, onTap: onEndTap),
          ] else ...[
            const SizedBox(width: 8),
            Text('Выходной',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const _TimeChip({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(time,
            style: AppTextStyles.labelBold.copyWith(color: AppColors.warning)),
      ),
    );
  }
}

Widget _label(String text) => Text(
      text,
      style: AppTextStyles.labelBold.copyWith(color: AppColors.textPrimary),
    );

Widget _field({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  int maxLines = 1,
  TextInputType keyboardType = TextInputType.text,
  String? Function(String?)? validator,
  String? labelOverride,
}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(14),
      boxShadow: AppColors.cardShadow,
    ),
    child: TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyLarge,
      validator: validator,
      decoration: InputDecoration(
        hintText: labelOverride ?? hint,
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        prefixIcon: maxLines == 1
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(icon, color: AppColors.warning, size: 20),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
