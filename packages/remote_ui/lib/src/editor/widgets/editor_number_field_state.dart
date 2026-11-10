import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'editor_number_field.dart';

class EditorNumberFieldState extends State<EditorNumberField> {
  late final _controller = TextEditingController(text: '${widget.value}');
  final _focus = FocusNode();

  String get label => widget.label;
  int get value => widget.value;
  int get minimum => widget.minimum;
  int get maximum => widget.maximum;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_focusChanged);
  }

  @override
  void didUpdateWidget(EditorNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focus.hasFocus && oldWidget.value != value) {
      _restore();
    }
  }

  void _focusChanged() {
    if (!_focus.hasFocus) {
      _restore();
    }
  }

  void _restore() => _controller.text = '$value';

  void _edit(String text) {
    final number = int.tryParse(text);
    if (number != null) {
      widget.onChanged(number);
    }
  }

  void _step(int direction) {
    _focus.unfocus();
    final next = value + direction;
    widget.onChanged(widget.isRotation ? next % (maximum + 1) : next);
  }

  @override
  void dispose() {
    _focus.removeListener(_focusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      spacing: 8,
      children: [
        Expanded(child: _caption(context)),
        _stepper(context),
      ],
    ),
  );

  Widget _caption(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodyLarge),
      if (minimum > 0)
        Text(
          'Min: $minimum · Max: $maximum',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
    ],
  );

  Widget _stepper(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _stepButton(increase: false),
        widget.isRotation ? _angle() : _input(),
        _stepButton(increase: true),
      ],
    ),
  );

  Widget _stepButton({required bool increase}) {
    if (widget.isRotation) {
      return _button(
        increase ? 1 : -1,
        increase ? Icons.rotate_right : Icons.rotate_left,
        increase ? 'Rotate right 90°' : 'Rotate left 90°',
        true,
      );
    }
    return _button(
      increase ? 1 : -1,
      increase ? Icons.add : Icons.remove,
      increase ? 'Increase $label' : 'Decrease $label',
      increase ? value < maximum : value > minimum,
    );
  }

  Widget _button(int direction, IconData icon, String tooltip, bool enabled) =>
      IconButton(
        tooltip: tooltip,
        onPressed: enabled ? () => _step(direction) : null,
        icon: Icon(icon, size: 20),
      );

  Widget _angle() => SizedBox(
    width: 40,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${value * 90}°',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ),
  );

  Widget _input() => SizedBox(
    width: 40,
    child: Semantics(
      label: label,
      child: TextField(
        key: PageStorageKey(('number', label)),
        controller: _controller,
        focusNode: _focus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          isDense: true,
          filled: false,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onChanged: _edit,
        onSubmitted: (_) => _restore(),
      ),
    ),
  );
}
