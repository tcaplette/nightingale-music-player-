import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/library/providers/library_providers.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

// Only used in debug builds. Registered via DebugOverlayController.addTab.
class LibraryScanLogTab extends ConsumerWidget {
  const LibraryScanLogTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(kDebugMode);
    final scanState = ref.watch(libraryScanProvider);

    if (scanState.status == LibraryScanStatus.scanning) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: AppSpacing.md),
            Text(
              'scanning…',
              style: TextStyle(color: AppColors.neutral400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final result = scanState.lastResult;
    if (result == null) {
      return const Center(
        child: Text(
          'No scan run yet',
          style: TextStyle(color: AppColors.neutral400, fontSize: 12),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _ScanRow('Completed', _fmtTime(result.completedAt)),
        _ScanRow('Duration', '${result.durationMs}ms'),
        _ScanRow('Found', '${result.totalFound}'),
        _ScanRow('Parsed', '${result.parsed}'),
        _ScanRow('Rejected', '${result.rejected}'),
        if (result.errors.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          const Text(
            'ERRORS',
            style: TextStyle(
              color: AppColors.errorDark,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final err in result.errors)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${err.filePath}\n  → ${err.reason}',
                style: const TextStyle(
                  color: AppColors.neutral500,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ],
    );
  }

  String _fmtTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}

class _ScanRow extends StatelessWidget {
  const _ScanRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.neutral400,
                fontSize: 11,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.neutral700,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
