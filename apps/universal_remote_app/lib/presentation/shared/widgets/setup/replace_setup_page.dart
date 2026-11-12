import 'package:flutter/material.dart';

/// Replaces the current setup step, so Back skips it.
Future<T?> replaceSetupPage<T>(BuildContext context, Widget page) =>
    Navigator.of(
      context,
    ).pushReplacement<T, Object?>(MaterialPageRoute<T>(builder: (_) => page));
