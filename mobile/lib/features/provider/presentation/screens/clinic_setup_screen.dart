import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String? _selectedCategory;
  final _step1Key = GlobalKey<FormState>();

  // Шаг 2
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  final _step2Key = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _websiteCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _onNext() async {
    final notifier = ref.read(clinicSetupProvider.notifier);
    final step = ref.read(clinicSetupProvider).currentStep;

    if (step == 0) {
      if (!_step1Key.currentState!.validate()) return;
      notifier.updateStep1(
        nameRu: _nameCtrl.text.trim(),
        descriptionRu: _descCtrl.text.trim(),
        categoryRu: _selectedCategory ?? '',
      );
      notifier.nextStep();
    } else if (step == 1) {
      if (!_step2Key.currentState!.validate()) return;
      notifier.updateStep2(
        addressRu: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        website: _websiteCtrl.text.trim(),
        workingHoursRu: _hoursCtrl.text.trim(),
      );
      notifier.nextStep();
    } else if (step == 2) {
      final ok = await notifier.submit();
      if (ok && mounted) {
        context.go('/provider/pending-clinic');
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
        leading: state.currentStep > 0
            ? IconButton(
                icon: const Icon(PhosphorIconsRegular.arrowLeft,
                    color: AppColors.textPrimary),
                onPressed: () =>
                    ref.read(clinicSetupProvider.notifier).prevStep(),
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
              descCtrl: _descCtrl,
              selectedCategory: _selectedCategory,
              onCategoryChanged: (v) => setState(() => _selectedCategory = v),
            ),
          1 => _Step2(
              key: const ValueKey(1),
              formKey: _step2Key,
              addressCtrl: _addressCtrl,
              phoneCtrl: _phoneCtrl,
              websiteCtrl: _websiteCtrl,
              hoursCtrl: _hoursCtrl,
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
                ? AppColors.primaryBlue
                : AppColors.backgroundChip,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─── Step 1: Основная информация ───────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final String? selectedCategory;
  final ValueChanged<String?> onCategoryChanged;

  const _Step1({
    super.key,
    required this.formKey,
    required this.nameCtrl,
    required this.descCtrl,
    required this.selectedCategory,
    required this.onCategoryChanged,
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
            const SizedBox(height: 32),
            _label('Название клиники *'),
            const SizedBox(height: 8),
            _field(
              controller: nameCtrl,
              hint: 'Например: МЦ Авиценна',
              icon: PhosphorIconsRegular.buildingOffice,
              validator: (v) => (v == null || v.trim().length < 2)
                  ? 'Введите название'
                  : null,
            ),
            const SizedBox(height: 20),
            _label('Описание'),
            const SizedBox(height: 8),
            _field(
              controller: descCtrl,
              hint: 'Кратко о специализации и услугах клиники',
              icon: PhosphorIconsRegular.textAlignLeft,
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            _label('Категория *'),
            const SizedBox(height: 8),
            _CategoryDropdown(
              value: selectedCategory,
              onChanged: onCategoryChanged,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2: Контакты и адрес ──────────────────────────────────────────────

class _Step2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController addressCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController websiteCtrl;
  final TextEditingController hoursCtrl;

  const _Step2({
    super.key,
    required this.formKey,
    required this.addressCtrl,
    required this.phoneCtrl,
    required this.websiteCtrl,
    required this.hoursCtrl,
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
              title: 'Контакты и адрес',
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
            _label('Телефон'),
            const SizedBox(height: 8),
            _field(
              controller: phoneCtrl,
              hint: '+996 312 000 000',
              icon: PhosphorIconsRegular.phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _label('Сайт'),
            const SizedBox(height: 8),
            _field(
              controller: websiteCtrl,
              hint: 'https://clinic.kg',
              icon: PhosphorIconsRegular.globe,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 20),
            _label('Режим работы'),
            const SizedBox(height: 8),
            _field(
              controller: hoursCtrl,
              hint: 'Пн-Пт 08:00-20:00, Сб 09:00-16:00',
              icon: PhosphorIconsRegular.clock,
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
    final state = ref.watch(clinicSetupProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(
            icon: PhosphorIconsFill.image,
            title: 'Фото клиники',
            subtitle: 'Добавьте фотографию для привлечения пациентов',
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () =>
                ref.read(clinicSetupProvider.notifier).pickAndUploadPhoto(),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  width: 1.5,
                  style: BorderStyle.solid,
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
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            PhosphorIconsRegular.cameraPlus,
                            color: AppColors.primaryBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Нажмите, чтобы выбрать фото',
                          style: AppTextStyles.labelBold
                              .copyWith(color: AppColors.primaryBlue),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG — рекомендуется 1200×800',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
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
                    'После отправки профиль будет проверен администратором. Обычно это занимает до 24 часов.',
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

// ─── Category dropdown ─────────────────────────────────────────────────────

class _CategoryDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const _CategoryDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        hint: Text(
          'Выберите категорию',
          style:
              AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        style: AppTextStyles.bodyLarge,
        decoration: const InputDecoration(border: InputBorder.none),
        icon: const Icon(PhosphorIconsRegular.caretDown,
            color: AppColors.primaryBlue, size: 18),
        validator: (v) => v == null ? 'Выберите категорию' : null,
        onChanged: onChanged,
        items: AppConstants.clinicCategories
            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
            .toList(),
      ),
    );
  }
}
