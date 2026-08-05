import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'test_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/icon/logo.png',
                      width: 34,
                      height: 34,
                      filterQuality: FilterQuality.medium,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'نبض',
                      style: TextStyle(
                        color: AppColors.text1,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'اختبار سرعة الإنترنت',
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontSize: 12,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'اعرف نبض\nاتصالك الآن',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text1,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'قياس فعلي لسرعة التنزيل والرفع، ووقت الاستجابة، مباشرة من '
                  'الخادم الخاص بك — بلا تسجيل وبلا تعقيد.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.text2, fontSize: 15, height: 1.7),
                ),
                const SizedBox(height: 44),
                _StartButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TestScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            gradient: LinearGradient(
              colors: [
                AppColors.cyan.withOpacity(0.18),
                AppColors.violet.withOpacity(0.18),
              ],
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_arrow_rounded, color: AppColors.text1),
              SizedBox(width: 8),
              Text(
                'ابدأ اختبار السرعة',
                style: TextStyle(
                  color: AppColors.text1,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
