import 'package:flutter/material.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/deduplication/acoustic_fingerprint_service.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

/// Debug panel showing fingerprint comparisons and merge decisions.
class DeduplicationTracePanel extends StatelessWidget {
  const DeduplicationTracePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final fingerprintService = sl<AcousticFingerprintService>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _section('Fingerprinting', [
          _row('Algorithm', 'placeholder-v1 (chromaprint FFI pending)'),
          _row('Status', 'Ready for integration'),
        ]),
        const Divider(),
        _section('Merge Provenance', [
          _row('Storage', 'merge_provenance table'),
          _row('Reversible', 'Yes — unmerge supported'),
        ]),
        const Divider(),
        _section('Actions', [
          _actionRow('Scan for Duplicates', () {
            // TODO: Trigger deduplication scan
          }),
        ]),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: AppSpacing.sm),
        ...children,
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }

  Widget _row(String key, String value) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(key, style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 10)),
        ),
      ],
    ),
  );

  Widget _actionRow(String label, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: InkWell(
      onTap: onTap,
      child: Row(
        children: [
          const SizedBox(width: 110),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    ),
  );
}
