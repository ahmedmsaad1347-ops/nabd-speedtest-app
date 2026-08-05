import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// معلومات محلية بحتة عن الجهاز والشبكة، لا تحتاج أي اتصال بالخادم.
class DeviceService {
  final Connectivity _connectivity = Connectivity();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// يعيد نوع الاتصال الحالي بصياغة عربية مناسبة للعرض.
  Future<String> getConnectionType() async {
    final results = await _connectivity.checkConnectivity();
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;

    switch (result) {
      case ConnectivityResult.wifi:
        return 'واي فاي (Wi-Fi)';
      case ConnectivityResult.mobile:
        return 'بيانات الجوال';
      case ConnectivityResult.ethernet:
        return 'إيثرنت';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.none:
        return 'غير متصل';
      default:
        return 'غير معروف';
    }
  }

  /// يعيد وصف مختصر للجهاز (الموديل + إصدار النظام).
  Future<String> getDeviceDescription() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceInfo.androidInfo;
        return '${info.manufacturer} ${info.model} — Android ${info.version.release}';
      } else if (Platform.isIOS) {
        final info = await _deviceInfo.iosInfo;
        return '${info.name} — iOS ${info.systemVersion}';
      }
    } catch (_) {
      // نتجاهل أي فشل في قراءة معلومات الجهاز ونعيد قيمة افتراضية بأمان
    }
    return 'جهاز غير معروف';
  }

  /// يستخدم لمراقبة انقطاع/عودة الاتصال أثناء الاختبار.
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;
}
