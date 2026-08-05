import 'package:flutter/material.dart';

/// نفس لوحة الألوان المستخدمة في نسخة الويب (نبض)، للحفاظ على هوية
/// بصرية موحدة بين المنصتين.
class AppColors {
  AppColors._();

  static const void_ = Color(0xFF0A0D16);
  static const surface = Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  static const border = Color(0x17FFFFFF); // rgba(255,255,255,0.09)

  static const cyan = Color(0xFF22D3EE);
  static const violet = Color(0xFF8B5CF6);
  static const success = Color(0xFF34D399);
  static const warning = Color(0xFFFBBF24);

  static const text1 = Color(0xFFEEF1F8);
  static const text2 = Color(0xFFA6ADC0);
  static const text3 = Color(0xFF6B7386);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [cyan, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.void_,
    fontFamily: 'Tajawal',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.cyan,
      brightness: Brightness.dark,
      surface: AppColors.void_,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: AppColors.text1),
    ),
  );
}
