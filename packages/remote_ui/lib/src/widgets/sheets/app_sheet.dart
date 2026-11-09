import 'package:flutter/material.dart';

class AppSheet extends StatelessWidget {
  const AppSheet({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.onClose,
    this.closeLabel = 'Close',
    this.scrollable = true,
  });

  static const _horizontalInset = 24.0;

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onClose;
  final String closeLabel;
  final bool scrollable;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _surface(context),
    ),
  );

  Widget _surface(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .88,
      maxWidth: 600,
    ),
    child: LayoutBuilder(builder: _layout),
  );

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    if (scrollable && constraints.maxHeight < 260) {
      return SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [_header(context), _body(), if (footer != null) _footer()],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context),
        Flexible(
          child: scrollable ? SingleChildScrollView(child: _body()) : _body(),
        ),
        if (footer != null) _footer(),
      ],
    );
  }

  Widget _header(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [_handle(context), _headingRow(context)],
  );

  Widget _handle(BuildContext context) => Container(
    width: 40,
    height: 4,
    margin: const EdgeInsets.only(top: 10, bottom: 4),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.onSurfaceVariant
          .withValues(alpha: .30),
      borderRadius: BorderRadius.circular(4),
    ),
  );

  Widget _headingRow(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(
      _horizontalInset,
      4,
      _horizontalInset,
      8,
    ),
    child: Row(
      children: [
        Expanded(child: _heading(context)),
        IconButton.filledTonal(
          tooltip: closeLabel,
          onPressed: onClose ?? () => Navigator.pop(context),
          icon: const Icon(Icons.close, size: 20),
        ),
      ],
    ),
  );

  Widget _heading(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.titleLarge),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _body() => Padding(
    padding: EdgeInsets.fromLTRB(
      _horizontalInset,
      8,
      _horizontalInset,
      footer == null ? 24 : 14,
    ),
    child: child,
  );

  Widget _footer() => Padding(
    padding: const EdgeInsets.fromLTRB(
      _horizontalInset,
      0,
      _horizontalInset,
      16,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [footer!],
    ),
  );
}
