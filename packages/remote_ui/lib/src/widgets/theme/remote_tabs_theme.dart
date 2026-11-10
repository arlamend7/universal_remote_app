import 'package:flutter/material.dart';

class RemoteTabsTheme extends ThemeExtension<RemoteTabsTheme> {
  const RemoteTabsTheme({
    required this.track,
    required this.selected,
    required this.unselected,
  });

  final BoxDecoration track;
  final ButtonStyle selected, unselected;

  @override
  RemoteTabsTheme copyWith({
    BoxDecoration? track,
    ButtonStyle? selected,
    ButtonStyle? unselected,
  }) => RemoteTabsTheme(
    track: track ?? this.track,
    selected: selected ?? this.selected,
    unselected: unselected ?? this.unselected,
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
    );
  }
}
