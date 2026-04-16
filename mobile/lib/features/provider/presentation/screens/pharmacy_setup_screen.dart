import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../providers/pharmacy_setup_provider.dart';

class PharmacySetupScreen extends ConsumerStatefulWidget {
  const PharmacySetupScreen({super.key});

  @override
  ConsumerState<PharmacySetupScreen> createState() =>
      _PharmacySetupScreenState();
}

class _PharmacySetupScreenState extends ConsumerState<PharmacySetupScreen> {
  // Шаг 1
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _step1Key = GlobalKey<FormState>();

  // Шаг 2
  final _phoneCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  bool _isOpen24h = false;
  final _step2Key = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final notifier = ref.read(pharmacySetupProvider.notifier);
    final step = ref.read(pharmacySetupProvider).currentStep;

    if (step == 0) {
      if (!_step1Key.currentState!.validate()) return;
      notifier.updateStep1(
        nameRu: _nameCtrl.text.trim(),
        addressRu: _addressCtrl.text.trim(),
      );
      notifier.nextStep();
    } else if (step == 1) {
      if (!_step2Key.currentState!.validate()) return;
      notifier.updateStep2(
        phone: _phoneCtrl.text.trim(),
        workingHoursRu: _isOpen24h ? 'Круглосуточно' : _hoursCtrl.text.trim(),
        isOpen24h: _isOpen24h,
      );
      notifier.nextStep();
    } else if (step == 2) {
      final ok = await notifier.submit();
      if (ok && mounted) {
        context.go('/provider/pending-pharmacy');
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
              nameCtrl: _nameCtrl,
              addressCtrl: _addressCtrl,
            ),
          1 => _Step2(
              key: const ValueKey(1),
              formKey: _step2Key,
              phoneCtrl: _phoneCtrl,
              hoursCtrl: _hoursCtrl,
              isOpen24h: _isOpen24h,
              onToggle24h: (v) => setState(() {
                _isOpen24h = v;
                if (v) _hoursCtrl.text = 'Круглосуточно';
              }),
            ),
          _ => _Step3(key: const ValueKey(2)),
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
              text: state.currentStep < 2 ? 'Далее' : 'Отправить на проверку',
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

// ─── Step 1 ────────────────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController addressCtrl;

  const _Step1({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.addressCtrl,
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
              icon: PhosphorIconsFill.pill,
              iconColor: AppColors.warning,
              title: 'Информация об аптеке',
              subtitle: 'Основные данные вашей аптеки',
            ),
            const SizedBox(height: 32),
            _label('Название аптеки *'),
            const SizedBox(height: 8),
            _field(
              controller: nameCtrl,
              hint: 'Например: Аптека Ден-Сат',
              icon: PhosphorIconsRegular.pill,
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Введите название'
                  : null,
            ),
            const SizedBox(height: 20),
            _label('Адрес *'),
            const SizedBox(height: 8),
            _field(
              controller: addressCtrl,
              hint: 'г. Бишкек, ул. Токтогула, 98',
              icon: PhosphorIconsRegular.mapPin,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Введите адрес' : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2 ────────────────────────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneCtrl;
  final TextEditingController hoursCtrl;
  final bool isOpen24h;
  final ValueChanged<bool> onToggle24h;

  const _Step2({
    super.key,
    required this.formKey,
    required this.phoneCtrl,
    required this.hoursCtrl,
    required this.isOpen24h,
    required this.onToggle24h,
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
              icon: PhosphorIconsFill.clock,
              iconColor: AppColors.warning,
              title: 'Контакты и режим',
              subtitle: 'Телефон и часы работы',
            ),
            const SizedBox(height: 32),
            _label('Телефон'),
            const SizedBox(height: 8),
            _field(
              controller: phoneCtrl,
              hint: '+996 312 000 000',
              icon: PhosphorIconsRegular.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            // Переключатель "Круглосуточно"
            Container(
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
                        Text('Работаем круглосуточно',
                            style: AppTextStyles.labelBold),
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
                    activeTrackColor: AppColors.warning.withValues(alpha: 0.4),
                  ),
                ],
              ),
            ),

            if (!isOpen24h) ...[
              const SizedBox(height: 20),
              _label('Режим работы'),
              const SizedBox(height: 8),
              _field(
                controller: hoursCtrl,
                hint: 'Пн-Пт 08:00-22:00, Сб-Вс 09:00-21:00',
                icon: PhosphorIconsRegular.clock,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Step 3 ────────────────────────────────────────────────────────────────

class _Step3 extends ConsumerWidget {
  const _Step3({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pharmacySetupProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            icon: PhosphorIconsFill.image,
            iconColor: AppColors.warning,
            title: 'Фото аптеки',
            subtitle: 'Добавьте фотографию фасада или интерьера',
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () =>
                ref.read(pharmacySetupProvider.notifier).pickAndUploadPhoto(),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: AppColors.cardShadow,
              ),
              child: state.photoLocalPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        File(state.photoLocalPath!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(PhosphorIconsRegular.cameraPlus,
                              color: AppColors.warning, size: 28),
                        ),
                        const SizedBox(height: 12),
                        Text('Нажмите, чтобы выбрать фото',
                            style: AppTextStyles.labelBold
                                .copyWith(color: AppColors.warning)),
                        const SizedBox(height: 4),
                        Text('Фото фасада или интерьера',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.info,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'После отправки ваш профиль будет проверен администратором в течение 24 часов.',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.warning),
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

// ─── Shared helpers ────────────────────────────────────────────────────────

Widget _header({
  required IconData icon,
  required Color iconColor,
  required String title,
  required String subtitle,
}) {
  return Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: iconColor, size: 22),
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
  TextInputType keyboardType = TextInputType.text,
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
      keyboardType: keyboardType,
      style: AppTextStyles.bodyLarge,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Icon(icon, color: AppColors.warning, size: 20),
        ),
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
