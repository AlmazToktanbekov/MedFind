import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class CustomSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final VoidCallback? onTap;
  final TextEditingController? controller;

  const CustomSearchBar({
    super.key,
    this.hint = 'Найти врача, симптом...',
    this.onChanged,
    this.onFilterTap,
    this.onTap,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              onTap: onTap,
              readOnly: onTap != null,
              style: AppTextStyles.bodyLarge,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: AppTextStyles.bodySmall,
                prefixIcon: Icon(
                  PhosphorIconsRegular.magnifyingGlass,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          ),
        ),
        if (onFilterTap != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onFilterTap,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.btnGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                PhosphorIconsRegular.slidersHorizontal,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
