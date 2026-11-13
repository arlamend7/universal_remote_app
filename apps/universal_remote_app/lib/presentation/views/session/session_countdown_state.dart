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

  /// Shows the remaining time and refreshes exactly when the shown value
  /// changes: each minute for the footer, each second in the final minute.
  void _update() {
    _refresh?.cancel();
    _refresh = null;
    if (widget.visible?.value == false) {
      return;
    }
    final remaining = widget.session.remaining;
    final next = widget.precision.format(remaining);
    if (next != _text) {
      setState(() => _text = next);
    }
    if (!widget.session.counting || remaining <= Duration.zero) {
      return;
    }
    _refresh = Timer(widget.precision.untilNextChange(remaining), _update);
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
