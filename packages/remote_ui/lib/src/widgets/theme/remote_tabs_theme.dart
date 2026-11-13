import 'package:flutter/material.dart';

class RemoteTabsTheme extends ThemeExtension<RemoteTabsTheme> {
  const RemoteTabsTheme({
    required this.track,
    required this.selected,
    required this.unselected,
    required this.padding,
    required this.spacing,
    required this.iconSize,
    required this.iconSpacing,
  });

  final BoxDecoration track;
  final ButtonStyle selected, unselected;
  final EdgeInsets padding;
  final double spacing, iconSize, iconSpacing;

  @override
  RemoteTabsTheme copyWith({
    BoxDecoration? track,
    ButtonStyle? selected,
    ButtonStyle? unselected,
    EdgeInsets? padding,
    double? spacing,
    double? iconSize,
    double? iconSpacing,
  }) => RemoteTabsTheme(
    track: track ?? this.track,
    selected: selected ?? this.selected,
    unselected: unselected ?? this.unselected,
    padding: padding ?? this.padding,
    spacing: spacing ?? this.spacing,
    iconSize: iconSize ?? this.iconSize,
    iconSpacing: iconSpacing ?? this.iconSpacing,
  );

  @override
  RemoteTabsTheme lerp(RemoteTabsTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return RemoteTabsTheme(
      track: BoxDecoration.lerp(track, other.track, t)!,
      selected: ButtonStyle.lerp(selected, other.selected, t)!,
      unselected: ButtonStyle.lerp(unselected, other.unselected, t)!,
      padding: EdgeInsets.lerp(padding, other.padding, t)!,
      spacing: spacing + (other.spacing - spacing) * t,
      iconSize: iconSize + (other.iconSize - iconSize) * t,
      iconSpacing: iconSpacing + (other.iconSpacing - iconSpacing) * t,
    );
  }
}
