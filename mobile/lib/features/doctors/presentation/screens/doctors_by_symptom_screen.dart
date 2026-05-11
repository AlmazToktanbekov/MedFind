import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/doctor_card.dart';
import '../../../doctors/providers/doctors_provider.dart';

class DoctorsBySymptomScreen extends ConsumerWidget {
  final int symptomId;
  final String symptomName;

  const DoctorsBySymptomScreen({
    super.key,
    required this.symptomId,
    required this.symptomName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctorsAsync = ref.watch(doctorsBySymptomProvider(symptomId));

    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundApp,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppColors.textPrimary,
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Врачи', style: AppTextStyles.headingMedium),
            Text(
              symptomName,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: doctorsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  size: 56, color: AppColors.textSecondary),
              const SizedBox(height: 12),
              Text('Не удалось загрузить врачей',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary)),
              TextButton(
                onPressed: () =>
                    ref.refresh(doctorsBySymptomProvider(symptomId)),
                child: Text('Повторить', style: AppTextStyles.labelBold),
              ),
            ],
          ),
        ),
        data: (doctors) {
          if (doctors.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(PhosphorIconsRegular.userCircle,
                      size: 56,
                      color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  Text('Врачи не найдены',
                      style: AppTextStyles.bodyLarge
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: doctors.length,
            itemBuilder: (_, index) => DoctorCard(
              doctor: doctors[index],
              onTap: () =>
                  context.push('/main/doctors/${doctors[index].id}'),
            ),
          );
        },
      ),
    );
  }
}
