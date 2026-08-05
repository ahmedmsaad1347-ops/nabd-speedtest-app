/// معلومات الاتصال والجهاز المعروضة في شاشة النتائج.
class ConnectionInfo {
  final String ip;
  final String? isp;
  final String connectionType; // من connectivity_plus (Wi-Fi / بيانات جوال / لا يوجد اتصال)
  final String device; // موديل الجهاز + إصدار النظام (من device_info_plus)

  const ConnectionInfo({
    required this.ip,
    required this.isp,
    required this.connectionType,
    required this.device,
  });

  factory ConnectionInfo.unknown() => const ConnectionInfo(
        ip: '—',
        isp: null,
        connectionType: 'غير معروف',
        device: 'غير معروف',
      );
}
