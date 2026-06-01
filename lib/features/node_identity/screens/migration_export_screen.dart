import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/node_identity/migration_service.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';
import 'package:nightingale/shared/theme/app_typography.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Settings entry point for exporting a migration token.
/// No cryptographic terminology in the primary label.
class MigrationExportScreen extends StatefulWidget {
  const MigrationExportScreen({super.key});

  @override
  State<MigrationExportScreen> createState() => _MigrationExportScreenState();
}

class _MigrationExportScreenState extends State<MigrationExportScreen> {
  String? _token;
  String? _error;
  bool _loading = false;

  Future<void> _export() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await sl<MigrationService>().exportToken();
    if (!mounted) return;
    if (result is MigrationTokenOk) {
      setState(() {
        _token = result.token;
        _loading = false;
      });
    } else {
      setState(() {
        _error = (result as MigrationTokenError).reason;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Back up your account')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transfer your account to a new phone',
                style: AppTypography.headlineSm,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Generate a transfer code and scan it on your new phone. '
                'Your followers and library connections will carry over.',
                style: AppTypography.bodyMd,
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_token == null && !_loading)
                ElevatedButton(
                  onPressed: _export,
                  child: const Text('Generate transfer code'),
                ),
              if (_loading)
                const CircularProgressIndicator.adaptive(),
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (_token != null) ...[
                if (_token!.length <= 2048) ...[
                  Center(
                    child: QrImageView(
                      data: _token!,
                      size: 240,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Or copy the code:', style: AppTypography.labelMd),
                ] else ...[
                  Text(
                    'Your profile photo makes this code too large for a QR — use the copy button instead.',
                    style: AppTypography.bodySm,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Copy the code:', style: AppTypography.labelMd),
                ],
                const SizedBox(height: AppSpacing.sm),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: _token!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard')),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _token!.substring(
                        0,
                        _token!.length > 60 ? 60 : _token!.length,
                      ) + '…',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'This code expires in 72 hours and can only be used once.',
                  style: AppTypography.bodySm.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
