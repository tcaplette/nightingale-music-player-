import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:nightingale/core/di/service_locator.dart';
import 'package:nightingale/core/federation/actor_resolver.dart';
import 'package:nightingale/shared/theme/app_spacing.dart';

class WebFingerDebuggerPanel extends StatefulWidget {
  const WebFingerDebuggerPanel({super.key});

  @override
  State<WebFingerDebuggerPanel> createState() => _WebFingerDebuggerPanelState();
}

class _WebFingerDebuggerPanelState extends State<WebFingerDebuggerPanel> {
  final _controller = TextEditingController();
  String? _result;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _resolve() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;
    setState(() {
      _loading = true;
      _result = null;
    });
    final resolver = sl<ActorResolver>();
    final result = await resolver.resolve(input);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _result = switch (result) {
        ResolveOk(:final actor) =>
          'OK — actor: ${actor.id}\n\n'
          + const JsonEncoder.withIndent('  ').convert(actor.toJson()),
        ResolveFailed(:final reason) => 'FAILED: $reason',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: const TextStyle(fontSize: 11),
                  decoration: const InputDecoration(
                    hintText: '@user@domain or actor URL',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _resolve(),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton(
                onPressed: _loading ? null : _resolve,
                child: const Text('Resolve', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const CircularProgressIndicator.adaptive()
          else if (_result != null)
            Expanded(
              child: SingleChildScrollView(
                child: SelectableText(
                  _result!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
