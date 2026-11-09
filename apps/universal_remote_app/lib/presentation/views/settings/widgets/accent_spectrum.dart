import 'package:flutter/material.dart';

import '../../../../shared/themes/app_themes.dart';

class AccentSpectrum extends StatelessWidget {
  const AccentSpectrum({
    super.key,
    required this.color,
    required this.onChanged,
  });

  final HSVColor color;
  final ValueChanged<HSVColor> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    spacing: 10,
    children: [
      _bar(
        context,
        'Hue',
        color.hue / 360,
        AppThemes.hueSpectrum,
        (value) => onChanged(color.withHue(value * 360)),
      ),
      _bar(context, 'Color tone', _tone, [
        Colors.black,
        color.withValue(1).withSaturation(1).toColor(),
        Colors.white,
      ], _setTone),
    ],
  );

  double get _tone =>
      color.value < 1 ? color.value / 2 : 1 - color.saturation / 2;

  void _setTone(double tone) {
    final value = (tone * 2).clamp(0.0, 1.0);
    final saturation = (2 - tone * 2).clamp(0.0, 1.0);
    onChanged(color.withValue(value).withSaturation(saturation));
  }

  Widget _bar(
    BuildContext context,
    String label,
    double value,
    List<Color> colors,
    ValueChanged<double> onChanged,
  ) => SizedBox(
    height: 34,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(9),
      ),
      child: SliderTheme(
        data: AppThemes.spectrumSlider(Theme.of(context)),
        child: Slider(
          value: value,
          semanticFormatterCallback: (position) =>
              '$label ${(position * 100).round()}%',
          onChanged: onChanged,
        ),
      ),
    ),
  );
}
