import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// عداد دائري متحرك لعرض السرعة اللحظية، يشبه بصريًا نسخة الويب
/// (قوس 270 درجة، تدرج لوني، علامات تجزئة).
class SpeedGauge extends StatelessWidget {
  const SpeedGauge({
    super.key,
    required this.value,
    required this.maxValue,
    required this.phaseLabel,
    this.size = 290,
  });

  final double value;
  final double maxValue;
  final String phaseLabel;
  final double size;

  @override
  Widget build(BuildContext context) {
    final percent = (value / maxValue).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
            builder: (context, animatedPercent, _) {
              return CustomPaint(
                size: Size(size, size),
                painter: _GaugePainter(
                  percent: animatedPercent,
                  maxValue: maxValue,
                ),
              );
            },
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value >= 100 ? value.round().toString() : value.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text1,
                ),
              ),
              const SizedBox(height: 2),
              const Text('Mbps', style: TextStyle(color: AppColors.text3, fontSize: 13)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  phaseLabel,
                  style: const TextStyle(color: AppColors.text2, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.percent, required this.maxValue});

  final double percent;
  final double maxValue;

  static const double _startAngle = 135 * pi / 180;
  static const double _sweepAngle = 270 * pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 26;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, trackPaint);

    _drawTicks(canvas, center, radius);

    if (percent > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          colors: const [AppColors.cyan, AppColors.violet],
          startAngle: _startAngle,
          endAngle: _startAngle + _sweepAngle,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, _startAngle, _sweepAngle * percent, false, progressPaint);
    }
  }

  void _drawTicks(Canvas canvas, Offset center, double radius) {
    const totalTicks = 25; // علامة كبيرة مع رقم كل 5 تدريجات => 0..500
    for (var i = 0; i <= totalTicks; i++) {
      final angle = _startAngle + _sweepAngle * (i / totalTicks);
      final cosA = cos(angle), sinA = sin(angle);
      final major = i % 5 == 0;

      final r1 = radius - (major ? 20 : 14);
      final r2 = radius - 6.0;

      final p1 = Offset(center.dx + r1 * cosA, center.dy + r1 * sinA);
      final p2 = Offset(center.dx + r2 * cosA, center.dy + r2 * sinA);

      final tickPaint = Paint()
        ..color = major
            ? Colors.white.withOpacity(0.32)
            : Colors.white.withOpacity(0.14)
        ..strokeWidth = 2;
      canvas.drawLine(p1, p2, tickPaint);

      if (major) {
        final value = ((i / totalTicks) * maxValue).round();
        final tp = TextPainter(
          text: TextSpan(
            text: '$value',
            style: const TextStyle(color: AppColors.text3, fontSize: 11),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelRadius = radius + 17;
        final lx = center.dx + labelRadius * cosA - tp.width / 2;
        final ly = center.dy + labelRadius * sinA - tp.height / 2;
        tp.paint(canvas, Offset(lx, ly));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.maxValue != maxValue;
}
