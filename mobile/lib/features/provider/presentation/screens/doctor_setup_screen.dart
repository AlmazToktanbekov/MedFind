import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../providers/doctor_setup_provider.dart';

// ─── Main screen ───────────────────────────────────────────────────────────

class DoctorSetupScreen extends ConsumerStatefulWidget {
  const DoctorSetupScreen({super.key});

  @override
  ConsumerState<DoctorSetupScreen> createState() => _DoctorSetupScreenState();
}

class _DoctorSetupScreenState extends ConsumerState<DoctorSetupScreen> {
  @override
  Widget build(BuildContext context) => _DoctorSetupScreenView();
}

class _DoctorSetupScreenView extends ConsumerWidget {
  const _DoctorSetupScreenView();

  static const _stepTitles = [
    'Основная информация',
    'Специализация',
    'Образование',
    'Услуги',
    'Контакты',
    'График приёма',
    'Выбор клиники',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(doctorSetupProvider);

    // Навигация после успешной отправки
    ref.listen<DoctorSetupState>(doctorSetupProvider, (_, next) {
      if (next.isSubmitted) {
        context.go('/provider/pending');
      }
    });

    final steps = [
      const _Step1(),
      const _Step2(),
      const _Step3(),
      const _Step4(),
      const _Step5(),
      const _Step6(),
      const _Step7(),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: state.currentStep > 0
              ? () => ref.read(doctorSetupProvider.notifier).prevStep()
              : () => context.canPop() ? context.pop() : context.go('/main'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Регистрация врача',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            Text(
              _stepTitles[state.currentStep],
              style: AppTextStyles.headingMedium,
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // ── Индикатор шагов ───────────────────────────────────────
          _StepIndicator(
            current: state.currentStep,
            total: _stepTitles.length,
          ),

          // ── Контент ───────────────────────────────────────────────
          Expanded(
            child: IndexedStack(
              index: state.currentStep,
              children: steps,
            ),
          ),

          // ── Ошибка ───────────────────────────────────────────────
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                state.error!,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),

          // ── Кнопки навигации ─────────────────────────────────────
          _BottomNav(
            step: state.currentStep,
            isLoading: state.isLoading,
            total: _stepTitles.length,
          ),
        ],
      ),
    );
  }
}

// ─── Step indicator ────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int current;
  final int total;

  const _StepIndicator({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: List.generate(total, (i) {
          final done = i < current;
          final active = i == current;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 4,
              decoration: BoxDecoration(
                color: done || active
                    ? AppColors.primaryBlue
                    : AppColors.backgroundChip,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Bottom navigation ─────────────────────────────────────────────────────

class _BottomNav extends ConsumerWidget {
  final int step;
  final int total;
  final bool isLoading;

  const _BottomNav({
    required this.step,
    required this.total,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLast = step == total - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: GradientButton(
          text: isLast ? 'Отправить на проверку' : 'Далее →',
          isLoading: isLoading,
          onPressed: isLoading
              ? null
              : () {
                  if (isLast) {
                    ref.read(doctorSetupProvider.notifier).submit();
                  } else {
                    ref.read(doctorSetupProvider.notifier).nextStep();
                  }
                },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ШАГ 1 — Фото + ФИО
// ═══════════════════════════════════════════════════════════════════════════

class _Step1 extends ConsumerStatefulWidget {
  const _Step1();

  @override
  ConsumerState<_Step1> createState() => _Step1State();
}

class _Step1State extends ConsumerState<_Step1> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(doctorSetupProvider);
    _nameCtrl = TextEditingController(text: s.fullName);
    final rawPhone = s.phone.startsWith('+996') ? s.phone.substring(4) : s.phone;
    _phoneCtrl = TextEditingController(text: rawPhone);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      ref.read(doctorSetupProvider.notifier).setPhoto(img.path);
    }
  }

  Future<void> _pickCoverPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      ref.read(doctorSetupProvider.notifier).setCoverPhoto(img.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update controllers once async pre-fill from storage arrives
    ref.listen<DoctorSetupState>(doctorSetupProvider, (prev, next) {
      if (_nameCtrl.text.isEmpty && next.fullName.isNotEmpty) {
        _nameCtrl.text = next.fullName;
        _nameCtrl.selection =
            TextSelection.collapsed(offset: next.fullName.length);
      }
      if (_phoneCtrl.text.isEmpty && next.phone.isNotEmpty) {
        final raw = next.phone.startsWith('+996')
            ? next.phone.substring(4)
            : next.phone;
        _phoneCtrl.text = raw;
        _phoneCtrl.selection = TextSelection.collapsed(offset: raw.length);
      }
    });

    final photoPath = ref.watch(
      doctorSetupProvider.select((s) => s.photoPath),
    );
    final coverPhotoPath = ref.watch(
      doctorSetupProvider.select((s) => s.coverPhotoPath),
    );
    final coverPhotoUrl = ref.watch(
      doctorSetupProvider.select((s) => s.coverPhotoUrl),
    );
    final n = ref.read(doctorSetupProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Обложка ──────────────────────────────────────────────
          GestureDetector(
            onTap: _pickCoverPhoto,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    gradient: (coverPhotoPath == null && coverPhotoUrl == null)
                        ? AppColors.heroGradient
                        : null,
                    image: coverPhotoPath != null
                        ? DecorationImage(
                            image: FileImage(File(coverPhotoPath)),
                            fit: BoxFit.cover,
                          )
                        : coverPhotoUrl != null
                            ? DecorationImage(
                                image: NetworkImage(AppConstants.fixUrl(coverPhotoUrl)),
                                fit: BoxFit.cover,
                              )
                            : null,
                  ),
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(PhosphorIconsRegular.image, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Фото обложки',
                              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Аватар поверх обложки
                Positioned(
                  bottom: 0,
                  left: 24,
                  child: Transform.translate(
                    offset: const Offset(0, 40),
                    child: GestureDetector(
                      onTap: _pickPhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.backgroundChip,
                              border: Border.all(color: Colors.white, width: 3),
                              image: photoPath != null
                                  ? DecorationImage(
                                      image: FileImage(File(photoPath)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: photoPath == null
                                ? const Icon(
                                    PhosphorIconsRegular.userCircle,
                                    size: 44,
                                    color: AppColors.primaryBlue,
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                PhosphorIconsRegular.camera,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 56),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _FormField(
                  label: 'ФИО *',
                  hint: 'Иванов Иван Иванович',
                  controller: _nameCtrl,
                  onChanged: n.setFullName,
                ),
                const SizedBox(height: 20),
                _PhoneField(
                  label: 'Номер телефона *',
                  controller: _phoneCtrl,
                  onChanged: (v) => n.setPhone(v.isEmpty ? '' : '+996$v'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ШАГ 2 — Специализация
// ═══════════════════════════════════════════════════════════════════════════

class _Step2 extends ConsumerStatefulWidget {
  const _Step2();

  @override
  ConsumerState<_Step2> createState() => _Step2State();
}

class _Step2State extends ConsumerState<_Step2> {
  late final TextEditingController _onlinePriceCtrl;
  late final TextEditingController _offlinePriceCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(doctorSetupProvider);
    _onlinePriceCtrl = TextEditingController(text: s.onlinePrice);
    _offlinePriceCtrl = TextEditingController(text: s.offlinePrice);
  }

  @override
  void dispose() {
    _onlinePriceCtrl.dispose();
    _offlinePriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = ref.read(doctorSetupProvider.notifier);
    final specialization =
        ref.watch(doctorSetupProvider.select((s) => s.specialization));
    final hasOnline =
        ref.watch(doctorSetupProvider.select((s) => s.hasOnline));
    final hasOffline =
        ref.watch(doctorSetupProvider.select((s) => s.hasOffline));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Специализация *', style: AppTextStyles.labelBold),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: specialization.isNotEmpty ? specialization : null,
                hint: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('Выберите специализацию',
                      style: AppTextStyles.bodySmall),
                ),
                isExpanded: true,
                borderRadius: BorderRadius.circular(14),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                items: AppConstants.specializations
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) n.setSpecialization(v);
                },
              ),
            ),
          ),

          const SizedBox(height: 28),
          Text('Тип приёма', style: AppTextStyles.labelBold),
          const SizedBox(height: 12),

          _ToggleRow(
            label: 'Очный приём',
            value: hasOffline,
            onChanged: n.setHasOffline,
          ),
          if (hasOffline) ...[
            const SizedBox(height: 8),
            _FormField(
              label: 'Цена (сом) *',
              hint: '1000',
              controller: _offlinePriceCtrl,
              onChanged: n.setOfflinePrice,
              keyboard: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],

          const SizedBox(height: 12),
          _ToggleRow(
            label: 'Онлайн-консультация',
            value: hasOnline,
            onChanged: n.setHasOnline,
          ),
          if (hasOnline) ...[
            const SizedBox(height: 8),
            _FormField(
              label: 'Цена онлайн (сом) *',
              hint: '800',
              controller: _onlinePriceCtrl,
              onChanged: n.setOnlinePrice,
              keyboard: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ШАГ 3 — Образование + Стаж
// ═══════════════════════════════════════════════════════════════════════════

class _Step3 extends ConsumerStatefulWidget {
  const _Step3();

  @override
  ConsumerState<_Step3> createState() => _Step3State();
}

class _Step3State extends ConsumerState<_Step3> {
  late final TextEditingController _eduCtrl;
  late final TextEditingController _bioCtrl;
  late final TextEditingController _langCtrl;
  late final TextEditingController _expCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(doctorSetupProvider);
    _eduCtrl = TextEditingController(text: s.education);
    _bioCtrl = TextEditingController(text: s.bio);
    _langCtrl = TextEditingController(text: s.consultationLanguage);
    _expCtrl = TextEditingController(text: s.experienceYears);
  }

  @override
  void dispose() {
    _eduCtrl.dispose();
    _bioCtrl.dispose();
    _langCtrl.dispose();
    _expCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = ref.read(doctorSetupProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _FormField(
            label: 'Образование *',
            hint: 'КГМА, ординатура по кардиологии...',
            controller: _eduCtrl,
            onChanged: n.setEducation,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          _FormField(
            label: 'О себе *',
            hint: 'Опишите свой опыт и подход к пациентам...',
            controller: _bioCtrl,
            onChanged: n.setBio,
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          _FormField(
            label: 'Язык консультации *',
            hint: 'Русский, Кыргызский',
            controller: _langCtrl,
            onChanged: n.setConsultationLanguage,
          ),
          const SizedBox(height: 20),
          _FormField(
            label: 'Стаж (лет) *',
            hint: '5',
            controller: _expCtrl,
            onChanged: n.setExperienceYears,
            keyboard: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ШАГ 4 — Услуги и цены
// ═══════════════════════════════════════════════════════════════════════════

class _Step4 extends ConsumerStatefulWidget {
  const _Step4();

  @override
  ConsumerState<_Step4> createState() => _Step4State();
}

class _Step4State extends ConsumerState<_Step4> {
  // Контроллеры привязаны к индексам; пересоздаём при изменении списка
  final List<TextEditingController> _nameCtls = [];
  final List<TextEditingController> _priceCtls = [];

  @override
  void initState() {
    super.initState();
    _syncControllers(ref.read(doctorSetupProvider).services);
  }

  void _syncControllers(List<ServiceEntry> services) {
    while (_nameCtls.length < services.length) {
      final i = _nameCtls.length;
      _nameCtls.add(TextEditingController(text: services[i].name));
      _priceCtls.add(TextEditingController(text: services[i].price));
    }
    while (_nameCtls.length > services.length) {
      _nameCtls.removeLast().dispose();
      _priceCtls.removeLast().dispose();
    }
  }

  @override
  void dispose() {
    for (final c in _nameCtls) { c.dispose(); }
    for (final c in _priceCtls) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(doctorSetupProvider.select((s) => s.services));
    _syncControllers(services);
    final n = ref.read(doctorSetupProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Добавьте услуги, которые вы оказываете',
              style: AppTextStyles.bodySmall),
          const SizedBox(height: 16),

          ...List.generate(services.length, (i) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _InlineField(
                      hint: 'Название услуги',
                      controller: _nameCtls[i],
                      onChanged: (v) => n.updateService(
                          i, services[i].copyWith(name: v)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _InlineField(
                      hint: 'Цена, сом',
                      controller: _priceCtls[i],
                      keyboard: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) => n.updateService(
                          i, services[i].copyWith(price: v)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => n.removeService(i),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        PhosphorIconsRegular.trash,
                        color: AppColors.error,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          GestureDetector(
            onTap: n.addService,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                border: Border.all(
                    color: AppColors.primaryBlue.withValues(alpha: 0.4),
                    width: 1.5),
                borderRadius: BorderRadius.circular(14),
                color: AppColors.backgroundChip,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(PhosphorIconsRegular.plus,
                      color: AppColors.primaryBlue, size: 18),
                  const SizedBox(width: 8),
                  Text('Добавить услугу', style: AppTextStyles.labelBold),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ШАГ 5 — Контакты
// ═══════════════════════════════════════════════════════════════════════════

class _Step5 extends ConsumerStatefulWidget {
  const _Step5();

  @override
  ConsumerState<_Step5> createState() => _Step5State();
}

class _Step5State extends ConsumerState<_Step5> {
  late final TextEditingController _waCtrl;
  late final TextEditingController _tgCtrl;
  late final TextEditingController _igCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(doctorSetupProvider);
    final rawWa = s.whatsapp.startsWith('+996') ? s.whatsapp.substring(4) : s.whatsapp;
    _waCtrl = TextEditingController(text: rawWa);
    _tgCtrl = TextEditingController(text: s.telegram.replaceAll('@', ''));
    _igCtrl = TextEditingController(text: s.instagram.replaceAll('@', ''));
  }

  @override
  void dispose() {
    _waCtrl.dispose();
    _tgCtrl.dispose();
    _igCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = ref.read(doctorSetupProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    'Номер телефона вы указали на первом шаге. Здесь добавьте мессенджеры.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _ContactField(
            icon: PhosphorIconsRegular.whatsappLogo,
            iconColor: const Color(0xFF25D366),
            label: 'WhatsApp *',
            hint: '700 000 000',
            controller: _waCtrl,
            onChanged: (v) => n.setWhatsapp(v.isEmpty ? '' : '+996$v'),
            keyboard: TextInputType.phone,
            prefixText: '+996 ',
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 9,
          ),
          const SizedBox(height: 16),
          _ContactField(
            icon: PhosphorIconsRegular.telegramLogo,
            iconColor: const Color(0xFF0088CC),
            label: 'Telegram *',
            hint: 'username',
            controller: _tgCtrl,
            onChanged: (v) => n.setTelegram(v.replaceAll('@', '')),
            prefixText: '@',
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[@\s]'))],
          ),
          const SizedBox(height: 16),
          _ContactField(
            icon: PhosphorIconsRegular.instagramLogo,
            iconColor: const Color(0xFFE1306C),
            label: 'Instagram *',
            hint: 'username',
            controller: _igCtrl,
            onChanged: (v) => n.setInstagram(v.replaceAll('@', '')),
            prefixText: '@',
            inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'[@\s]'))],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ШАГ 6 — Адрес + График
// ═══════════════════════════════════════════════════════════════════════════

class _Step6 extends ConsumerStatefulWidget {
  const _Step6();

  @override
  ConsumerState<_Step6> createState() => _Step6State();
}

class _Step6State extends ConsumerState<_Step6> {
  Future<void> _pickTime(
    BuildContext ctx,
    ScheduleEntry entry,
    bool isStart,
  ) async {
    final n = ref.read(doctorSetupProvider.notifier);
    final picked = await showTimePicker(
      context: ctx,
      initialTime: isStart ? entry.startTime : entry.endTime,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    n.updateSchedule(
      entry.dayOfWeek,
      isStart
          ? entry.copyWith(startTime: picked)
          : entry.copyWith(endTime: picked),
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = ref.read(doctorSetupProvider.notifier);
    final schedules =
        ref.watch(doctorSetupProvider.select((s) => s.schedules));
    final clinicName = ref.watch(
        doctorSetupProvider.select((s) => s.selectedClinicName));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.mapPin,
                    color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    clinicName != null
                        ? 'Адрес приёма: берётся из клиники «$clinicName»'
                        : 'Адрес приёма берётся автоматически из выбранной вами клиники.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          Text('График приёма', style: AppTextStyles.headingMedium),
          const SizedBox(height: 12),

          ...schedules.map((entry) {
            return _ScheduleRow(
              entry: entry,
              onToggle: (v) =>
                  n.updateSchedule(entry.dayOfWeek, entry.copyWith(isAvailable: v)),
              onStartTap: () => _pickTime(context, entry, true),
              onEndTap: () => _pickTime(context, entry, false),
            );
          }),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  final ScheduleEntry entry;
  final ValueChanged<bool> onToggle;
  final VoidCallback onStartTap;
  final VoidCallback onEndTap;

  const _ScheduleRow({
    required this.entry,
    required this.onToggle,
    required this.onStartTap,
    required this.onEndTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              entry.label,
              style: AppTextStyles.bodyLarge
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: entry.isAvailable,
            onChanged: onToggle,
            activeThumbColor: AppColors.primaryBlue,
          ),
          const Spacer(),
          if (entry.isAvailable) ...[
            _TimeButton(time: entry.startStr, onTap: onStartTap),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('—',
                  style: AppTextStyles.bodySmall),
            ),
            _TimeButton(time: entry.endStr, onTap: onEndTap),
          ] else
            Text('Выходной',
                style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String time;
  final VoidCallback onTap;

  const _TimeButton({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundChip,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(time, style: AppTextStyles.labelBold),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ШАГ 7 — Выбор клиники
// ═══════════════════════════════════════════════════════════════════════════

class _Step7 extends ConsumerStatefulWidget {
  const _Step7();

  @override
  ConsumerState<_Step7> createState() => _Step7State();
}

class _Step7State extends ConsumerState<_Step7> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _results = []; });
      return;
    }
    setState(() { _searching = true; });
    try {
      final results = await ref.read(doctorSetupProvider.notifier).searchClinics(q.trim());
      if (mounted) setState(() { _results = results; _searching = false; });
    } catch (_) {
      if (mounted) setState(() { _searching = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(doctorSetupProvider.select((s) => s.selectedClinicId));
    final selectedName = ref.watch(doctorSetupProvider.select((s) => s.selectedClinicName));
    final n = ref.read(doctorSetupProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Найдите клинику, в которой вы работаете, и отправьте заявку на подтверждение.',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // Выбранная клиника
          if (selected != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.checkCircle,
                      color: AppColors.primaryBlue, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedName ?? '',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => n.clearClinic(),
                    child: const Icon(PhosphorIconsRegular.x,
                        color: AppColors.textSecondary, size: 18),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Поиск
          Container(
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Введите название клиники...',
                hintStyle: AppTextStyles.bodySmall,
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass,
                    color: AppColors.textSecondary, size: 20),
                suffixIcon: _searching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Результаты поиска
          ..._results.map((clinic) {
            final id = clinic['id'] as int?;
            final name = clinic['name_ru'] as String? ?? '';
            final address = clinic['address_ru'] as String? ?? '';
            final logoUrl = clinic['logo_url'] as String?;
            final isSelected = id != null && id == selected;
            return GestureDetector(
              onTap: () {
                if (id != null) {
                  n.setClinic(id, name);
                  setState(() { _results = []; _searchCtrl.clear(); });
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryBlue.withValues(alpha: 0.06)
                      : AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppColors.cardShadow,
                  border: isSelected
                      ? Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.3))
                      : null,
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: logoUrl != null
                          ? Image.network(
                              AppConstants.fixUrl(logoUrl),
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, _) =>
                                  const _ClinicSearchLogoPlaceholder(),
                            )
                          : const _ClinicSearchLogoPlaceholder(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: AppTextStyles.labelBold),
                          if (address.isNotEmpty)
                            Text(address,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    if (isSelected)
                      const Icon(PhosphorIconsRegular.checkCircle,
                          color: AppColors.primaryBlue, size: 20),
                  ],
                ),
              ),
            );
          }),

          if (_results.isEmpty && _searchCtrl.text.isNotEmpty && !_searching)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Center(
                child: Text(
                  'Клиника не найдена. Попробуйте другой запрос.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared form widgets
// ═══════════════════════════════════════════════════════════════════════════

class _FormField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboard;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const _FormField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.keyboard,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelBold),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.cardShadow,
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: keyboard,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodySmall,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? inputFormatters;

  const _InlineField({
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.keyboard,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboard,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodySmall
          .copyWith(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodySmall,
        isDense: true,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyLarge),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _PhoneField({
    required this.label,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelBold),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(14),
            boxShadow: AppColors.cardShadow,
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 9,
            style: AppTextStyles.bodyLarge,
            decoration: InputDecoration(
              hintText: '700 000 000',
              hintStyle: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              prefixText: '+996 ',
              prefixStyle: AppTextStyles.bodyLarge
                  .copyWith(fontWeight: FontWeight.w600),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: InputBorder.none,
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboard;
  final String? prefixText;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;

  const _ContactField({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.keyboard,
    this.prefixText,
    this.inputFormatters,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              keyboardType: keyboard,
              inputFormatters: inputFormatters,
              maxLength: maxLength,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
                labelText: label,
                labelStyle: AppTextStyles.bodySmall,
                prefixText: prefixText,
                prefixStyle: AppTextStyles.bodyLarge
                    .copyWith(fontWeight: FontWeight.w600),
                border: InputBorder.none,
                counterText: '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 0, vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 14),
        ],
      ),
    );
  }
}

class _ClinicSearchLogoPlaceholder extends StatelessWidget {
  const _ClinicSearchLogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.backgroundChip,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(
        PhosphorIconsRegular.hospital,
        color: AppColors.primaryBlue,
        size: 22,
      ),
    );
  }
}
