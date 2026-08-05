/// إعدادات الاتصال بالـ Backend.
///
/// القيمة الافتراضية هنا تفترض أن السيرفر يعمل على **نفس الهاتف**
/// (عبر Termux على المنفذ 3000). التطبيق يستطيع الوصول إليه مباشرة
/// عبر 127.0.0.1 لأنه على نفس الجهاز.
///
/// حالات أخرى:
///   - محاكي Android على كمبيوتر: استخدم http://10.0.2.2:3000
///   - جهاز حقيقي وسيرفر على كمبيوتر بنفس الواي فاي: استخدم IP الكمبيوتر
///     (مثال: http://192.168.1.10:3000)
///   - بعد النشر على سيرفر حقيقي: https://api.example.com
///
/// يمكن تغييرها وقت البناء دون تعديل الكود:
///   flutter build apk --dart-define=API_BASE_URL=https://example.com
class ApiConfig {
  ApiConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  static const Duration pingTimeout = Duration(seconds: 5);
  static const Duration downloadTimeout = Duration(seconds: 20);
  static const Duration uploadTimeout = Duration(seconds: 25);
  static const Duration metaTimeout = Duration(seconds: 5);

  static const int pingAttempts = 6;
  static const List<int> downloadSizesMb = [5, 10];
  static const List<int> uploadSizesMb = [4, 8];
}
