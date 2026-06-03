import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/federation/stun/stun_address_resolver.dart';
import 'package:nightingale/features/node_identity/node_identity_repository.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';
import 'package:nightingale/shared/theme/app_typography.dart';

class ProfileSettingsScreen extends ConsumerStatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  ConsumerState<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState
    extends ConsumerState<ProfileSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;

  String _username = '';
  Uint8List? _currentAvatarBytes;
  Uint8List? _stagedAvatarBytes;
  bool _loading = true;
  bool _saving = false;
  bool _dirty = false;
  String? _shareableHandle;
  bool _resolvingAddress = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_onFieldChanged);
    _bioController = TextEditingController()..addListener(_onFieldChanged);
    _loadProfile();
    _loadShareableHandle();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_loading) setState(() => _dirty = true);
  }

  Future<void> _loadShareableHandle() async {
    final repo = sl<NodeIdentityRepository>();
    final handle = await repo.getShareableHandle();
    if (!mounted) return;
    setState(() => _shareableHandle = handle);
  }

  Future<void> _retryStun() async {
    setState(() => _resolvingAddress = true);
    try {
      final stun = sl<StunAddressResolver>();
      final address = await stun.resolve();
      final repo = sl<NodeIdentityRepository>();
      await repo.updatePublicAddress(address);
      await _loadShareableHandle();
    } catch (_) {}
    if (mounted) setState(() => _resolvingAddress = false);
  }

  Future<void> _copyAddress() async {
    if (_shareableHandle == null) return;
    await Clipboard.setData(ClipboardData(text: _shareableHandle!));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Address copied')),
    );
  }

  Future<void> _loadProfile() async {
    final repo = sl<NodeIdentityRepository>();
    final actor = await repo.getLocalActor();
    final avatarBytes = await repo.getAvatarBytes();
    if (!mounted) return;
    setState(() {
      _nameController.text = actor.name;
      _bioController.text = actor.summary ?? '';
      _username = actor.preferredUsername;
      _currentAvatarBytes = avatarBytes;
      _loading = false;
      _dirty = false;
    });
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    final raw = await file.readAsBytes();
    final compressed = await FlutterImageCompress.compressWithList(
      raw,
      minWidth: 256,
      minHeight: 256,
      quality: 85,
      format: CompressFormat.jpeg,
    );
    if (!mounted) return;
    setState(() {
      _stagedAvatarBytes = compressed;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final repo = sl<NodeIdentityRepository>();
      await repo.updateProfile(
        displayName: _nameController.text.trim(),
        summary: _bioController.text.trim().isEmpty
            ? null
            : _bioController.text.trim(),
        avatarBytes: _stagedAvatarBytes ?? _currentAvatarBytes,
      );
      if (!mounted) return;
      setState(() {
        _currentAvatarBytes = _stagedAvatarBytes ?? _currentAvatarBytes;
        _stagedAvatarBytes = null;
        _dirty = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final previewBytes = _stagedAvatarBytes ?? _currentAvatarBytes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: _dirty && !_saving ? _save : null,
            child: _saving
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                // ── Avatar ──────────────────────────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        _AvatarPreview(
                          bytes: previewBytes,
                          displayName: _nameController.text,
                          size: 80,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: scheme.primary,
                            child: Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: scheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Display name ─────────────────────────────────────────────
                Text('Display name', style: AppTypography.labelMd),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Your name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Username (read-only) ─────────────────────────────────────
                Text('Username', style: AppTypography.labelMd),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm + 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outline),
                    borderRadius: BorderRadius.circular(4),
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    '@$_username',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Username cannot be changed after account creation.',
                  style: AppTypography.bodySm
                      .copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Bio ──────────────────────────────────────────────────────
                Text('Bio', style: AppTypography.labelMd),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _bioController,
                  maxLines: 3,
                  maxLength: 160,
                  decoration: const InputDecoration(
                    hintText: 'Tell people about yourself (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Your address ─────────────────────────────────────────────
                Text('Your address', style: AppTypography.labelMd),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Share this with anyone so they can find you.',
                  style: AppTypography.bodySm.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _AddressSection(
                  handle: _shareableHandle,
                  resolving: _resolvingAddress,
                  onCopy: _copyAddress,
                  onRetry: _retryStun,
                ),
              ],
            ),
    );
  }
}

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.handle,
    required this.resolving,
    required this.onCopy,
    required this.onRetry,
  });

  final String? handle;
  final bool resolving;
  final VoidCallback onCopy;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (resolving) {
      return const Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: AppSpacing.sm),
          Text('Resolving your address…'),
        ],
      );
    }

    if (handle == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Could not resolve public address.',
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outline),
        borderRadius: BorderRadius.circular(4),
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              handle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            tooltip: 'Copy address',
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.bytes,
    required this.displayName,
    required this.size,
  });

  final Uint8List? bytes;
  final String displayName;
  final double size;

  String get _initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final b = bytes;
    if (b != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: MemoryImage(b),
      );
    }
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: scheme.primary.withValues(alpha: 0.15),
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
