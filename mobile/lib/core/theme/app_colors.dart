import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Основные
  static const Color primaryBlue = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF0D47A1);
  static const Color accentBlue = Color(0xFF2979FF);

  // Фон
  static const Color backgroundApp = Color(0xFFF0F4FF);
  static const Color backgroundCard = Color(0xFFFFFFFF);
  static const Color backgroundChip = Color(0xFFEEF2FF);

  // Текст
  static const Color textPrimary = Color(0xFF0D1B3E);
  static const Color textSecondary = Color(0xFF6B7A99);

  // Статусы
  static const Color success = Color(0xFF00C897);
  static const Color warning = Color(0xFFFF8C42);
  static const Color error = Color(0xFFE53935);

  // Градиенты
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF42A5F5)],
  );

  static const LinearGradient btnGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF1565C0), Color(0xFF2979FF)],
  );

  // Тень карточек
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x1A1565C0),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];
}
