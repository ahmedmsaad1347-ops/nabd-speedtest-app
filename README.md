# نبض — تطبيق Flutter لاختبار سرعة الإنترنت

تطبيق Android/iOS حقيقي بواجهته الخاصة، يتصل بنفس الـ Backend (Node.js + Express) اللي بنيناه سابقًا.

## هيكل المشروع

```
lib/
├── main.dart                    # نقطة الدخول
├── config/api_config.dart       # عنوان الخادم + المهلات الزمنية + أحجام الاختبار
├── models/                      # PingStats, ConnectionInfo, TestResults
├── services/
│   ├── api_service.dart         # كل الاتصال بالـ Backend (ping/download/upload/ip-info)
│   ├── device_service.dart      # نوع الاتصال + معلومات الجهاز (محليًا)
│   ├── speed_calculator.dart    # متوسط / Jitter / استبعاد القيم الشاذة (IQR)
│   └── speed_test_exception.dart
├── screens/
│   ├── home_screen.dart         # الشاشة الرئيسية + زر البدء
│   ├── test_screen.dart         # تنفيذ الاختبار الفعلي (تنسيق المراحل)
│   └── results_screen.dart      # عرض النتائج النهائية
├── widgets/                     # SpeedGauge, PhaseTrack, ResultCard, ErrorBanner
└── theme/app_theme.dart         # ألوان وخطوط موحّدة مع نسخة الويب
```

## 1. المتطلبات

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (قناة stable، 3.19 أو أحدث)
- محرر (VS Code أو Android Studio) مع إضافة Flutter/Dart
- محاكي Android أو iOS Simulator، أو جهاز حقيقي

تحقق من التثبيت:
```bash
flutter doctor
```

## 2. إنشاء مشروع Flutter ونسخ الكود

هذا التسليم عبارة عن ملفات `lib/` و`pubspec.yaml` فقط (بدون مجلدات `android/` و`ios/` التي يولّدها Flutter تلقائيًا حسب بيئتك). لذلك:

```bash
# 1. أنشئ مشروع Flutter فارغ بنفس الاسم
flutter create nabd_speedtest
cd nabd_speedtest

# 2. احذف lib/main.dart الافتراضي، وانسخ محتويات lib/ المرفقة مكانه
rm -rf lib
cp -r /path/to/delivered/lib .

# 3. استبدل pubspec.yaml بالنسخة المرفقة (أو أضف الحزم الموجودة فيه يدويًا)
cp /path/to/delivered/pubspec.yaml .

# 4. نزّل الحزم
flutter pub get
```

## 3. ضبط عنوان الـ Backend

افتح `lib/config/api_config.dart` وعدّل `apiBaseUrl` حسب بيئتك:

| البيئة | القيمة |
|---|---|
| محاكي Android (Emulator) | `http://10.0.2.2:3000` *(القيمة الافتراضية بالكود)* |
| محاكي iOS (Simulator) | `http://localhost:3000` |
| جهاز حقيقي على نفس شبكة الواي فاي | `http://<IP-الشبكة-المحلي-لجهازك>:3000` |
| بعد النشر على VPS | `https://api.example.com` |

بدلاً من تعديل الكود، يمكنك أيضًا تمريره وقت التشغيل بدون لمس الملف:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
```

⚠️ تذكّر ضبط `CORS_ORIGIN` في إعدادات الـ Backend (`.env`) إذا كنت ستستخدم الويب أيضًا؛ بالنسبة لتطبيق Flutter الأصلي (Android/iOS) فإن قيود CORS لا تنطبق أصلاً لأنها خاصة بالمتصفح فقط.

## 4. التشغيل

```bash
flutter run
```

اختر الجهاز/المحاكي عند الطلب. أول تشغيل قد يستغرق دقيقة أو دقيقتين.

## 5. بناء نسخة للتوزيع

### Android (APK)
```bash
flutter build apk --release
# الناتج: build/app/outputs/flutter-apk/app-release.apk
```

### Android (App Bundle لمتجر Google Play)
```bash
flutter build appbundle --release
```

### iOS (يتطلب جهاز Mac + Xcode)
```bash
flutter build ios --release
# ثم افتح ios/Runner.xcworkspace في Xcode للأرشفة والرفع إلى App Store Connect
```

## 6. صلاحيات الإنترنت

- **Android**: صلاحية الإنترنت مفعّلة تلقائيًا في مشروع Flutter الافتراضي (`<uses-permission android:name="android.permission.INTERNET"/>` موجودة في `android/app/src/main/AndroidManifest.xml` الذي يولّده `flutter create`). لا حاجة لأي إضافة يدوية.
- **iOS**: لا يحتاج صلاحية خاصة للاتصال بخادم HTTPS. إذا كان الـ Backend يعمل محليًا عبر HTTP فقط أثناء التطوير، أضف استثناء App Transport Security في `ios/Runner/Info.plist`:
  ```xml
  <key>NSAppTransportSecurity</key>
  <dict>
      <key>NSAllowsArbitraryLoads</key>
      <true/>
  </dict>
  ```
  احذف هذا الاستثناء قبل الإصدار النهائي واستخدم HTTPS دائمًا في الإنتاج.

## 7. ملاحظات معمارية مهمة

- **نفس منطق الحساب بالضبط** بين الويب وFlutter: استبعاد القيم الشاذة (IQR)، حساب المتوسط والـ Jitter، موجودة في `services/speed_calculator.dart` بنفس صيغة `app.js`.
- **الرفع/التنزيل** يعتمدان على `onSendProgress`/`onReceiveProgress` من مكتبة Dio لتحديث العداد لحظيًا، بدل التخزين الكامل للبيانات في الذاكرة دفعة واحدة.
- **معالجة الانقطاع**: `DeviceService.onConnectivityChanged` يراقب الشبكة باستمرار أثناء الاختبار، ويُلغي الطلب الجاري فورًا (`CancelToken`) ويعرض بانر الخطأ مع زر "إعادة المحاولة" عند انقطاع الاتصال.
- **تحسين الأداء على الهاتف**: نفس فكرة الويب — لا يتم تخزين بايتات الملف المُنزَّل في الذاكرة، فقط عدّه؛ وحجم بيانات الرفع يُبنى مرة واحدة فقط بحجم معقول (6–12MB).
