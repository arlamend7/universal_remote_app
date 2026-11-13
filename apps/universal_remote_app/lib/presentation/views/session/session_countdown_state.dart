
import 'dart:async';

import 'package:flutter/material.dart';

import 'session_countdown.dart';

class SessionCountdownState extends State<SessionCountdown> {
  Timer? _refresh;
  String _text = '';

  static const int _microsecondsPerMinute =
      Duration.microsecondsPerMinute;

  @override
  void initState() {
    super.initState();

    widget.session.addListener(_update);
    widget.visible?.addListener(_update);

    _update();
  }

  @override
  void didUpdateWidget(SessionCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.session != oldWidget.session) {
      oldWidget.session.removeListener(_update);
      widget.session.addListener(_update);
    }

    if (widget.visible != oldWidget.visible) {
      oldWidget.visible?.removeListener(_update);
      widget.visible?.addListener(_update);
    }

    _update();
  }

  void _update() {
    _refresh?.cancel();
    _refresh = null;

    if (widget.visible?.value == false) {
      return;
    }

    final remaining = widget.session.remaining;

    // Round up to avoid displaying 00:00 before expiration.
    final totalMinutes =
        (remaining.inMicroseconds +
            _microsecondsPerMinute - 1) ~/
        _microsecondsPerMinute;

    final hours =
        (totalMinutes ~/ 60).toString().padLeft(2, '0');

    final minutes =
        (totalMinutes % 60).toString().padLeft(2, '0');

    final next = '$hours:$minutes';

    if (next != _text) {
      setState(() => _text = next);
    }

    if (!widget.session.counting ||
        remaining <= Duration.zero) {
      return;
    }

    // Schedule the next update at the minute boundary,
    // instead of refreshing every second.
    final remainder =
        remaining.inMicroseconds % _microsecondsPerMinute;

    final delay = Duration(
      microseconds: remainder == 0
          ? _microsecondsPerMinute
          : remainder,
    ) + const Duration(seconds: 30);

    _refresh = Timer(delay, _update);
  }

  @override
  void dispose() {
    _refresh?.cancel();

    widget.session.removeListener(_update);
    widget.visible?.removeListener(_update);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _text);
}
