import 'package:flutter/widgets.dart' show Widget;

/// One consistent, display-ready reading produced by a [RemoteInfo].
final class RemoteReading {
  const RemoteReading(
    this.title, {
    this.subtitle,
    this.leading,
    this.semanticsLabel,
  });

  final String title;

  /// Spoken form when the title alone is not enough, such as "Volume 40 percent".
  final String? semanticsLabel;
  final String? subtitle;

  /// Optional visual such as an app icon, shown before the text.
  final Widget? leading;
}
