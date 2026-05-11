import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../providers/clinic_setup_provider.dart';

class ClinicSetupScreen extends ConsumerStatefulWidget {
  const ClinicSetupScreen({super.key});

  @override
  ConsumerState<ClinicSetupScreen> createState() => _ClinicSetupScreenState();
}

class _ClinicSetupScreenState extends ConsumerState<ClinicSetupScreen> {
  // Шаг 1
  final _descCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  List<String> _selectedCategories = [];
  final _step1Key = GlobalKey<FormState>();
  String _registeredName = '';
  String _registeredPhone = '';

  // Шаг 2
  final _addressCtrl = TextEditingController();
  final _mapUrlCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _telegramCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _step2Key = GlobalKey<FormState>();

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
    _endTimes = List.filled(7, const TimeOfDay(hour: 18, minute: 0));
    _loadAccountData();
  }

  Future<void> _loadAccountData() async {
    const storage = FlutterSecureStorage();
    final name = await storage.read(key: 'full_name') ?? '';
    final phone = await storage.read(key: 'user_phone') ?? '';
    if (mounted) {
      setState(() {
        _registeredName = name;
        _registeredPhone = phone;
      });
    }
  }

  String _buildHoursString() {
    final parts = <String>[];
    for (int i = 0; i < 7; i++) {
      if (!_dayEnabled[i]) continue;
      final s = _dayLabels[i];
      final st = _startTimes[i];
      final en = _endTimes[i];
      final sf =
          '${st.hour.toString().padLeft(2, '0')}:${st.minute.toString().padLeft(2, '0')}';
      final ef =
          '${en.hour.toString().padLeft(2, '0')}:${en.minute.toString().padLeft(2, '0')}';
      parts.add('$s $sf–$ef');
    }
    return parts.join(', ');
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _websiteCtrl.dispose();
    _addressCtrl.dispose();
    _mapUrlCtrl.dispose();
    _whatsappCtrl.dispose();
    _telegramCtrl.dispose();
    _instagramCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final notifier = ref.read(clinicSetupProvider.notifier);
    final step = ref.read(clinicSetupProvider).currentStep;

    if (step == 0) {
      if (!_step1Key.currentState!.validate()) return;
      if (_selectedCategories.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Выберите хотя бы одно направление')),
        );
        return;
      }
      notifier.updateStep1(
        descriptionRu: _descCtrl.text.trim(),
        categories: List.from(_selectedCategories),
        website: _websiteCtrl.text.trim(),
      );
      notifier.nextStep();
    } else if (step == 1) {
      if (!_step2Key.currentState!.validate()) return;
      notifier.updateStep2(
        addressRu: _addressCtrl.text.trim(),
        mapUrl: _mapUrlCtrl.text.trim(),
        whatsapp: _whatsappCtrl.text.trim(),
        telegram: _telegramCtrl.text.trim(),
        instagram: _instagramCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        workingHoursRu: _buildHoursString(),
      );
      notifier.nextStep();
    } else if (step == 2) {
      final ok = await notifier.submit();
      if (ok && mounted) {
        context.go('/provider/clinic-created');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clinicSetupProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft,
              color: AppColors.textPrimary),
          onPressed: () {
            if (state.currentStep > 0) {
              ref.read(clinicSetupProvider.notifier).prevStep();
            } else if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: _StepIndicator(
          currentStep: state.currentStep,
          totalSteps: 3,
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: switch (state.currentStep) {
          0 => _Step1(
              key: const ValueKey(0),
              formKey: _step1Key,
              descCtrl: _descCtrl,
              websiteCtrl: _websiteCtrl,
              selectedCategories: _selectedCategories,
              onCategoriesChanged: (v) =>
                  setState(() => _selectedCategories = v),
              registeredName: _registeredName,
              registeredPhone: _registeredPhone,
            ),
          1 => _Step2(
              key: const ValueKey(1),
              formKey: _step2Key,
              addressCtrl: _addressCtrl,
              mapUrlCtrl: _mapUrlCtrl,
              whatsappCtrl: _whatsappCtrl,
              telegramCtrl: _telegramCtrl,
              instagramCtrl: _instagramCtrl,
              emailCtrl: _emailCtrl,
              dayLabels: _dayLabels,
              dayEnabled: _dayEnabled,
              startTimes: _startTimes,
              endTimes: _endTimes,
              onDayToggle: (i, v) => setState(() => _dayEnabled[i] = v),
              onStartTime: (i, t) => setState(() => _startTimes[i] = t),
              onEndTime: (i, t) => setState(() => _endTimes[i] = t),
            ),
          _ => const _Step3(key: ValueKey(2)),
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(state.error!,
                    style:
                        AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
              ),
              const SizedBox(height: 12),
            ],
            GradientButton(
              text: state.currentStep < 2 ? 'Далее' : 'Зарегистрировать клинику',
              isLoading: state.isLoading,
              onPressed: state.isLoading ? null : _onNext,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step indicator ────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalSteps, (i) {
        final isActive = i == currentStep;
        final isDone = i < currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDone || isActive
                ? AppColors.primaryBlue
                : AppColors.backgroundChip,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Step 1: Основная информация ──────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController descCtrl;
  final TextEditingController websiteCtrl;
  final List<String> selectedCategories;
  final ValueChanged<List<String>> onCategoriesChanged;
  final String registeredName;
  final String registeredPhone;

  const _Step1({
    super.key,
    required this.formKey,
    required this.descCtrl,
    required this.websiteCtrl,
    required this.selectedCategories,
    required this.onCategoriesChanged,
    required this.registeredName,
    required this.registeredPhone,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(
              icon: PhosphorIconsFill.hospital,
              title: 'Основная информация',
              subtitle: 'Расскажите о вашей клинике',
            ),
            const SizedBox(height: 16),

            // Название и телефон из аккаунта (read-only)
            if (registeredName.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsFill.hospital,
                        color: AppColors.primaryBlue, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            registeredName,
                            style: AppTextStyles.labelBold
                                .copyWith(color: AppColors.textPrimary),
                          ),
                          if (registeredPhone.isNotEmpty)
                            Text(
                              registeredPhone,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'из аккаунта',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

            _ClinicLogoUpload(),
            const SizedBox(height: 24),

            _label('Описание'),
            const SizedBox(height: 8),
            _field(
              controller: descCtrl,
              hint: 'Кратко о специализации и услугах клиники',
              icon: PhosphorIconsRegular.textAlignLeft,
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            _label('Сайт'),
            const SizedBox(height: 8),
            _field(
              controller: websiteCtrl,
              hint: 'https://clinic.kg',
              icon: PhosphorIconsRegular.globe,
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final uri = Uri.tryParse(v.trim());
                if (uri == null ||
                    !uri.hasScheme ||
                    (!uri.scheme.startsWith('http') &&
                        !uri.scheme.startsWith('https')) ||
                    uri.host.isEmpty ||
                    !uri.host.contains('.')) {
                  return 'Введите корректный сайт (https://...)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            _label('Направления / Категории *'),
            const SizedBox(height: 4),
            Text(
              'Выберите одну или несколько',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _CategoryPickerButton(
              selected: selectedCategories,
              onChanged: onCategoriesChanged,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Адрес, координаты и контакты ────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController addressCtrl;
  final TextEditingController mapUrlCtrl;
  final TextEditingController whatsappCtrl;
  final TextEditingController telegramCtrl;
  final TextEditingController instagramCtrl;
  final TextEditingController emailCtrl;
  final List<String> dayLabels;
  final List<bool> dayEnabled;
  final List<TimeOfDay> startTimes;
  final List<TimeOfDay> endTimes;
  final void Function(int, bool) onDayToggle;
  final void Function(int, TimeOfDay) onStartTime;
  final void Function(int, TimeOfDay) onEndTime;

  const _Step2({
    super.key,
    required this.formKey,
    required this.addressCtrl,
    required this.mapUrlCtrl,
    required this.whatsappCtrl,
    required this.telegramCtrl,
    required this.instagramCtrl,
    required this.emailCtrl,
    required this.dayLabels,
    required this.dayEnabled,
    required this.startTimes,
    required this.endTimes,
    required this.onDayToggle,
    required this.onStartTime,
    required this.onEndTime,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(
              icon: PhosphorIconsFill.mapPin,
              title: 'Адрес и контакты',
              subtitle: 'Как пациенты вас найдут',
            ),
            const SizedBox(height: 32),

            _label('Адрес *'),
            const SizedBox(height: 8),
            _field(
              controller: addressCtrl,
              hint: 'г. Бишкек, ул. Киевская, 96',
              icon: PhosphorIconsRegular.mapPin,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите адрес' : null,
            ),
            const SizedBox(height: 20),

            _label('Ссылка на карту'),
            const SizedBox(height: 4),
            Text(
              'Вставьте ссылку из 2GIS или Google Maps',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            _field(
              controller: mapUrlCtrl,
              hint: 'https://go.2gis.com/...',
              icon: PhosphorIconsRegular.mapPin,
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
                  return 'Введите корректную ссылку';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            _label('Контакты (необязательно)'),
            const SizedBox(height: 12),
            _field(
              controller: whatsappCtrl,
              hint: '996700000000',
              icon: PhosphorIconsRegular.whatsappLogo,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (!RegExp(r'^\d{10,15}$').hasMatch(v.trim())) {
                  return 'Введите номер цифрами, например: 996700000000';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _prefixField(
              controller: telegramCtrl,
              hint: 'username',
              icon: PhosphorIconsRegular.telegramLogo,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (!RegExp(r'^[a-zA-Z0-9_]{5,32}$').hasMatch(v.trim())) {
                  return 'Только буквы, цифры и _, от 5 до 32 символов';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _prefixField(
              controller: instagramCtrl,
              hint: 'username',
              icon: PhosphorIconsRegular.instagramLogo,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (!RegExp(r'^[a-zA-Z0-9_.]{1,30}$').hasMatch(v.trim())) {
                  return 'Только буквы, цифры, _ и точка, до 30 символов';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _field(
              controller: emailCtrl,
              hint: 'clinic@example.kg',
              icon: PhosphorIconsRegular.envelope,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (!RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$')
                    .hasMatch(v.trim())) {
                  return 'Введите корректный email';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),

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
                  return _ScheduleRow(
                    label: dayLabels[i],
                    enabled: dayEnabled[i],
                    start: startTimes[i],
                    end: endTimes[i],
                    onToggle: (v) => onDayToggle(i, v),
                    onStartTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTimes[i],
                      );
                      if (picked != null) onStartTime(i, picked);
                    },
                    onEndTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTimes[i],
                      );
                      if (picked != null) onEndTime(i, picked);
                    },
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 3: Фото ─────────────────────────────────────────────────────────

class _Step3 extends ConsumerWidget {
  const _Step3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photos = ref.watch(
        clinicSetupProvider.select((s) => s.photoLocalPaths));
    final notifier = ref.read(clinicSetupProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            icon: PhosphorIconsFill.images,
            title: 'Фото клиники',
            subtitle: 'Добавьте несколько фотографий',
          ),
          const SizedBox(height: 24),

          // Сетка фото + кнопка добавления
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.0,
            ),
            itemCount: photos.length + 1,
            itemBuilder: (context, i) {
              if (i == photos.length) {
                return GestureDetector(
                  onTap: () => notifier.addPhoto(),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: AppColors.cardShadow,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.plus,
                            color: AppColors.primaryBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Добавить фото',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.primaryBlue),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(photos[i]),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => notifier.removePhoto(i),
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.info,
                    color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'После регистрации ваша клиника сразу станет видна пациентам.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Logo upload widget ────────────────────────────────────────────────────

class _ClinicLogoUpload extends ConsumerWidget {
  const _ClinicLogoUpload();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logoPath =
        ref.watch(clinicSetupProvider.select((s) => s.logoLocalPath));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Логотип (необязательно)'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () =>
              ref.read(clinicSetupProvider.notifier).pickAndUploadLogo(),
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primaryBlue.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: AppColors.cardShadow,
            ),
            child: logoPath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(File(logoPath), fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        PhosphorIconsRegular.image,
                        color: AppColors.primaryBlue,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Загрузить',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primaryBlue),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ─── Category picker button + bottom sheet ────────────────────────────────

class _CategoryPickerButton extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _CategoryPickerButton({
    required this.selected,
    required this.onChanged,
  });

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryBottomSheet(
        selected: List<String>.from(selected),
        onDone: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (selected.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: selected.map((cat) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      cat,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        final updated = List<String>.from(selected)..remove(cat);
                        onChanged(updated);
                      },
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        GestureDetector(
          onTap: () => _openSheet(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.list,
                    color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selected.isEmpty
                        ? 'Выбрать направления'
                        : '${selected.length} выбрано — изменить',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: selected.isEmpty
                          ? AppColors.textSecondary
                          : AppColors.primaryBlue,
                    ),
                  ),
                ),
                const Icon(PhosphorIconsRegular.caretDown,
                    color: AppColors.primaryBlue, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryBottomSheet extends StatefulWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onDone;

  const _CategoryBottomSheet({
    required this.selected,
    required this.onDone,
  });

  @override
  State<_CategoryBottomSheet> createState() => _CategoryBottomSheetState();
}

class _CategoryBottomSheetState extends State<_CategoryBottomSheet> {
  late List<String> _local;

  @override
  void initState() {
    super.initState();
    _local = List<String>.from(widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.backgroundApp,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.backgroundChip,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text('Направления / Категории',
                      style: AppTextStyles.headingMedium),
                ),
                if (_local.isNotEmpty)
                  Text(
                    '${_local.length} выбрано',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primaryBlue),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: AppConstants.clinicCategories.length,
              itemBuilder: (context, i) {
                final cat = AppConstants.clinicCategories[i];
                final isSelected = _local.contains(cat);
                return ListTile(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _local.remove(cat);
                      } else {
                        _local.add(cat);
                      }
                    });
                  },
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  title: Text(cat,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isSelected
                            ? AppColors.primaryBlue
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                      )),
                  trailing: isSelected
                      ? Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryBlue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 14),
                        )
                      : Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.backgroundChip, width: 2),
                          ),
                        ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                24, 12, 24, MediaQuery.of(context).padding.bottom + 16),
            child: GestureDetector(
              onTap: () {
                widget.onDone(_local);
                Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  gradient: AppColors.btnGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _local.isEmpty ? 'Выбрать' : 'Готово (${_local.length})',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared helpers ────────────────────────────────────────────────────────

Widget _header({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.btnGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.headingMedium),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ],
  );
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
  List<TextInputFormatter>? inputFormatters,
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
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        prefixIcon: maxLines == 1
            ? Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Icon(icon, color: AppColors.primaryBlue, size: 20),
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

Widget _prefixField({
  required TextEditingController controller,
  required String hint,
  required IconData icon,
  String? Function(String?)? validator,
}) {
  return Container(
    decoration: BoxDecoration(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(14),
      boxShadow: AppColors.cardShadow,
    ),
    child: TextFormField(
      controller: controller,
      style: AppTextStyles.bodyLarge,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(),
        prefix: Text('@',
            style: AppTextStyles.bodyLarge
                .copyWith(color: AppColors.textPrimary)),
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

// ─── Schedule row ──────────────────────────────────────────────────────────

class _ScheduleRow extends StatelessWidget {
  final String label;
  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;
  final ValueChanged<bool> onToggle;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const _ScheduleRow({
    required this.label,
    required this.enabled,
    required this.start,
    required this.end,
    required this.onToggle,
    required this.onStartTap,
    required this.onEndTap,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
            activeThumbColor: AppColors.primaryBlue,
            activeTrackColor: AppColors.primaryBlue.withValues(alpha: 0.4),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          if (enabled) ...[
            const SizedBox(width: 8),
            _TimeChip(time: _fmt(start), onTap: onStartTap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('—',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),
            _TimeChip(time: _fmt(end), onTap: onEndTap),
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
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(time,
            style:
                AppTextStyles.labelBold.copyWith(color: AppColors.primaryBlue)),
      ),
    );
  }
}
