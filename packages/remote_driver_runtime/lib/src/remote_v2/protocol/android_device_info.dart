import 'dart:convert';

import 'wire_message.dart';

/// The device information the TV reports in its Remote v2 configure message
/// (`RemoteDeviceInfo`: model 1, vendor 2, package 5, app version 6).
///
/// Values are untrusted: each is decoded leniently, trimmed, stripped of
/// control characters and bounded. A missing or unusable value stays null —
/// nothing is inferred from another field.
final class AndroidDeviceInfo {
  const AndroidDeviceInfo({
    this.model,
    this.vendor,
    this.packageName,
    this.appVersion,
  });

  static const maximumLength = 100;

  final String? model;
  final String? vendor;
  final String? packageName;
  final String? appVersion;

  static AndroidDeviceInfo? parse(Object? payload) {
    if (payload is! List<int>) {
      return null;
    }
    final Map<int, Object> fields;
    try {
      fields = WireMessage.decode(payload);
    } on FormatException {
      return null;
    }
    final info = AndroidDeviceInfo(
      model: _text(fields[1]),
      vendor: _text(fields[2]),
      packageName: _text(fields[5]),
      appVersion: _text(fields[6]),
    );
    return info.isEmpty ? null : info;
  }

  bool get isEmpty =>
      model == null &&
      vendor == null &&
      packageName == null &&
      appVersion == null;

  static String? _text(Object? value) {
    if (value is! List<int> || value.length > maximumLength * 4) {
      return null;
    }
    final decoded = utf8
        .decode(value, allowMalformed: true)
        .replaceAll(RegExp(r'[\u0000-\u001f\u007f�]'), '')
        .trim();
    if (decoded.isEmpty) {
      return null;
    }
    return decoded.length > maximumLength
        ? decoded.substring(0, maximumLength)
        : decoded;
  }
}
