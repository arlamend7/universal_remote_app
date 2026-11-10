import 'dart:async';

import 'package:flutter/material.dart';

import '../../feedback/remote_feedback.dart';
import 'action_button.dart';

class ActionButtonState extends State<ActionButton> {
  Timer? _timer;
  bool _pressed = false;
  bool _busy = false;

  void _start() {
    if (!widget.repeat || widget.onPressed == null) {
      return;
    }
    unawaited(_press());
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 220), (_) {
      unawaited(_press(repeating: true));
    });
  }

  Future<void> _press({bool repeating = false}) async {
    final action = widget.onPressed;
    if (_busy || action == null || !mounted) {
      return;
    }
    _busy = true;
    try {
      repeating ? RemoteFeedback.tick() : RemoteFeedback.tap();
      await action();
    } catch (_) {
      _stop();
      RemoteFeedback.failure();
    } finally {
      _busy = false;
    }
  }

  @override
  void didUpdateWidget(covariant ActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.repeat || (widget.onPressed == null && !_busy)) {
      _stop();
      _pressed = false;
    }
  }

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) {
      return;
    }
    setState(() => _pressed = value);
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: _description,
    enabled: widget.onPressed != null,
    child: _gesture(context),
  );
  Widget _gesture(BuildContext context) => Tooltip(
    message: _description,
    child: Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) {
        _setPressed(false);
        _stop();
      },
      onPointerCancel: (_) {
        _setPressed(false);
        _stop();
      },
      child: _button(context),
    ),
  );
  String get _description {
    final reason = widget.unavailableReason;
    return reason == null ? widget.label : '${widget.label}. $reason';
  }

  Widget _button(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(
      widget.elementStyle?.cornerRadius ?? 12,
    ),
    onTap: widget.onPressed == null ? null : _press,
    onLongPress: widget.repeat && widget.onPressed != null ? _start : null,
    child: ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      child: Padding(
        padding: const EdgeInsets.all(_inset),
        child: Center(
          child: AnimatedScale(
            scale: _pressed ? .9 : 1,
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            child: Opacity(
              opacity: widget.onPressed == null ? .38 : 1,
              child: _label(),
            ),
          ),
        ),
      ),
    ),
  );
  Color? get _foreground {
    final value = widget.elementStyle?.foreground;
    return value == null ? null : Color(value);
  }

  /// Identical on every side so neighbouring controls line up.
  static const _inset = 4.0;
  static const _gap = 4.0;

  bool get _showIcon =>
      !widget.showLabel ||
      widget.appearance['showLabel'] == 'false' ||
      (widget.elementStyle?.showIcon ??
          (widget.appearance['showIcon'] != 'false'));

  Widget _label() => Column(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      if (_showIcon)
        widget.iconWidget ??
            Icon(
              widget.icon,
              size: widget.elementStyle?.iconSize ?? 24,
              color: _foreground ?? Theme.of(context).colorScheme.primary,
            ),
      if (widget.showLabel && widget.appearance['showLabel'] != 'false')
        const SizedBox(height: _gap),
      if (widget.showLabel && widget.appearance['showLabel'] != 'false')
        Flexible(
          child: Text(
            widget.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _foreground),
          ),
        ),
    ],
  );
}
