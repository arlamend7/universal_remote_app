import 'package:flutter/material.dart';

import 'app_sheet.dart';

Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Widget child,
  bool scrollable = true,
  Widget? footer,
}) => showAppModal<T>(
  context,
  builder: (_) => AppSheet(
    title: title,
    subtitle: subtitle,
    scrollable: scrollable,
    footer: footer,
    child: child,
  ),
);

/// Presents stateful sheet content with the standard app modal route.
Future<T?> showAppModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxWidth = 600,
  Color? backgroundColor,
  bool isDismissible = true,
  bool enableDrag = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  backgroundColor: backgroundColor,
  useSafeArea: true,
  constraints: BoxConstraints(maxWidth: maxWidth),
  isDismissible: isDismissible,
  enableDrag: enableDrag,
  builder: builder,
);
