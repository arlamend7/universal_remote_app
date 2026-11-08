import 'package:flutter/material.dart';

import 'app_sheet.dart';

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget child,
  bool scrollable = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  constraints: const BoxConstraints(maxWidth: 600),
  builder: (_) => AppSheet(
    title: title,
    subtitle: subtitle,
    scrollable: scrollable,
    child: child,
  ),
);
