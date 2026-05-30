import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nightingale/core/debug/tabs/federation/panels/actor_cache_panel.dart';
import 'package:nightingale/core/debug/tabs/federation/panels/deduplication_trace_panel.dart';
import 'package:nightingale/core/debug/tabs/federation/panels/incoming_activity_log_panel.dart';
import 'package:nightingale/core/debug/tabs/federation/panels/incoming_library_feed_panel.dart';
import 'package:nightingale/core/debug/tabs/federation/panels/library_publishing_panel.dart';
import 'package:nightingale/core/debug/tabs/federation/panels/moderation_state_panel.dart';
import 'package:nightingale/core/debug/tabs/federation/panels/outgoing_activity_log_panel.dart';
import 'package:nightingale/core/debug/tabs/federation/panels/reachability_status_panel.dart';
import 'package:nightingale/core/debug/tabs/federation/panels/stream_inspector_panel.dart';
import 'package:nightingale/core/debug/tabs/federation/panels/webfinger_debugger_panel.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Root widget for the "Federation" debug overlay tab.
/// Compile-time gated — only instantiated when kDebugMode is true.
class FederationInspectorTab extends StatelessWidget {
  const FederationInspectorTab({super.key});

  @override
  Widget build(BuildContext context) {
    assert(kDebugMode, 'FederationInspectorTab must only be used in debug builds');
    return DefaultTabController(
      length: 10,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: TextStyle(fontSize: 10),
            tabs: [
              Tab(text: 'Outgoing'),
              Tab(text: 'Incoming'),
              Tab(text: 'Actors'),
              Tab(text: 'Reachability'),
              Tab(text: 'Moderation'),
              Tab(text: 'WebFinger'),
              // Phase 4 tabs
              Tab(text: 'Library Pub'),
              Tab(text: 'Stream'),
              Tab(text: 'Feed'),
              Tab(text: 'Dedup'),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                OutgoingActivityLogPanel(),
                IncomingActivityLogPanel(),
                ActorCachePanel(),
                ReachabilityStatusPanel(),
                ModerationStatePanel(),
                WebFingerDebuggerPanel(),
                // Phase 4 panels
                LibraryPublishingPanel(),
                StreamInspectorPanel(),
                IncomingLibraryFeedPanel(),
                DeduplicationTracePanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
