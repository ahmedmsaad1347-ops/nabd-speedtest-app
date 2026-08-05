import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const NabdApp());
}

class NabdApp extends StatelessWidget {
  const NabdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'نبض — اختبار سرعة الإنترنت',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // الواجهة عربية بالكامل، لذلك نفرض اتجاه RTL على مستوى التطبيق
      locale: const Locale('ar'),
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),
      home: const HomeScreen(),
    );
  }
}
