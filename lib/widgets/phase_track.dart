import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum PhaseState { pending, active, done }

class PhaseTrack extends StatelessWidget {
  const PhaseTrack({super.key, required this.phases});

  /// خريطة بالترتيب: 'ping' -> الحالة، 'download' -> الحالة، 'upload' -> الحالة
  final Map<String, PhaseState> phases;

  static const _labels = {
    'ping': 'فحص Ping',
    'download': 'فحص التنزيل',
    'upload': 'فحص الرفع',
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: phases.entries.map((entry) {
        final state = entry.value;
        final label = _labels[entry.key] ?? entry.key;

        Color textColor;
        Color dotColor;
        Color borderColor;
        Color bgColor;

        switch (state) {
          case PhaseState.active:
            textColor = AppColors.text1;
            dotColor = AppColors.cyan;
            borderColor = AppColors.cyan.withOpacity(0.35);
            bgColor = AppColors.cyan.withOpacity(0.09);
            break;
          case PhaseState.done:
            textColor = AppColors.success;
            dotColor = AppColors.success;
            borderColor = AppColors.success.withOpacity(0.3);
            bgColor = AppColors.success.withOpacity(0.07);
            break;
          case PhaseState.pending:
            textColor = AppColors.text3;
            dotColor = AppColors.text3;
            borderColor = AppColors.border;
            bgColor = AppColors.surface;
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: textColor, fontSize: 13)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
