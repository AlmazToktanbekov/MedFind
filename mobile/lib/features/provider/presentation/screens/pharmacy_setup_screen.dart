import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../providers/pharmacy_setup_provider.dart';

class PharmacySetupScreen extends ConsumerStatefulWidget {
  const PharmacySetupScreen({super.key});

  @override
  ConsumerState<PharmacySetupScreen> createState() =>
      _PharmacySetupScreenState();
}

class _PharmacySetupScreenState extends ConsumerState<PharmacySetupScreen> {
  // Шаг 1 — Компания
  final _websiteCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _whatsappCtrl = TextEditingController();
  final _instagramCtrl = TextEditingController();
  final _step1Key = GlobalKey<FormState>();
  String _registeredName = '';
  String _registeredPhone = '';

  // Шаг 2 — Первый филиал
  final _addressCtrl = TextEditingController();
  final _branchPhoneCtrl = TextEditingController();
  final _mapLinkCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  bool _isOpen24h = false;
  final _step2Key = GlobalKey<FormState>();

  // График работы филиала
  static const _dayLabels = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
  late List<bool> _dayEnabled;
  late List<TimeOfDay> _startTimes;
  late List<TimeOfDay> _endTimes;

  @override
  void initState() {
    super.initState();
    _dayEnabled = List.filled(7, false)..[0] = true..[1] = true..[2] = true..[3] = true..[4] = true;
    _startTimes = List.filled(7, const TimeOfDay(hour: 9, minute: 0));
    _endTimes = List.filled(7, const TimeOfDay(hour: 21, minute: 0));
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
      final s = _startTimes[i];
      final e = _endTimes[i];
      final sf = '${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
      final ef = '${e.hour.toString().padLeft(2, '0')}:${e.minute.toString().padLeft(2, '0')}';
      parts.add('${_dayLabels[i]} $sf-$ef');
    }
    return parts.join(', ');
  }

  @override
  void dispose() {
    _websiteCtrl.dispose();
    _descCtrl.dispose();
    _whatsappCtrl.dispose();
    _instagramCtrl.dispose();
    _addressCtrl.dispose();
    _branchPhoneCtrl.dispose();
    _mapLinkCtrl.dispose();
    _latCtrl.dispose();
    _lonCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final notifier = ref.read(pharmacySetupProvider.notifier);
    final step = ref.read(pharmacySetupProvider).currentStep;

    if (step == 0) {
      if (!_step1Key.currentState!.validate()) return;
      final authRepo = ref.read(authRepositoryProvider);
      final companyName = await authRepo.getFullName() ?? '';
      final mainPhone = await authRepo.getPhone() ?? '';
      notifier.updateStep1(
        companyName: companyName,
        mainPhone: mainPhone,
        website: _websiteCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        whatsapp: _whatsappCtrl.text.trim(),
        instagram: _instagramCtrl.text.trim(),
      );
      notifier.nextStep();
    } else if (step == 1) {
      if (!_step2Key.currentState!.validate()) return;
      notifier.updateStep2(
        branchAddress: _addressCtrl.text.trim(),
        branchPhone: _branchPhoneCtrl.text.trim(),
        mapLink: _mapLinkCtrl.text.trim(),
        latitude: double.tryParse(_latCtrl.text.trim()) ?? 0.0,
        longitude: double.tryParse(_lonCtrl.text.trim()) ?? 0.0,
        workingHours: _isOpen24h ? 'Круглосуточно' : _buildHoursString(),
        isOpen24h: _isOpen24h,
      );
      final ok = await notifier.submit();
      if (ok && mounted) {
        context.go('/provider/pharmacy/manage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pharmacySetupProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: state.currentStep > 0
            ? IconButton(
                icon: const Icon(PhosphorIconsRegular.arrowLeft,
                    color: AppColors.textPrimary),
                onPressed: () =>
                    ref.read(pharmacySetupProvider.notifier).prevStep(),
              )
            : null,
        title: _StepIndicator(
          currentStep: state.currentStep,
          totalSteps: 2,
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
              websiteCtrl: _websiteCtrl,
              descCtrl: _descCtrl,
              whatsappCtrl: _whatsappCtrl,
              instagramCtrl: _instagramCtrl,
              registeredName: _registeredName,
              registeredPhone: _registeredPhone,
            ),
          _ => _Step2(
              key: const ValueKey(1),
              formKey: _step2Key,
              addressCtrl: _addressCtrl,
              branchPhoneCtrl: _branchPhoneCtrl,
              mapLinkCtrl: _mapLinkCtrl,
              latCtrl: _latCtrl,
              lonCtrl: _lonCtrl,
              isOpen24h: _isOpen24h,
              onToggle24h: (v) => setState(() => _isOpen24h = v),
              dayLabels: _dayLabels,
              dayEnabled: _dayEnabled,
              startTimes: _startTimes,
              endTimes: _endTimes,
              onDayToggle: (i, v) => setState(() => _dayEnabled[i] = v),
              onStartTime: (i, t) => setState(() => _startTimes[i] = t),
              onEndTime: (i, t) => setState(() => _endTimes[i] = t),
            ),
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
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.error)),
              ),
              const SizedBox(height: 12),
            ],
            GradientButton(
              text: state.currentStep < 1 ? 'Далее' : 'Зарегистрировать аптеку',
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
                ? AppColors.warning
                : AppColors.backgroundChip,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Step 1: Данные компании ───────────────────────────────────────────────

class _Step1 extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController websiteCtrl;
  final TextEditingController descCtrl;
  final TextEditingController whatsappCtrl;
  final TextEditingController instagramCtrl;
  final String registeredName;
  final String registeredPhone;

  const _Step1({
    super.key,
    required this.formKey,
    required this.websiteCtrl,
    required this.descCtrl,
    required this.whatsappCtrl,
    required this.instagramCtrl,
    required this.registeredName,
    required this.registeredPhone,
  });

  Widget _buildCoverPicker(PharmacySetupState state, PharmacySetupNotifier notifier) {
    return GestureDetector(
      onTap: notifier.pickCoverPhoto,
      child: Container(
        width: double.infinity,
        height: 140,
        decoration: BoxDecoration(
          color: AppColors.backgroundChip,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.4),
            width: 1.5,
            style: BorderStyle.solid,
          ),
          image: state.coverLocalPath != null
              ? DecorationImage(
                  image: FileImage(File(state.coverLocalPath!)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: state.coverLocalPath == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIconsRegular.image,
                      color: AppColors.warning, size: 32),
                  const SizedBox(height: 8),
                  Text('Фото обложки (необязательно)',
                      style: AppTextStyles.labelBold
                          .copyWith(color: AppColors.warning)),
                  const SizedBox(height: 4),
                  Text('Баннер за логотипом на профиле',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              )
            : Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(PhosphorIconsRegular.pencilSimple,
                        color: Colors.white, size: 14),
                  ),
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pharmacySetupProvider);
    final notifier = ref.read(pharmacySetupProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(
              icon: PhosphorIconsFill.pill,
              title: 'Данные компании',
              subtitle: 'Информация о вашей аптечной сети',
            ),
            const SizedBox(height: 16),

            // Название и телефон из аккаунта (read-only)
            if (registeredName.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(PhosphorIconsFill.pill,
                        color: AppColors.warning, size: 20),
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

            // Обложка профиля
            _buildCoverPicker(state, notifier),
            const SizedBox(height: 16),

            // Логотип
            Center(
              child: GestureDetector(
                onTap: notifier.pickLogo,
                child: Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundChip,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        image: state.logoLocalPath != null
                            ? DecorationImage(
                                image: FileImage(File(state.logoLocalPath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: state.logoLocalPath == null
                          ? const Icon(PhosphorIconsRegular.pill,
                              size: 36, color: AppColors.warning)
                          : null,
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(PhosphorIconsRegular.camera,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('Логотип (необязательно)',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ),

            const SizedBox(height: 24),
            _label('Сайт'),
            const SizedBox(height: 8),
            _field(
              controller: websiteCtrl,
              hint: 'https://apteka.kg',
              icon: PhosphorIconsRegular.globe,
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final url = v.trim();
                if (!url.startsWith('https://')) {
                  return 'Ссылка должна начинаться с https://';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _label('WhatsApp'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow,
              ),
              child: TextFormField(
                controller: whatsappCtrl,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 9,
                style: AppTextStyles.bodyLarge,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (v.trim().length < 9) return 'Введите 9 цифр';
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
                    child: const Icon(PhosphorIconsRegular.whatsappLogo,
                        color: AppColors.warning, size: 20),
                  ),
                  prefixIconConstraints: const BoxConstraints(),
                  counterText: '',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
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
            _label('Instagram'),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow,
              ),
              child: TextFormField(
                controller: instagramCtrl,
                keyboardType: TextInputType.text,
                style: AppTextStyles.bodyLarge,
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'\s')),
                ],
                decoration: InputDecoration(
                  hintText: 'apteka_kg',
                  hintStyle: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  prefixText: '@',
                  prefixStyle: AppTextStyles.bodyLarge
                      .copyWith(fontWeight: FontWeight.w600),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: const Icon(PhosphorIconsRegular.instagramLogo,
                        color: AppColors.warning, size: 20),
                  ),
                  prefixIconConstraints: const BoxConstraints(),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 16),
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
            _label('Описание'),
            const SizedBox(height: 8),
            _field(
              controller: descCtrl,
              hint: 'Кратко о вашей аптечной сети...',
              icon: PhosphorIconsRegular.textAlignLeft,
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Первый филиал ─────────────────────────────────────────────────

class _Step2 extends ConsumerWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController addressCtrl;
  final TextEditingController branchPhoneCtrl;
  final TextEditingController mapLinkCtrl;
  final TextEditingController latCtrl;
  final TextEditingController lonCtrl;
  final bool isOpen24h;
  final ValueChanged<bool> onToggle24h;
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
    required this.branchPhoneCtrl,
    required this.mapLinkCtrl,
    required this.latCtrl,
    required this.lonCtrl,
    required this.isOpen24h,
    required this.onToggle24h,
    required this.dayLabels,
    required this.dayEnabled,
    required this.startTimes,
    required this.endTimes,
    required this.onDayToggle,
    required this.onStartTime,
    required this.onEndTime,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pharmacySetupProvider);
    final notifier = ref.read(pharmacySetupProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(
              icon: PhosphorIconsFill.mapPin,
              title: 'Первый филиал',
              subtitle: 'Адрес и контакты вашей аптеки',
            ),
            const SizedBox(height: 28),

            _label('Адрес *'),
            const SizedBox(height: 8),
            _field(
              controller: addressCtrl,
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
                controller: branchPhoneCtrl,
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              controller: mapLinkCtrl,
              hint: 'https://2gis.kg/bishkek/...',
              icon: PhosphorIconsRegular.mapTrifold,
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Введите ссылку на карту';
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
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _field(
                    controller: latCtrl,
                    hint: '42.8746',
                    icon: PhosphorIconsRegular.arrowsVertical,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
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
                    controller: lonCtrl,
                    hint: '74.5698',
                    icon: PhosphorIconsRegular.arrowsHorizontal,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
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
              onTap: () => onToggle24h(!isOpen24h),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      value: isOpen24h,
                      onChanged: onToggle24h,
                      activeThumbColor: AppColors.warning,
                      activeTrackColor:
                          AppColors.warning.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
            ),

            if (!isOpen24h) ...[
              const SizedBox(height: 16),
              _label('Режим работы'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppColors.cardShadow,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: List.generate(7, (i) {
                    String fmt(TimeOfDay t) =>
                        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                    return _ScheduleRow(
                      label: dayLabels[i],
                      enabled: dayEnabled[i],
                      startLabel: fmt(startTimes[i]),
                      endLabel: fmt(endTimes[i]),
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

            const SizedBox(height: 24),

            // Фото филиала
            _label('Фото (необязательно)'),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: notifier.pickBranchPhoto,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.backgroundCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: AppColors.cardShadow,
                ),
                child: state.photoLocalPath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(state.photoLocalPath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(PhosphorIconsRegular.cameraPlus,
                              color: AppColors.warning, size: 32),
                          const SizedBox(height: 8),
                          Text('Добавить фото аптеки',
                              style: AppTextStyles.labelBold
                                  .copyWith(color: AppColors.warning)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.checkCircle,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'После регистрации аптека сразу станет видна пользователям.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Schedule row ──────────────────────────────────────────────────────────

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
            style: AppTextStyles.labelBold
                .copyWith(color: AppColors.warning)),
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
          color: AppColors.warning.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.warning, size: 22),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.headingMedium),
            Text(subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
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
