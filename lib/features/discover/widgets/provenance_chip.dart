import 'package:flutter/material.dart';
import 'package:nightingale/features/recommendations/domain/provenance_record.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/theme/app_colors.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class ProvenanceChip extends StatelessWidget {
  const ProvenanceChip({super.key, required this.provenance, this.avatarUrl});

  final ProvenanceRecord provenance;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final hasActor = provenance.topActorDisplayName != null;

    if (!hasActor) {
      return Text(
        provenance.reasonString,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.neutral400,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PersonDisplay(
          displayName: provenance.topActorDisplayName!,
          avatarUrl: avatarUrl,
          avatarSize: 20,
        ),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            _reasonWithoutName(
                provenance.reasonString, provenance.topActorDisplayName!),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.neutral400,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _reasonWithoutName(String reason, String name) {
    // If reason starts with the name, trim it so we don't repeat alongside the avatar
    if (reason.startsWith(name)) {
      final rest = reason.substring(name.length).trimLeft();
      return rest.isEmpty ? reason : rest;
    }
    return reason;
  }
}
