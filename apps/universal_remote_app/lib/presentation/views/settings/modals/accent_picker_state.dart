import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:remote_ui/remote_ui.dart';

import '../widgets/accent_spectrum.dart';
import '../widgets/accent_swatches.dart';
import 'accent_picker.dart';

class AccentPickerState extends State<AccentPicker> {
  late HSVColor _color = HSVColor.fromColor(Color(widget.initialValue));
  late final _hex = TextEditingController(text: _format(widget.initialValue));

  @override
  Widget build(BuildContext context) => AppSheet(
    title: 'Custom Accent',
    subtitle: 'Fine-tune hue and saturation',
    child: _content(),
    footer: _actions(),
  );

  Widget _content() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _preview(),
      const SizedBox(height: 18),
      _spectrumHeading(),
      const SizedBox(height: 8),
      AccentSpectrum(color: _color, onChanged: _select),
      const SizedBox(height: 12),
      const Text('Quick Palettes'),
      const SizedBox(height: 6),
      AccentSwatches(
        value: _color.toColor().toARGB32(),
        onSelected: (value) => _select(HSVColor.fromColor(Color(value))),
      ),
    ],
  );

  Widget _preview() => Card(
    child: Padding(padding: const EdgeInsets.all(12), child: _previewRow()),
  );

  Widget _previewRow() => Row(
    children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _color.toColor(),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      const SizedBox(width: 10),
      const Expanded(child: Text('Active Color')),
      const SizedBox(width: 8),
      Expanded(child: _hexField()),
    ],
  );

  Widget _hexField() => TextField(
    controller: _hex,
    autocorrect: false,
    textCapitalization: TextCapitalization.characters,
    inputFormatters: [
      FilteringTextInputFormatter.allow(RegExp('[0-9A-Fa-f]')),
      LengthLimitingTextInputFormatter(6),
    ],
    decoration: const InputDecoration(labelText: 'Hex color', prefixText: '#'),
    onChanged: _editHex,
  );

  Widget _spectrumHeading() => Wrap(
    alignment: WrapAlignment.spaceBetween,
    children: [const Text('SPECTRUM'), Text('Hue ${_color.hue.round()}°')],
  );

  Widget _actions() => AppSheetActions(
    secondary: OutlinedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Cancel'),
    ),
    primary: FilledButton(
      onPressed: _hex.text.length == 6
          ? () => Navigator.pop(context, _color.toColor().toARGB32())
          : null,
      child: const Text('Apply Color'),
    ),
  );

  void _editHex(String value) {
    setState(() {
      final rgb = int.tryParse(value, radix: 16);
      if (value.length == 6 && rgb != null) {
        _color = HSVColor.fromColor(Color(0xff000000 | rgb));
      }
    });
  }

  void _select(HSVColor color) {
    setState(() {
      _color = color;
      _hex.text = _format(color.toColor().toARGB32());
    });
  }

  String _format(int value) =>
      (value & 0xffffff).toRadixString(16).padLeft(6, '0').toUpperCase();

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }
}
