import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nightingale/core/debug/debug_overlay.dart';
import 'package:nightingale/shared/components/buttons/app_button.dart';
import 'package:nightingale/shared/components/cards/app_card.dart';
import 'package:nightingale/shared/components/identity/person_display.dart';
import 'package:nightingale/shared/components/inputs/app_text_input.dart';
import 'package:nightingale/shared/components/modals/app_modal.dart';
import 'package:nightingale/shared/components/network_state/buffering_widget.dart';
import 'package:nightingale/shared/components/network_state/host_offline_widget.dart';
import 'package:nightingale/shared/components/network_state/partial_library_widget.dart';
import 'package:nightingale/shared/components/network_state/stream_failed_playing_local_widget.dart';
import 'package:nightingale/shared/components/sheets/app_bottom_sheet.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Tap-sequence counter for debug overlay activation.
  // 7 taps on the version label activates the overlay.
  int _tapCount = 0;
  DateTime? _lastTap;

  void _handleVersionTap() {
    if (!kDebugMode) return;
    final now = DateTime.now();
    if (_lastTap != null &&
        now.difference(_lastTap!) > const Duration(seconds: 2)) {
      _tapCount = 0;
    }
    _lastTap = now;
    _tapCount++;
    if (_tapCount >= 7) {
      _tapCount = 0;
      DebugOverlayController.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nightingale'),
        actions: [
          if (kDebugMode)
            GestureDetector(
              onTap: _handleVersionTap,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Center(
                  child: Text(
                    'DEV',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _Section(
            title: 'Buttons',
            children: [
              AppButton(label: 'Primary', onPressed: () {}),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Secondary',
                onPressed: () {},
                variant: AppButtonVariant.secondary,
              ),
              const SizedBox(height: AppSpacing.sm),
              const AppButton(label: 'Disabled', onPressed: null),
              const SizedBox(height: AppSpacing.sm),
              const AppButton(
                label: 'Loading',
                onPressed: null,
                isLoading: true,
              ),
            ],
          ),
          _Section(
            title: 'Input',
            children: [
              AppTextInput(
                label: 'Search',
                hint: 'Type something…',
                onChanged: (_) {},
              ),
            ],
          ),
          _Section(
            title: 'Card',
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Card title',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Card body text goes here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          _Section(
            title: 'Sheets & Modals',
            children: [
              AppButton(
                label: 'Show Bottom Sheet',
                variant: AppButtonVariant.secondary,
                onPressed: () => showAppBottomSheet(
                  context: context,
                  child: const Text('Bottom sheet content'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                label: 'Show Modal',
                variant: AppButtonVariant.secondary,
                onPressed: () => showAppModal(
                  context: context,
                  title: 'Modal title',
                  child: const Text('Modal content goes here.'),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Network State',
            children: [
              const BufferingWidget(statusLabel: 'Connecting to node…'),
              const SizedBox(height: AppSpacing.md),
              HostOfflineWidget(
                displayName: 'Maya',
                lastSeenAt: DateTime.now().subtract(const Duration(hours: 2)),
              ),
              const SizedBox(height: AppSpacing.md),
              const StreamFailedPlayingLocalWidget(),
              const SizedBox(height: AppSpacing.md),
              const PartialLibraryWidget(displayName: 'Jordan'),
            ],
          ),
          const _Section(
            title: 'Identity',
            children: [
              PersonDisplay(displayName: 'Maya Patel'),
              SizedBox(height: AppSpacing.md),
              PersonDisplay(
                displayName: 'Jordan Lee',
                handle: '@jordan@music.example',
                showHandle: false,
              ),
              SizedBox(height: AppSpacing.md),
              PersonDisplay(
                displayName: 'Alex Rivera',
                handle: '@alex@federated.example',
                showHandle: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(letterSpacing: 1.0),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}
