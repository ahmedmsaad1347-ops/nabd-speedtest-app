import 'package:flutter/material.dart';

import '../models/test_results.dart';
import '../theme/app_theme.dart';
import '../widgets/result_card.dart';
import 'test_screen.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.results});

  final TestResults results;

  String _fmt(double n) => n >= 100 ? n.round().toString() : n.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final maxScale = [results.downloadMbps, results.uploadMbps]
            .reduce((a, b) => a > b ? a : b) *
        1.15;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'نتيجة الاختبار',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.text1, fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 22),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  ResultCard(
                    icon: Icons.arrow_downward_rounded,
                    label: 'التنزيل',
                    value: _fmt(results.downloadMbps),
                    unit: 'Mbps',
                    accentColor: AppColors.cyan,
                  ),
                  ResultCard(
                    icon: Icons.arrow_upward_rounded,
                    label: 'الرفع',
                    value: _fmt(results.uploadMbps),
                    unit: 'Mbps',
                    accentColor: AppColors.violet,
                  ),
                  ResultCard(
                    icon: Icons.speed_rounded,
                    label: 'Ping',
                    value: results.pingMs.round().toString(),
                    unit: 'ms',
                    accentColor: AppColors.success,
                  ),
                  ResultCard(
                    icon: Icons.show_chart_rounded,
                    label: 'Jitter',
                    value: results.jitterMs.round().toString(),
                    unit: 'ms',
                    accentColor: AppColors.warning,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // بطاقة مقارنة السرعات (رسم بياني بسيط بأعمدة متحركة)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('مقارنة السرعات', style: TextStyle(color: AppColors.text2, fontSize: 13)),
                        Text('Mbps', style: TextStyle(color: AppColors.text3, fontFamily: 'monospace')),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SpeedBar(
                          label: 'تنزيل',
                          value: results.downloadMbps,
                          maxValue: maxScale,
                          color: AppColors.cyan,
                        ),
                        const SizedBox(width: 32),
                        _SpeedBar(
                          label: 'رفع',
                          value: results.uploadMbps,
                          maxValue: maxScale,
                          color: AppColors.violet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // بطاقة معلومات الاتصال
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'عنوان IP', value: results.connectionInfo.ip),
                    const Divider(color: AppColors.border, height: 24),
                    _InfoRow(label: 'مزود الخدمة (ISP)', value: results.connectionInfo.isp ?? 'غير متاح'),
                    const Divider(color: AppColors.border, height: 24),
                    _InfoRow(label: 'نوع الاتصال', value: results.connectionInfo.connectionType),
                    const Divider(color: AppColors.border, height: 24),
                    _InfoRow(label: 'الجهاز', value: results.connectionInfo.device),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const TestScreen()),
                  );
                },
                icon: const Icon(Icons.refresh_rounded, color: AppColors.text1),
                label: const Text('إعادة الاختبار', style: TextStyle(color: AppColors.text1)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeedBar extends StatelessWidget {
  const _SpeedBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
  });

  final String label;
  final double value;
  final double maxValue;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final heightFraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.02, 1.0);

    return Column(
      children: [
        Container(
          width: 40,
          height: 120,
          alignment: Alignment.bottomCenter,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: heightFraction),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, fraction, _) => FractionallySizedBox(
              heightFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [color, color.withOpacity(0.25)],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value >= 100 ? value.round().toString() : value.toStringAsFixed(1),
          style: const TextStyle(color: AppColors.text1, fontWeight: FontWeight.w600),
        ),
        Text(label, style: const TextStyle(color: AppColors.text3, fontSize: 12)),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.text3, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(color: AppColors.text1, fontSize: 13, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}
