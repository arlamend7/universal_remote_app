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
    this.heightFactor = .88,
    this.horizontalInset = 24,
    this.centerTitle = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onClose;
  final String closeLabel;
  final bool scrollable;
  final double heightFactor;
  final double horizontalInset;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: _surface(context),
    ),
  );

  Widget _surface(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * heightFactor,
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
    padding: EdgeInsetsDirectional.fromSTEB(
      horizontalInset,
      4,
      horizontalInset,
      8,
    ),
    child: centerTitle
        ? _centeredHeadingRow(context)
        : Row(
            children: [
              Expanded(child: _heading(context)),
              _closeButton(context),
            ],
          ),
  );

  Widget _centeredHeadingRow(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: _heading(context),
      ),
      Align(
        alignment: AlignmentDirectional.centerEnd,
        child: _closeButton(context),
      ),
    ],
  );

  Widget _closeButton(BuildContext context) => IconButton.filledTonal(
    tooltip: closeLabel,
    onPressed: onClose ?? () => Navigator.pop(context),
    icon: const Icon(Icons.close, size: 20),
  );

  Widget _heading(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: centerTitle
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.titleLarge,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            textAlign: centerTitle ? TextAlign.center : TextAlign.start,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }

  Widget _body() => Padding(
    padding: EdgeInsets.fromLTRB(
      horizontalInset,
      8,
      horizontalInset,
      footer == null ? 24 : 14,
    ),
    child: child,
  );

  Widget _footer() => Padding(
    padding: EdgeInsets.fromLTRB(horizontalInset, 0, horizontalInset, 16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [footer!],
    ),
  );
}
