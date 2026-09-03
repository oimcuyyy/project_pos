import 'dart:async';
import 'package:flutter/material.dart';

class InactivityWrapper extends StatefulWidget {
  final Widget child;
  final Duration timeout;
  final VoidCallback onTimeout;

  const InactivityWrapper({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 5), // Kunci otomatis setelah 5 menit diam
    required this.onTimeout,
  });

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.timeout, () {
      widget.onTimeout();
    });
  }

  void _handleUserInteraction(PointerEvent event) {
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handleUserInteraction,
      onPointerMove: _handleUserInteraction,
      onPointerUp: _handleUserInteraction,
      child: widget.child,
    );
  }
}
