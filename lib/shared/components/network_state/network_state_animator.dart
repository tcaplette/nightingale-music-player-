import 'package:flutter/material.dart';
import 'package:nightingale/shared/theme/app_motion.dart';

/// Wraps a network-state widget with a fade-in entrance using
/// [AppMotion.stateTransition] duration and [AppMotion.curveStandard] easing.
/// All four network-state components use this wrapper.
class NetworkStateAnimator extends StatefulWidget {
  const NetworkStateAnimator({super.key, required this.child});

  final Widget child;

  @override
  State<NetworkStateAnimator> createState() => _NetworkStateAnimatorState();
}

class _NetworkStateAnimatorState extends State<NetworkStateAnimator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.stateTransition,
    );
    _opacity = CurvedAnimation(parent: _controller, curve: AppMotion.curveStandard);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
