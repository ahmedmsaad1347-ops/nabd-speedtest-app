import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../models/ping_stats.dart';
import 'speed_calculator.dart';
import 'speed_test_exception.dart';

/// طبقة الاتصال الوحيدة بالـ Backend. كل الشاشات تتعامل مع هذا الكلاس
/// فقط، ولا تستدعي Dio مباشرة أبدًا — هذا يسهّل تبديل مكتبة الشبكة
/// لاحقًا دون لمس واجهة المستخدم.
class ApiService {
  ApiService() : _dio = Dio(BaseOptions(baseUrl: ApiConfig.apiBaseUrl));

  final Dio _dio;

  /// ===================== Ping + Jitter =====================

  Future<double> _singlePing(CancelToken cancelToken) async {
    final sw = Stopwatch()..start();
    try {
      await _dio.get(
        '/api/ping',
        queryParameters: {'_': DateTime.now().millisecondsSinceEpoch},
        options: Options(
          sendTimeout: ApiConfig.pingTimeout,
          receiveTimeout: ApiConfig.pingTimeout,
        ),
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _mapDioError(e, 'ping');
    }
    sw.stop();
    return sw.elapsedMicroseconds / 1000; // مللي ثانية بدقة أعلى من الميلي الصحيح
  }

  /// ينفذ عدة محاولات Ping متتالية، يستدعي [onSample] بعد كل محاولة
  /// ناجحة بالمتوسط والـ Jitter اللحظيين (لتحديث الواجهة أثناء
  /// التنفيذ)، ثم يعيد النتيجة النهائية بعد استبعاد القيم الشاذة.
  Future<PingStats> runPingTest({
    required void Function(double runningAvgMs, double runningJitterMs) onSample,
    required CancelToken cancelToken,
  }) async {
    final samples = <double>[];

    for (var i = 0; i < ApiConfig.pingAttempts; i++) {
      try {
        final ms = await _singlePing(cancelToken);
        samples.add(ms);
        onSample(
          SpeedCalculator.average(samples),
          SpeedCalculator.computeJitter(samples),
        );
      } catch (_) {
        // نتجاهل عينة فاشلة واحدة ونكمل، طالما لم تفشل أغلب المحاولات
      }
      await Future.delayed(const Duration(milliseconds: 110));
    }

    if (samples.length < (ApiConfig.pingAttempts / 2).ceil()) {
      throw const SpeedTestException(
        'ping',
        'تعذر قياس Ping — الشبكة غير مستقرة أو الخادم لا يستجيب.',
      );
    }

    final filtered = SpeedCalculator.rejectOutliers(samples);
    return PingStats(
      avgMs: SpeedCalculator.average(filtered),
      jitterMs: SpeedCalculator.computeJitter(filtered),
    );
  }

  /// ===================== Download =====================

  Future<_DownloadResult> _singleDownload(
    int sizeMb,
    void Function(double instMbps) onProgress,
    CancelToken cancelToken,
  ) async {
    final samples = <double>[];
    final sw = Stopwatch()..start();
    var received = 0;
    var lastReceived = 0;
    var lastMs = 0;

    try {
      final response = await _dio.get<ResponseBody>(
        '/api/download-test',
        queryParameters: {
          'size': sizeMb,
          '_': DateTime.now().millisecondsSinceEpoch,
        },
        options: Options(
          responseType: ResponseType.stream,
          receiveTimeout: ApiConfig.downloadTimeout,
        ),
        cancelToken: cancelToken,
      );

      // نقرأ الدفق تدريجيًا ونعدّ حجم كل جزء فقط دون تخزين البايتات
      // في الذاكرة، تمامًا كما تفعل نسخة الويب عبر reader.read().
      await for (final chunk in response.data!.stream) {
        received += chunk.length;
        final nowMs = sw.elapsedMilliseconds;
        if (nowMs - lastMs > 150) {
          final instMbps = SpeedCalculator.bytesToMbps(
            received - lastReceived,
            (nowMs - lastMs).toDouble(),
          );
          samples.add(instMbps);
          onProgress(instMbps);
          lastMs = nowMs;
          lastReceived = received;
        }
      }
    } on DioException catch (e) {
      throw _mapDioError(e, 'download');
    }

    // السرعة الإجمالية للملف كاملاً — تُحسب دائمًا، حتى على الاتصالات
    // السريعة جدًا التي ينتهي فيها التنزيل قبل تسجيل أي عينة لحظية.
    final overallMbps = SpeedCalculator.bytesToMbps(
      received,
      sw.elapsedMilliseconds.toDouble(),
    );
    if (overallMbps > 0) onProgress(overallMbps);

    return _DownloadResult(samples, overallMbps);
  }

  /// يحمّل عدة ملفات اختبار بأحجام مختلفة (راجع [ApiConfig.downloadSizesMb])،
  /// ويستدعي [onProgress] لحظيًا بالسرعة الآنية لتحريك العداد، ثم يعيد
  /// المتوسط النهائي بعد استبعاد القيم الشاذة وتجاهل فترة إحماء الاتصال.
  Future<double> runDownloadTest({
    required void Function(double instMbps) onProgress,
    required CancelToken cancelToken,
  }) async {
    final instAll = <double>[];
    final overallAll = <double>[];

    for (final size in ApiConfig.downloadSizesMb) {
      try {
        final result = await _singleDownload(size, onProgress, cancelToken);
        // نتجاهل أول عينة (إحماء الاتصال) فقط عند توفر عينات كافية
        if (result.samples.length > 2) {
          instAll.addAll(result.samples.sublist(1));
        }
        if (result.overallMbps > 0) overallAll.add(result.overallMbps);
      } catch (_) {
        // نسمح بفشل ملف واحد طالما نجح واحد آخر على الأقل
      }
    }

    if (overallAll.isEmpty) {
      throw const SpeedTestException(
        'download',
        'تعذر إتمام اختبار التنزيل. تحقق من الاتصال بالخادم.',
      );
    }

    // نفضّل متوسط العينات اللحظية عند توفرها بعدد كافٍ، ونرجع للسرعة
    // الإجمالية عندما يكون التنزيل أسرع من أن تُسجَّل له عينات.
    return instAll.length >= 4
        ? SpeedCalculator.average(SpeedCalculator.rejectOutliers(instAll))
        : SpeedCalculator.average(overallAll);
  }

  /// ===================== Upload =====================

  Future<double> _singleUpload(
    int sizeMb,
    void Function(double instMbps) onProgress,
    CancelToken cancelToken,
  ) async {
    final bytes = _generateRandomBytes(sizeMb * 1024 * 1024);
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: 'upload-test-${sizeMb}MB.bin'),
    });

    final sw = Stopwatch()..start();
    var lastSent = 0;
    var lastMs = 0;

    try {
      final response = await _dio.post(
        '/api/upload-test',
        data: formData,
        options: Options(
          sendTimeout: ApiConfig.uploadTimeout,
          receiveTimeout: ApiConfig.uploadTimeout,
        ),
        cancelToken: cancelToken,
        onSendProgress: (sent, total) {
          final nowMs = sw.elapsedMilliseconds;
          if (nowMs - lastMs > 150) {
            final instMbps = SpeedCalculator.bytesToMbps(
              sent - lastSent,
              (nowMs - lastMs).toDouble(),
            );
            onProgress(instMbps);
            lastMs = nowMs;
            lastSent = sent;
          }
        },
      );

      final data = response.data as Map<String, dynamic>;
      final inner = data['data'] as Map<String, dynamic>;
      return (inner['uploadSpeedMbps'] as num).toDouble();
    } on DioException catch (e) {
      throw _mapDioError(e, 'upload');
    }
  }

  /// يرفع عدة ملفات اختبار مولّدة محليًا (راجع [ApiConfig.uploadSizesMb])
  /// ويعتمد على السرعة المحسوبة من الخادم نفسه (أدق من حساب العميل)،
  /// ثم يعيد المتوسط النهائي بعد استبعاد القيم الشاذة.
  Future<double> runUploadTest({
    required void Function(double instMbps) onProgress,
    required CancelToken cancelToken,
  }) async {
    final results = <double>[];

    for (final size in ApiConfig.uploadSizesMb) {
      try {
        final mbps = await _singleUpload(size, onProgress, cancelToken);
        results.add(mbps);
      } catch (_) {
        // نسمح بفشل محاولة رفع واحدة طالما نجحت أخرى
      }
    }

    if (results.isEmpty) {
      throw const SpeedTestException(
        'upload',
        'تعذر إتمام اختبار الرفع. تحقق من الاتصال بالخادم.',
      );
    }

    final filtered = SpeedCalculator.rejectOutliers(results);
    return SpeedCalculator.average(filtered);
  }

  /// ===================== IP / ISP =====================

  Future<Map<String, dynamic>> fetchIpInfo(CancelToken cancelToken) async {
    try {
      final response = await _dio.get(
        '/api/ip-info',
        options: Options(receiveTimeout: ApiConfig.metaTimeout),
        cancelToken: cancelToken,
      );
      return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    } on DioException {
      return {'ip': '—', 'isp': null};
    }
  }

  /// ===================== Helpers =====================

  Uint8List _generateRandomBytes(int size) {
    final random = Random();
    final bytes = Uint8List(size);
    for (var i = 0; i < size; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  SpeedTestException _mapDioError(DioException e, String phase) {
    if (e.type == DioExceptionType.cancel) {
      return const SpeedTestException('network', 'تم إلغاء الاختبار.');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const SpeedTestException(
        'timeout',
        'انتهت مهلة الانتظار — الخادم بطيء جدًا أو لا يستجيب.',
      );
    }
    if (e.type == DioExceptionType.connectionError) {
      return const SpeedTestException(
        'network',
        'تعذر الاتصال بالخادم. تحقق من اتصالك بالإنترنت.',
      );
    }
    return SpeedTestException(phase, 'حدث خطأ غير متوقع أثناء الاتصال بالخادم.');
  }
}

/// نتيجة تنزيل ملف اختبار واحد: العينات اللحظية (لتحريك العداد وحساب
/// متوسط أدق) + السرعة الإجمالية للملف (قيمة احتياطية موثوقة دائمًا).
class _DownloadResult {
  final List<double> samples;
  final double overallMbps;

  const _DownloadResult(this.samples, this.overallMbps);
}
