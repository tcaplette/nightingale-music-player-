import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:nightingale/core/debug/diagnostics.dart';
import 'package:nightingale/core/debug/network_inspector.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// Only compiled in diagnostic builds — zero overhead in release.

class PerformanceOverlayTab extends StatefulWidget {
  const PerformanceOverlayTab({super.key});

  @override
  State<PerformanceOverlayTab> createState() => _PerformanceOverlayTabState();
}

class _PerformanceOverlayTabState extends State<PerformanceOverlayTab> {
  // Frame timing
  double _currentFrameMs = 0;
  double _avgFrameMs = 0;
  double _peakFrameMs60s = 0;
  final List<double> _frameHistory = [];
  DateTime _peakWindow = DateTime.now();

  // Memory
  int _rssBytes = 0;
  Timer? _memTimer;

  @override
  void initState() {
    super.initState();
    if (kDiagnosticsEnabled) {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
      _memTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updateMemory());
      _updateMemory();
    }
  }

  @override
  void dispose() {
    if (kDiagnosticsEnabled) {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
    }
    _memTimer?.cancel();
    super.dispose();
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!mounted) return;
    for (final t in timings) {
      final ms = t.totalSpan.inMicroseconds / 1000.0;
      _frameHistory.add(ms);
      if (_frameHistory.length > 300) _frameHistory.removeAt(0);

      final now = DateTime.now();
      if (now.difference(_peakWindow) > const Duration(seconds: 60)) {
        _peakFrameMs60s = 0;
        _peakWindow = now;
      }
      if (ms > _peakFrameMs60s) _peakFrameMs60s = ms;
    }

    final avg = _frameHistory.isEmpty
        ? 0.0
        : _frameHistory.reduce((a, b) => a + b) / _frameHistory.length;
    final current = _frameHistory.isEmpty ? 0.0 : _frameHistory.last;

    setState(() {
      _currentFrameMs = current;
      _avgFrameMs = avg;
    });
  }

  void _updateMemory() {
    // ProcessInfo.currentRss is available on Linux/macOS/Android/iOS
    try {
      final rss = ProcessInfo.currentRss;
      if (mounted) setState(() => _rssBytes = rss);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (!kDiagnosticsEnabled) return const SizedBox.shrink();

    final inspector = sl<NetworkInspector>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _Section(
          label: 'Frame Render Time',
          children: [
            _Row('Current', '${_currentFrameMs.toStringAsFixed(1)} ms'),
            _Row('Average', '${_avgFrameMs.toStringAsFixed(1)} ms'),
            _Row(
              'Peak (60 s)',
              '${_peakFrameMs60s.toStringAsFixed(1)} ms',
              warn: _peakFrameMs60s > 16.7,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _Section(
          label: 'Memory',
          children: [
            _Row('RSS', '${(_rssBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                warn: _rssBytes > 150 * 1024 * 1024),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _Section(
          label: 'Network',
          children: [
            _Row('Requests (session)',
                inspector.totalRequestCount.toString()),
            _Row('Bytes received',
                '${(inspector.totalBytesReceived / 1024).toStringAsFixed(1)} KB'),
          ],
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.children});
  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              color: AppColors.neutral400,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            )),
        const SizedBox(height: AppSpacing.xs),
        ...children,
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.warn = false});
  final String label;
  final String value;
  final bool warn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.neutral400, fontSize: 11)),
          Text(value,
              style: TextStyle(
                color: warn ? AppColors.warningBanner : AppColors.neutral700,
                fontSize: 11,
                fontFamily: 'monospace',
              )),
        ],
      ),
    );
  }
}
