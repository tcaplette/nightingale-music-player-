import 'package:flutter/material.dart';
import 'package:nightingale/features/library/services/metadata_validator.dart';

class MetadataBadge extends StatelessWidget {
  const MetadataBadge({super.key, required this.result});

  final MetadataValidationResult result;

  static const double _size = 8.0;

  @override
  Widget build(BuildContext context) {
    final color = switch (result) {
      MetadataComplete() => const Color(0xFF34C759),
      MetadataIncomplete() => const Color(0xFFFF3B30),
    };

    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
