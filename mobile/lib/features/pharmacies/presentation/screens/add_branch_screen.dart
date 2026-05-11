import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../data/pharmacies_repository.dart';
import 'pharmacy_manage_screen.dart';

class AddBranchScreen extends ConsumerStatefulWidget {
  const AddBranchScreen({super.key});

  @override
  ConsumerState<AddBranchScreen> createState() => _AddBranchScreenState();
}

class _AddBranchScreenState extends ConsumerState<AddBranchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _mapLinkCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();

  bool _isOpen24h = false;
  bool _isLoading = false;
  String? _error;

  final List<String> _photoPaths = [];

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

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage(imageQuality: 85, maxWidth: 1200);
    if (files.isEmpty) return;
    setState(() {
      for (final f in files) {
        if (!_photoPaths.contains(f.path)) _photoPaths.add(f.path);
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(_branchRepoProvider);
      final company = await repo.getMyCompany();
      if (company == null) {
        setState(() {
          _error = 'Не удалось найти вашу аптечную компанию';
          _isLoading = false;
        });
        return;
      }

      final branch = await repo.createBranch(
        companyId: company.id,
        address: _addressCtrl.text.trim(),
        latitude: double.parse(_latCtrl.text.trim()),
        longitude: double.parse(_lonCtrl.text.trim()),
        phone: _phoneCtrl.text.trim().isNotEmpty
            ? '+996${_phoneCtrl.text.trim()}'
            : null,
        workingHours: _isOpen24h ? 'Круглосуточно' : _buildHoursString(),
        mapLink: _mapLinkCtrl.text.trim().isNotEmpty
            ? _mapLinkCtrl.text.trim()
            : null,
      );

      for (final path in _photoPaths) {
        final url = await repo.uploadPhoto(path);
        await repo.addBranchPhoto(branch.id, url);
      }

      ref.invalidate(myPharmacyCompanyProvider);
      if (mounted) context.pop();
    } catch (e) {
      setState(() {
        _error = 'Ошибка: ${e.toString()}';
        _isLoading = false;
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
        title: Text('Новый филиал', style: AppTextStyles.headingMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(PhosphorIconsFill.mapPin,
                        color: AppColors.warning, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Данные филиала', style: AppTextStyles.headingMedium),
                        Text('Адрес и контакты',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Галерея фото (вверху) ─────────────────────────────────────
              Row(
                children: [
                  _label('Фото филиала'),
                  const Spacer(),
                  if (_photoPaths.isNotEmpty)
                    GestureDetector(
                      onTap: _pickPhotos,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsRegular.plus,
                                color: AppColors.warning, size: 16),
                            const SizedBox(width: 4),
                            Text('Добавить',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.warning,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (_photoPaths.isEmpty)
                GestureDetector(
                  onTap: _pickPhotos,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(PhosphorIconsRegular.images,
                            color: AppColors.warning, size: 32),
                        const SizedBox(height: 8),
                        Text('Выбрать фото',
                            style: AppTextStyles.labelBold
                                .copyWith(color: AppColors.warning)),
                        Text('Можно выбрать несколько сразу',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photoPaths.length + 1,
                    itemBuilder: (_, i) {
                      if (i == _photoPaths.length) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: GestureDetector(
                            onTap: _pickPhotos,
                            child: Container(
                              width: 100,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color:
                                      AppColors.warning.withValues(alpha: 0.35),
                                  width: 1.5,
                                ),
                              ),
                              child: const Center(
                                child: Icon(PhosphorIconsRegular.plus,
                                    color: AppColors.warning, size: 24),
                              ),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.file(
                                File(_photoPaths[i]),
                                width: 100,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _photoPaths.removeAt(i)),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                  if (v == null || v.trim().isEmpty) return 'Введите адрес';
                  if (v.trim().length < 5) return 'Введите корректный адрес';
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
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 9,
                  style: AppTextStyles.bodyLarge,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    if (v.trim().length < 9) return 'Введите 9 цифр номера';
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
                      padding: const EdgeInsets.only(left: 16, right: 8),
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
                      borderSide:
                          const BorderSide(color: AppColors.error, width: 1),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.error, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _label('Ссылка на карту *'),
              const SizedBox(height: 8),
              _field(
                controller: _mapLinkCtrl,
                hint: 'https://2gis.kg/bishkek/...',
                icon: PhosphorIconsRegular.mapTrifold,
                keyboardType: TextInputType.url,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Введите ссылку на карту';
                  }
                  if (!v.trim().startsWith('https://')) {
                    return 'Ссылка должна начинаться с https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _label('Координаты *'),
              const SizedBox(height: 4),
              Text(
                'Найдите место на Google Maps → нажмите на точку → скопируйте координаты',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      controller: _latCtrl,
                      hint: '42.8746',
                      icon: PhosphorIconsRegular.arrowsVertical,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Обязательно';
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
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true, signed: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Обязательно';
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
                onTap: () => setState(() => _isOpen24h = !_isOpen24h),
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
                          color: AppColors.warning.withValues(alpha: 0.1),
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
                            Text('Круглосуточно', style: AppTextStyles.labelBold),
                            Text('24 часа, 7 дней в неделю',
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isOpen24h,
                        onChanged: (v) => setState(() => _isOpen24h = v),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    children: List.generate(7, (i) {
                      String fmt(TimeOfDay t) =>
                          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                      return _ScheduleRow(
                        label: _dayLabels[i],
                        enabled: _dayEnabled[i],
                        startLabel: fmt(_startTimes[i]),
                        endLabel: fmt(_endTimes[i]),
                        onToggle: (v) => setState(() => _dayEnabled[i] = v),
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
                text: 'Добавить филиал',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submit,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

final _branchRepoProvider =
    Provider<PharmaciesRepository>((_) => PharmaciesRepository());

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
