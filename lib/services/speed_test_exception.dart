/// استثناء مخصص يحمل اسم المرحلة التي فشلت (ping/download/upload/network)
/// ورسالة عربية جاهزة للعرض مباشرة للمستخدم في الواجهة.
class SpeedTestException implements Exception {
  final String phase;
  final String message;

  const SpeedTestException(this.phase, this.message);

  @override
  String toString() => message;
}
