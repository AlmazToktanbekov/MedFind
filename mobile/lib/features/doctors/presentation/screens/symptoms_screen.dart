import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/symptom_model.dart';
import '../../providers/doctors_provider.dart';

const _symptomEmojis = ['❤️', '🛡️', '🌸', '💑', '🦴', '💊', '🔙', '🩸',
  '😮‍💨', '💪', '🚽', '🤰', '🦠', '🧠', '🤧', '👁️'];

const _symptomAccents = [
  Color(0xFFE53935), Color(0xFF43A047), Color(0xFF8E24AA), Color(0xFFD81B60),
  Color(0xFF1565C0), Color(0xFFFF8C42), Color(0xFF00897B), Color(0xFFFFB300),
  Color(0xFF5E35B1), Color(0xFF039BE5), Color(0xFF6D4C41), Color(0xFF43A047),
  Color(0xFFE53935), Color(0xFF7B1FA2), Color(0xFF1565C0), Color(0xFF1E88E5),
];

const _symptomBgs = [
  Color(0xFFFFEBEE), Color(0xFFE8F5E9), Color(0xFFF3E5F5), Color(0xFFFCE4EC),
  Color(0xFFE3F0FF), Color(0xFFFFF3E0), Color(0xFFE0F2F1), Color(0xFFFFF8E1),
  Color(0xFFEDE7F6), Color(0xFFE1F5FE), Color(0xFFEFEBE9), Color(0xFFE8F5E9),
  Color(0xFFFFEBEE), Color(0xFFF3E5F5), Color(0xFFE3F0FF), Color(0xFFE3F2FD),
];

class SymptomsScreen extends ConsumerStatefulWidget {
  const SymptomsScreen({super.key});

  @override
  ConsumerState<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends ConsumerState<SymptomsScreen> {
  String _query = '';

  List<SymptomModel> _filtered(List<SymptomModel> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((s) => s.nameRu.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final symptomsAsync = ref.watch(symptomsProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundApp,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Симптомы',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(14),
                boxShadow: AppColors.cardShadow,
              ),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: AppTextStyles.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Поиск симптома...',
                  hintStyle: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: const Icon(
                    PhosphorIconsRegular.magnifyingGlass,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          Expanded(
            child: symptomsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Не удалось загрузить симптомы',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              data: (all) {
                final items = _filtered(all);
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      'Ничего не найдено',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.4,
                  ),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final symptom = items[i];
                    final idx = i % _symptomBgs.length;
                    return GestureDetector(
                      onTap: () => context.push(
                        '/main/doctors/by-symptom/${symptom.id}',
                        extra: symptom.nameRu,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _symptomBgs[idx],
                          borderRadius: BorderRadius.circular(18),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _symptomEmojis[idx],
                              style: const TextStyle(fontSize: 28),
                            ),
                            Text(
                              symptom.nameRu,
                              style: AppTextStyles.labelBold.copyWith(
                                fontSize: 13,
                                color: _symptomAccents[idx],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
