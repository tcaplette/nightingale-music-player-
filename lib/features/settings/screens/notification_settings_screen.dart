import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/features/settings/data/settings_repository.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _notifyFollowers = true;
  bool _notifyActivity = true;
  NotificationAutoClear _autoClear = NotificationAutoClear.never;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = sl<SettingsRepository>();
    final followers = await repo.isNotifyNewFollowersEnabled();
    final activity = await repo.isNotifyActivityFeedEnabled();
    final autoClear = await repo.getNotificationAutoClear();
    if (!mounted) return;
    setState(() {
      _notifyFollowers = followers;
      _notifyActivity = activity;
      _autoClear = autoClear;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          _SectionHeader('In-App Notifications'),
          SwitchListTile(
            title: const Text('New followers'),
            subtitle: const Text('Show when someone follows you'),
            value: _notifyFollowers,
            onChanged: (v) async {
              await sl<SettingsRepository>().setNotifyNewFollowersEnabled(v);
              setState(() => _notifyFollowers = v);
            },
          ),
          SwitchListTile(
            title: const Text('Activity from people I follow'),
            subtitle: const Text('Listens, shares, and other activity'),
            value: _notifyActivity,
            onChanged: (v) async {
              await sl<SettingsRepository>().setNotifyActivityFeedEnabled(v);
              setState(() => _notifyActivity = v);
            },
          ),
          const Divider(height: AppSpacing.xl),
          _SectionHeader('Cleanup'),
          ListTile(
            title: const Text('Auto-clear read notifications'),
            subtitle: Text(_autoClear.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showAutoClearOptions(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showAutoClearOptions(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
              child: Text('Auto-clear read notifications',
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            for (final v in NotificationAutoClear.values)
              RadioListTile<NotificationAutoClear>(
                title: Text(v.label),
                value: v,
                groupValue: _autoClear,
                onChanged: (sel) async {
                  Navigator.of(ctx).pop();
                  if (sel != null) {
                    await sl<SettingsRepository>()
                        .setNotificationAutoClear(sel);
                    setState(() => _autoClear = sel);
                  }
                },
                dense: true,
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xs),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.0,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
