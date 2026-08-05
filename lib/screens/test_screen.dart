import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../config/api_config.dart';
import '../models/connection_info.dart';
import '../models/test_results.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';
import '../services/speed_test_exception.dart';
import '../theme/app_theme.dart';
import '../widgets/error_banner.dart';
import '../widgets/phase_track.dart';
import '../widgets/speed_gauge.dart';
import 'results_screen.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  static const double _gaugeMaxMbps = 1000;

  final ApiService _apiService = ApiService();
  final DeviceService _deviceService = DeviceService();

  CancelToken? _cancelToken;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  double _gaugeValue = 0;
  String _gaugePhaseLabel = 'تهيئة…';
  double _progress = 0;
  double? _livePing;
  double? _liveJitter;
  String? _errorMessage;
  bool _isRunning = false;
  TestResults? _results;

  Map<String, PhaseState> _phases = {
    'ping': PhaseState.pending,
    'download': PhaseState.pending,
    'upload': PhaseState.pending,
  };

  @override
  void initState() {
    super.initState();
    _connectivitySub = _deviceService.onConnectivityChanged.listen(_onConnectivityChanged);
    _runTest();
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _cancelToken?.cancel();
    super.dispose();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final offline = results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    if (offline && _isRunning) {
      _cancelToken?.cancel('offline');
      setState(() {
        _errorMessage = 'انقطع الاتصال بالإنترنت أثناء الاختبار.';
        _gaugePhaseLabel = 'توقف الاختبار';
      });
    }
  }

  Future<void> _runTest() async {
    setState(() {
      _errorMessage = null;
      _gaugeValue = 0;
      _gaugePhaseLabel = 'تهيئة…';
      _progress = 0;
      _livePing = null;
      _liveJitter = null;
      _results = null;
      _phases = {
        'ping': PhaseState.pending,
        'download': PhaseState.pending,
        'upload': PhaseState.pending,
      };
    });

    _cancelToken = CancelToken();
    _isRunning = true;

    try {
      var pingSampleCount = 0;

      setState(() => _phases = {..._phases, 'ping': PhaseState.active});
      final pingStats = await _apiService.runPingTest(
        cancelToken: _cancelToken!,
        onSample: (avg, jitter) {
          pingSampleCount++;
          if (!mounted) return;
          setState(() {
            _livePing = avg;
            _liveJitter = jitter;
            _progress = (pingSampleCount / ApiConfig.pingAttempts) * 30;
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _phases = {..._phases, 'ping': PhaseState.done, 'download': PhaseState.active};
        _progress = 30;
      });

      final download = await _apiService.runDownloadTest(
        cancelToken: _cancelToken!,
        onProgress: (inst) {
          if (!mounted) return;
          setState(() {
            _gaugeValue = inst;
            _gaugePhaseLabel = 'فحص التنزيل';
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _phases = {..._phases, 'download': PhaseState.done, 'upload': PhaseState.active};
        _gaugeValue = download;
        _progress = 68;
      });

      final upload = await _apiService.runUploadTest(
        cancelToken: _cancelToken!,
        onProgress: (inst) {
          if (!mounted) return;
          setState(() {
            _gaugeValue = inst;
            _gaugePhaseLabel = 'فحص الرفع';
          });
        },
      );

      if (!mounted) return;
      setState(() {
        _phases = {..._phases, 'upload': PhaseState.done};
        _gaugeValue = upload;
        _gaugePhaseLabel = 'اكتمل الاختبار';
        _progress = 100;
      });

      final ipData = await _apiService.fetchIpInfo(_cancelToken!);
      final connectionType = await _deviceService.getConnectionType();
      final device = await _deviceService.getDeviceDescription();

      if (!mounted) return;

      // لا ننتقل تلقائيًا: نحتفظ بالنتيجة ونترك المستخدم على شاشة العداد
      // حتى يقرر هو الانتقال لصفحة النتائج التفصيلية.
      setState(() {
        _results = TestResults(
          pingMs: pingStats.avgMs,
          jitterMs: pingStats.jitterMs,
          downloadMbps: download,
          uploadMbps: upload,
          connectionInfo: ConnectionInfo(
            ip: (ipData['ip'] as String?) ?? '—',
            isp: ipData['isp'] as String?,
            connectionType: connectionType,
            device: device,
          ),
        );
      });
    } on SpeedTestException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _gaugePhaseLabel = 'توقف الاختبار';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع أثناء الاختبار. حاول مرة أخرى.';
        _gaugePhaseLabel = 'توقف الاختبار';
      });
    } finally {
      _isRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              children: [
                SpeedGauge(
                  value: _gaugeValue,
                  maxValue: _gaugeMaxMbps,
                  phaseLabel: _gaugePhaseLabel,
                ),
                const SizedBox(height: 26),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress / 100),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: Colors.white.withOpacity(0.06),
                      valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                PhaseTrack(phases: _phases),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LiveStat(label: 'Ping ms', value: _livePing?.toStringAsFixed(0) ?? '--'),
                    const SizedBox(width: 40),
                    _LiveStat(label: 'Jitter ms', value: _liveJitter?.toStringAsFixed(0) ?? '--'),
                  ],
                ),
                if (_results != null) ...[
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ResultsScreen(results: _results!),
                        ),
                      );
                    },
                    icon: const Icon(Icons.bar_chart_rounded, size: 20),
                    label: const Text(
                      'عرض النتائج التفصيلية',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: AppColors.text1,
                      backgroundColor: AppColors.cyan.withOpacity(0.16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                        side: BorderSide(color: Colors.white.withOpacity(0.12)),
                      ),
                    ),
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  ErrorBanner(message: _errorMessage!, onRetry: _runTest),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveStat extends StatelessWidget {
  const _LiveStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: AppColors.text1, fontSize: 22, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.text3, fontSize: 11)),
      ],
    );
  }
}
