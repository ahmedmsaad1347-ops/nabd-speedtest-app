import 'connection_info.dart';

/// النتيجة النهائية الكاملة لاختبار السرعة، جاهزة لعرضها في شاشة النتائج.
class TestResults {
  final double pingMs;
  final double jitterMs;
  final double downloadMbps;
  final double uploadMbps;
  final ConnectionInfo connectionInfo;

  const TestResults({
    required this.pingMs,
    required this.jitterMs,
    required this.downloadMbps,
    required this.uploadMbps,
    required this.connectionInfo,
  });
}
