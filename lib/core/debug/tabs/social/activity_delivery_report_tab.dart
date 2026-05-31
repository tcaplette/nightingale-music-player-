import 'package:drift/drift.dart' show OrderingTerm, OrderingMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nightingale/core/database/app_database.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class ActivityDeliveryReportTab extends StatefulWidget {
  const ActivityDeliveryReportTab({super.key});

  @override
  State<ActivityDeliveryReportTab> createState() =>
      _ActivityDeliveryReportTabState();
}

class _ActivityDeliveryReportTabState
    extends State<ActivityDeliveryReportTab> {
  List<OutboxActivitiesTableData> _activities = [];

  @override
  void initState() {
    super.initState();
    assert(
      kDebugMode,
      'ActivityDeliveryReportTab must only be used in debug builds',
    );
    _load();
  }

  Future<void> _load() async {
    final db = sl<AppDatabase>();
    final rows = await (db.select(db.outboxActivitiesTable)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ])
          ..limit(100))
        .get();
    if (mounted) setState(() => _activities = rows);
  }

  @override
  Widget build(BuildContext context) {
    if (_activities.isEmpty) {
      return const Center(
        child: Text(
          'No outgoing activities yet',
          style: TextStyle(color: AppColors.neutral400, fontSize: 12),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.sm),
      itemCount: _activities.length,
      itemBuilder: (_, i) {
        final a = _activities[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _StatusChip(a.status),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      a.type,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.neutral700,
                      ),
                    ),
                  ),
                  Text(
                    _relTime(a.createdAt),
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.neutral400,
                    ),
                  ),
                ],
              ),
              Text(
                a.targetInboxUrl,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.neutral400,
                  fontFamily: 'monospace',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 2) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);
  final String status;

  Color get _color => switch (status) {
        'delivered' => const Color(0xFF34C759),
        'retrying' => AppColors.warningBanner,
        'failed' => AppColors.errorDark,
        _ => AppColors.neutral400,
      };

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          status,
          style: TextStyle(fontSize: 9, color: _color),
        ),
      );
}

