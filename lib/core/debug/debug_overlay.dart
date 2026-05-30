import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nightingale/core/debug/diagnostics.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/logging/app_logger.dart';
import 'package:nightingale/core/logging/log_event.dart';
import 'package:nightingale/core/repositories/app_info_repository.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_radius.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// Gated by kDiagnosticsEnabled — zero symbols in release binary.

// ── Tab registration ───────────────────────────────────────────────────────

class DebugOverlayTab {
  const DebugOverlayTab({required this.label, required this.builder});
  final String label;
  final WidgetBuilder builder;
}

// Built-in Phase 1 tabs. Phase 2+ tabs are added by calling
// DebugOverlayController.addTab() before the overlay is first shown.
final List<DebugOverlayTab> _tabs = [
  DebugOverlayTab(label: 'Logs', builder: (_) => const _LogsTab()),
  DebugOverlayTab(label: 'Info', builder: (_) => const _InfoTab()),
  DebugOverlayTab(label: 'Network', builder: (_) => const _NetworkTab()),
];

class DebugOverlayController {
  static OverlayEntry? _entry;

  static void addTab(DebugOverlayTab tab) {
    assert(kDiagnosticsEnabled, 'addTab is only valid in diagnostic builds');
    if (!_tabs.any((t) => t.label == tab.label)) {
      _tabs.add(tab);
    }
  }

  static void show(BuildContext context) {
    if (!kDiagnosticsEnabled) return;
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (_) => _DebugOverlay(onClose: dismiss),
    );
    Overlay.of(context).insert(_entry!);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _DebugOverlay extends StatefulWidget {
  const _DebugOverlay({required this.onClose});
  final VoidCallback onClose;

  @override
  State<_DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<_DebugOverlay> {
  int _tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: false,
      child: Material(
        color: Colors.transparent,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.neutral100.withValues(alpha: 0.97),
                borderRadius: AppRadius.lgAll,
              ),
              child: Column(
                children: [
                  _Header(
                    tabs: _tabs,
                    tabIndex: _tabIndex,
                    onTabChanged: (i) => setState(() => _tabIndex = i),
                    onClose: widget.onClose,
                  ),
                  Expanded(
                    child: _tabs[_tabIndex].builder(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.tabs,
    required this.tabIndex,
    required this.onTabChanged,
    required this.onClose,
  });

  final List<DebugOverlayTab> tabs;
  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, tab) in tabs.indexed)
                    GestureDetector(
                      onTap: () => onTabChanged(i),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: AppSpacing.md,
                          bottom: AppSpacing.sm,
                        ),
                        child: Text(
                          tab.label,
                          style: TextStyle(
                            color: tabIndex == i
                                ? AppColors.accent
                                : AppColors.neutral400,
                            fontSize: 12,
                            fontWeight: tabIndex == i
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Icon(Icons.close, size: 16, color: AppColors.neutral400),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logs Tab ─────────────────────────────────────────────────────────────────

class _LogsTab extends StatefulWidget {
  const _LogsTab();

  @override
  State<_LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<_LogsTab> {
  final List<LogEvent> _events = [];
  StreamSubscription<LogEvent>? _sub;
  LogLevel? _filterLevel;

  @override
  void initState() {
    super.initState();
    if (kDiagnosticsEnabled) {
      _sub = AppLogger.logStream.listen((e) {
        setState(() => _events.add(e));
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = _filterLevel == null
        ? _events
        : _events.where((e) => e.level.index >= _filterLevel!.index).toList();

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              for (final level in [null, LogLevel.warning, LogLevel.error])
                GestureDetector(
                  onTap: () => setState(() => _filterLevel = level),
                  child: Container(
                    margin: const EdgeInsets.only(right: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _filterLevel == level
                          ? AppColors.accent
                          : AppColors.neutral200,
                      borderRadius: AppRadius.fullAll,
                    ),
                    child: Text(
                      level == null ? 'All' : level.name,
                      style: const TextStyle(
                        color: AppColors.neutral900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? const Center(
                  child: Text(
                    'No logs yet',
                    style: TextStyle(color: AppColors.neutral400, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  reverse: true,
                  itemCount: shown.length,
                  itemBuilder: (_, i) {
                    final e = shown[shown.length - 1 - i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 2,
                      ),
                      child: Text(
                        '[${e.level.name.toUpperCase()}] [${e.tag}] ${e.message}',
                        style: TextStyle(
                          color: _levelColor(e.level),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Color _levelColor(LogLevel l) => switch (l) {
    LogLevel.verbose => AppColors.neutral400,
    LogLevel.debug => AppColors.neutral500,
    LogLevel.info => AppColors.neutral700,
    LogLevel.warning => AppColors.warningBanner,
    LogLevel.error => AppColors.errorDark,
    LogLevel.fatal => AppColors.errorDark,
  };
}

// ── Info Tab ──────────────────────────────────────────────────────────────────

class _InfoTab extends StatefulWidget {
  const _InfoTab();

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  String _version = '—';
  String _build = '—';
  String _env = '—';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = sl<AppInfoRepository>();
    final v = await repo.getVersion();
    final b = await repo.getBuildNumber();
    final e = repo.getEnvironment().name;
    if (mounted) {
      setState(() {
        _version = v;
        _build = b;
        _env = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        for (final (k, v) in [
          ('Version', _version),
          ('Build', _build),
          ('Environment', _env),
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    k,
                    style: const TextStyle(
                      color: AppColors.neutral400,
                      fontSize: 11,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    v,
                    style: const TextStyle(
                      color: AppColors.neutral700,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Network Tab (stub) ────────────────────────────────────────────────────────

class _NetworkTab extends StatelessWidget {
  const _NetworkTab();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No requests recorded yet',
        style: TextStyle(color: AppColors.neutral400, fontSize: 12),
      ),
    );
  }
}
