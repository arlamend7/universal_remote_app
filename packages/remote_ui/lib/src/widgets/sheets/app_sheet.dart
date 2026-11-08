import 'package:flutter/material.dart';

class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.scrollable = true,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final bool scrollable;
  @override
  Widget build(BuildContext context) => SafeArea(child: _insets(context));
  Widget _insets(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: _surface(context),
  );
  Widget _surface(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .88,
      maxWidth: 600,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(context),
        Flexible(child: _body()),
      ],
    ),
  );
  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 12, 8),
    child: Row(
      children: [
        Expanded(child: _heading(context)),
        IconButton(
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    ),
  );
  Widget _heading(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (subtitle != null)
        Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
  Widget _body() {
    if (!scrollable) {
      return child;
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: child,
    );
  }
}
