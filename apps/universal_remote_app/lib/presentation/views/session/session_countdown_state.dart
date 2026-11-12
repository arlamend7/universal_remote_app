import 'dart:async';

import 'package:flutter/material.dart';

import 'session_countdown.dart';

class SessionCountdownState extends State<SessionCountdown> {
  Timer? _refresh;
  String _text = '';

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
    if (widget.visible?.value == false) {
      return;
    }
    final remaining = widget.session.remaining;
    final seconds = (remaining.inMicroseconds + 999999) ~/ 1000000;
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final rest = (seconds % 60).toString().padLeft(2, '0');
    final next = '$minutes:$rest';
    if (next != _text) {
      setState(() => _text = next);
    }
    if (!widget.session.counting) {
      return;
    }
    _refresh = Timer(const Duration(seconds: 1), _update);
  }

  @override
  void dispose() {
    _refresh?.cancel();
    widget.session.removeListener(_update);
    widget.visible?.removeListener(_update);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _text);
}
