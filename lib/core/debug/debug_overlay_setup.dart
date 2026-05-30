import 'package:flutter/material.dart';
import 'package:nightingale/core/debug/diagnostics.dart';
import 'package:nightingale/core/debug/debug_overlay.dart';
import 'package:nightingale/core/debug/tabs/federation/federation_inspector_tab.dart';
import 'package:nightingale/core/debug/tabs/library_scan_log_tab.dart';
import 'package:nightingale/core/debug/tabs/performance/performance_overlay_tab.dart';
import 'package:nightingale/core/debug/tabs/playback_diagnostics_tab.dart';
import 'package:nightingale/core/debug/tabs/recommendations/affinity_matrix_tab.dart';
import 'package:nightingale/core/debug/tabs/recommendations/recommendation_inspector_tab.dart';
import 'package:nightingale/core/debug/tabs/recommendations/signal_event_log_tab.dart';
import 'package:nightingale/core/debug/tabs/social/activity_delivery_report_tab.dart';
import 'package:nightingale/core/debug/tabs/social/feed_hydration_log_tab.dart';
import 'package:nightingale/core/debug/tabs/social/social_graph_inspector_tab.dart';

/// Register all debug overlay tabs for Phases 2–6.
/// Called once from setupServiceLocator() — no-op in release builds.
void registerDebugOverlayTabs() {
  if (!kDiagnosticsEnabled) return;
  DebugOverlayController.addTab(
    const DebugOverlayTab(label: 'Playback', builder: _playbackTabBuilder),
  );
  DebugOverlayController.addTab(
    const DebugOverlayTab(label: 'Lib Scan', builder: _libScanTabBuilder),
  );
  DebugOverlayController.addTab(
    const DebugOverlayTab(label: 'Federation', builder: _federationTabBuilder),
  );
  // Phase 5 — social debug panels
  DebugOverlayController.addTab(
    const DebugOverlayTab(label: 'Social Graph', builder: _socialGraphTabBuilder),
  );
  DebugOverlayController.addTab(
    const DebugOverlayTab(
      label: 'Activity Delivery',
      builder: _activityDeliveryTabBuilder,
    ),
  );
  DebugOverlayController.addTab(
    const DebugOverlayTab(
      label: 'Feed Hydration',
      builder: _feedHydrationTabBuilder,
    ),
  );
  // Phase 6 — recommendation debug tabs
  DebugOverlayController.addTab(
    const DebugOverlayTab(label: 'Rec Engine', builder: _recEngineTabBuilder),
  );
  DebugOverlayController.addTab(
    const DebugOverlayTab(label: 'Signals', builder: _signalsTabBuilder),
  );
  DebugOverlayController.addTab(
    const DebugOverlayTab(label: 'Affinity', builder: _affinityTabBuilder),
  );
  // Phase 7 — performance overlay tab
  DebugOverlayController.addTab(
    const DebugOverlayTab(label: 'Perf', builder: _performanceTabBuilder),
  );
}

Widget _playbackTabBuilder(BuildContext context) => const PlaybackDiagnosticsTab();
Widget _libScanTabBuilder(BuildContext context) => const LibraryScanLogTab();
Widget _federationTabBuilder(BuildContext context) => const FederationInspectorTab();
Widget _socialGraphTabBuilder(BuildContext context) => const SocialGraphInspectorTab();
Widget _activityDeliveryTabBuilder(BuildContext context) =>
    const ActivityDeliveryReportTab();
Widget _feedHydrationTabBuilder(BuildContext context) => const FeedHydrationLogTab();
Widget _recEngineTabBuilder(BuildContext context) => const RecommendationInspectorTab();
Widget _signalsTabBuilder(BuildContext context) => const SignalEventLogTab();
Widget _affinityTabBuilder(BuildContext context) => const AffinityMatrixTab();
Widget _performanceTabBuilder(BuildContext context) => const PerformanceOverlayTab();
