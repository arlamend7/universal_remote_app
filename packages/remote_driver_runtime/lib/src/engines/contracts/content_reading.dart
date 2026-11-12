import 'package:remote_core/remote_core.dart';

/// Current content plus the input it implies, when the protocol reveals one.
final class ContentReading {
  const ContentReading(this.content, {this.input, this.reportsInput = false});

  final CurrentContent content;
  final DeviceInput? input;

  /// True when [input] is authoritative (null means "not an input").
  final bool reportsInput;
}
