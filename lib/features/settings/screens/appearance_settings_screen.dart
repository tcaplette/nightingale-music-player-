import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale/features/settings/providers/motion_notifier.dart';
import 'package:nightingale/features/settings/providers/theme_notifier.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeNotifierProvider).valueOrNull ?? ThemeMode.system;
    final reduceMotion = ref.watch(motionNotifierProvider).valueOrNull ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Appearance')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          _SectionHeader('Theme'),
          _ThemeOption(
            label: 'System default',
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (v) =>
                ref.read(themeNotifierProvider.notifier).setTheme(v),
          ),
          _ThemeOption(
            label: 'Light',
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (v) =>
                ref.read(themeNotifierProvider.notifier).setTheme(v),
          ),
          _ThemeOption(
            label: 'Dark',
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (v) =>
                ref.read(themeNotifierProvider.notifier).setTheme(v),
          ),
          const Divider(height: AppSpacing.xl),
          _SectionHeader('Motion'),
          SwitchListTile(
            title: const Text('Reduce motion'),
            subtitle: const Text('Shortens all animations'),
            value: reduceMotion,
            onChanged: (v) =>
                ref.read(motionNotifierProvider.notifier).setReduceMotion(v),
          ),
        ],
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

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String label;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return RadioListTile<ThemeMode>(
      title: Text(label),
      value: value,
      groupValue: groupValue,
      onChanged: (v) => v != null ? onChanged(v) : null,
      dense: true,
    );
  }
}
