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

class DoctorSetupScreen extends ConsumerWidget {
  const DoctorSetupScreen({super.key});

  static const _stepTitles = [
    'Фото и ФИО',
    'Специализация',
    'Образование',
    'Услуги',
    'Контакты',
    'Адрес и график',
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
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        leading: state.currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: AppColors.textPrimary,
                onPressed: () =>
                    ref.read(doctorSetupProvider.notifier).prevStep(),
              )
            : null,
        title: Text(
          _stepTitles[state.currentStep],
          style: AppTextStyles.headingMedium,
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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: ref.read(doctorSetupProvider).fullName,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (img != null) {
      ref.read(doctorSetupProvider.notifier).setPhoto(img.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoPath = ref.watch(
      doctorSetupProvider.select((s) => s.photoPath),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Аватар
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundChip,
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
                          size: 52,
                          color: AppColors.primaryBlue,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      PhosphorIconsRegular.camera,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Text(
            'Нажмите чтобы выбрать фото',
            style: AppTextStyles.bodySmall,
          ),

          const SizedBox(height: 32),

          _FormField(
            label: 'ФИО *',
            hint: 'Иванов Иван Иванович',
            controller: _nameCtrl,
            onChanged: ref.read(doctorSetupProvider.notifier).setFullName,
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
              label: 'Цена (сом)',
              hint: '1000',
              controller: _offlinePriceCtrl,
              onChanged: n.setOfflinePrice,
              keyboard: TextInputType.number,
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
              label: 'Цена онлайн (сом)',
              hint: '800',
              controller: _onlinePriceCtrl,
              onChanged: n.setOnlinePrice,
              keyboard: TextInputType.number,
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
  late final TextEditingController _bioCtrl;
  late final TextEditingController _expCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(doctorSetupProvider);
    _bioCtrl = TextEditingController(text: s.bio);
    _expCtrl = TextEditingController(text: s.experienceYears);
  }

  @override
  void dispose() {
    _bioCtrl.dispose();
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
            label: 'Образование и опыт',
            hint: 'КГМА, ординатура по кардиологии...',
            controller: _bioCtrl,
            onChanged: n.setBio,
            maxLines: 5,
          ),
          const SizedBox(height: 20),
          _FormField(
            label: 'Стаж (лет)',
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
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _waCtrl;
  late final TextEditingController _tgCtrl;
  late final TextEditingController _igCtrl;

  @override
  void initState() {
    super.initState();
    final s = ref.read(doctorSetupProvider);
    _phoneCtrl = TextEditingController(text: s.phone);
    _waCtrl = TextEditingController(text: s.whatsapp);
    _tgCtrl = TextEditingController(text: s.telegram);
    _igCtrl = TextEditingController(text: s.instagram);
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
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
        children: [
          _ContactField(
            icon: PhosphorIconsRegular.phone,
            iconColor: AppColors.primaryBlue,
            label: 'Телефон',
            hint: '+996 700 000 000',
            controller: _phoneCtrl,
            onChanged: n.setPhone,
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _ContactField(
            icon: PhosphorIconsRegular.whatsappLogo,
            iconColor: const Color(0xFF25D366),
            label: 'WhatsApp',
            hint: '996700000000',
            controller: _waCtrl,
            onChanged: n.setWhatsapp,
            keyboard: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _ContactField(
            icon: PhosphorIconsRegular.telegramLogo,
            iconColor: const Color(0xFF0088CC),
            label: 'Telegram',
            hint: '@username',
            controller: _tgCtrl,
            onChanged: n.setTelegram,
          ),
          const SizedBox(height: 16),
          _ContactField(
            icon: PhosphorIconsRegular.instagramLogo,
            iconColor: const Color(0xFFE1306C),
            label: 'Instagram',
            hint: '@username',
            controller: _igCtrl,
            onChanged: n.setInstagram,
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
  late final TextEditingController _addressCtrl;

  @override
  void initState() {
    super.initState();
    _addressCtrl =
        TextEditingController(text: ref.read(doctorSetupProvider).address);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FormField(
            label: 'Адрес приёма',
            hint: 'ул. Чуй 123, кабинет 5',
            controller: _addressCtrl,
            onChanged: n.setAddress,
          ),

          const SizedBox(height: 28),
          Text('График работы', style: AppTextStyles.headingMedium),
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

  const _InlineField({
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboard,
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

class _ContactField extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final TextInputType? keyboard;

  const _ContactField({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.keyboard,
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
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodySmall,
                labelText: label,
                labelStyle: AppTextStyles.bodySmall,
                border: InputBorder.none,
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
