/// نتيجة اختبار Ping بعد استبعاد القيم الشاذة وحساب المتوسط والـ Jitter.
class PingStats {
  final double avgMs;
  final double jitterMs;

  const PingStats({required this.avgMs, required this.jitterMs});
}
