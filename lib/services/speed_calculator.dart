/// دوال إحصائية مساعدة، نفس منطق النسخة الموجودة في الواجهة الويب
/// (app.js) بالضبط، لضمان اتساق طريقة حساب النتائج بين المنصتين.
class SpeedCalculator {
  SpeedCalculator._();

  static double bytesToMbps(int bytes, double durationMs) {
    if (durationMs <= 0) return 0;
    final bits = bytes * 8;
    final seconds = durationMs / 1000;
    return (bits / seconds) / 1000000;
  }

  static double average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double computeJitter(List<double> samples) {
    if (samples.length < 2) return 0;
    double sum = 0;
    for (var i = 1; i < samples.length; i++) {
      sum += (samples[i] - samples[i - 1]).abs();
    }
    return sum / (samples.length - 1);
  }

  /// يستبعد القيم الشاذة بأسلوب IQR (المدى الربيعي). يحتاج 4 عينات
  /// على الأقل ليكون الحساب ذا معنى إحصائي، وإلا يعيد القائمة كما هي.
  static List<double> rejectOutliers(List<double> samples) {
    if (samples.length < 4) return samples;
    final sorted = [...samples]..sort();
    final q1 = _percentile(sorted, 0.25);
    final q3 = _percentile(sorted, 0.75);
    final iqr = q3 - q1;
    final lower = q1 - 1.5 * iqr;
    final upper = q3 + 1.5 * iqr;
    final filtered = sorted.where((v) => v >= lower && v <= upper).toList();
    return filtered.isNotEmpty ? filtered : samples;
  }

  static double _percentile(List<double> sortedValues, double p) {
    final idx = p * (sortedValues.length - 1);
    final lo = idx.floor();
    final hi = idx.ceil();
    if (lo == hi) return sortedValues[lo];
    return sortedValues[lo] + (sortedValues[hi] - sortedValues[lo]) * (idx - lo);
  }
}
