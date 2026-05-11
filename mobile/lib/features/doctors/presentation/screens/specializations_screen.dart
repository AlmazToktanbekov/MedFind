import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';

// emoji + accent color + light background for each specialization
const _specData = <String, (String, Color, Color)>{
  'Терапевт': ('🩺', Color(0xFF1565C0), Color(0xFFE3F0FF)),
  'Кардиолог': ('❤️', Color(0xFFE53935), Color(0xFFFFEBEE)),
  'Акушер-гинеколог': ('🤰', Color(0xFF8E24AA), Color(0xFFF3E5F5)),
  'Гастроэнтеролог': ('🫁', Color(0xFF00897B), Color(0xFFE0F2F1)),
  'Оториноларинголог': ('👂', Color(0xFFFF8C42), Color(0xFFFFF3E0)),
  'Эндокринолог': ('🧬', Color(0xFF5E35B1), Color(0xFFEDE7F6)),
  'Уролог': ('💧', Color(0xFF039BE5), Color(0xFFE1F5FE)),
  'Диетолог': ('🥗', Color(0xFF43A047), Color(0xFFE8F5E9)),
  'Дерматолог': ('🌿', Color(0xFF6D4C41), Color(0xFFEFEBE9)),
  'Андролог': ('⚕️', Color(0xFF1E88E5), Color(0xFFE3F2FD)),
  'Ортопед': ('🦴', Color(0xFF546E7A), Color(0xFFECEFF1)),
  'Пульмонолог': ('🫀', Color(0xFF00ACC1), Color(0xFFE0F7FA)),
  'Травматолог': ('🩹', Color(0xFFFF7043), Color(0xFFFBE9E7)),
  'Невролог': ('🧠', Color(0xFF7B1FA2), Color(0xFFF3E5F5)),
  'Маммолог': ('🔬', Color(0xFFEC407A), Color(0xFFFCE4EC)),
  'Онколог': ('⚗️', Color(0xFF1565C0), Color(0xFFE3F0FF)),
  'Психотерапевт': ('🧘', Color(0xFF00897B), Color(0xFFE0F2F1)),
  'Педиатр': ('👶', Color(0xFFFFB300), Color(0xFFFFF8E1)),
  'Косметолог': ('💆', Color(0xFFD81B60), Color(0xFFFCE4EC)),
  'Офтальмолог': ('👁️', Color(0xFF1E88E5), Color(0xFFE3F2FD)),
  'Стоматолог': ('🦷', Color(0xFF26A69A), Color(0xFFE0F2F1)),
  'Хирург': ('🔪', Color(0xFF455A64), Color(0xFFECEFF1)),
  'Нефролог': ('🫘', Color(0xFF8D6E63), Color(0xFFEFEBE9)),
  'Семейный врач': ('👨‍👩‍👧', Color(0xFF43A047), Color(0xFFE8F5E9)),
  'Нутрициолог': ('🍎', Color(0xFF7CB342), Color(0xFFF1F8E9)),
  'Хэлс-коуч': ('💪', Color(0xFFFF8C42), Color(0xFFFFF3E0)),
  'Медсестра': ('💉', Color(0xFF1565C0), Color(0xFFE3F0FF)),
  'Венеролог': ('🔬', Color(0xFF8E24AA), Color(0xFFF3E5F5)),
  'Проктолог': ('🩻', Color(0xFF546E7A), Color(0xFFECEFF1)),
  'Анестезиолог-реаниматолог': ('😴', Color(0xFF455A64), Color(0xFFECEFF1)),
  'Кардиохирург': ('❤️‍🩹', Color(0xFFE53935), Color(0xFFFFEBEE)),
  'Неонатолог': ('🍼', Color(0xFFFFB300), Color(0xFFFFF8E1)),
  'Рентгенолог': ('🩻', Color(0xFF546E7A), Color(0xFFECEFF1)),
  'Радиолог': ('☢️', Color(0xFF1565C0), Color(0xFFE3F0FF)),
  'Врач функциональной диагностики': ('📋', Color(0xFF039BE5), Color(0xFFE1F5FE)),
};

class SpecializationsScreen extends StatefulWidget {
  const SpecializationsScreen({super.key});

  @override
  State<SpecializationsScreen> createState() => _SpecializationsScreenState();
}

class _SpecializationsScreenState extends State<SpecializationsScreen> {
  String _query = '';

  List<String> get _filtered {
    if (_query.isEmpty) return AppConstants.specializations;
    final q = _query.toLowerCase();
    return AppConstants.specializations
        .where((s) => s.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
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
          'Специализации',
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
                  hintText: 'Поиск специализации...',
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
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) => _SpecCard(name: items[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  final String name;
  const _SpecCard({required this.name});

  @override
  Widget build(BuildContext context) {
    final data = _specData[name];
    final emoji = data?.$1 ?? '🩺';
    final accent = data?.$2 ?? AppColors.primaryBlue;
    final bg = data?.$3 ?? const Color(0xFFE3F0FF);

    return GestureDetector(
      onTap: () => context.push(
        '/main/doctors/by-specialization',
        extra: name,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelBold.copyWith(color: accent),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
