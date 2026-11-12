import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';

import 'setup_step_header.dart';

class SetupStepPage extends StatelessWidget {
  const SetupStepPage({
    super.key,
    required this.step,
    required this.title,
    required this.body,
    this.subtitle,
    this.onBack,
    this.showBack = true,
    this.bodyPadding = const EdgeInsets.all(20),
    this.primary,
    this.secondary,
    this.footerLink,
    this.banner,
    this.headerAction,
    this.floating,
  });

  final int step;
  final String title;
  final Widget body;
  final String? subtitle;
  final VoidCallback? onBack;
  final bool showBack;
  final EdgeInsetsGeometry bodyPadding;
  final Widget? primary;
  final Widget? secondary;
  final Widget? footerLink;
  final Widget? banner;
  final Widget? headerAction;

  /// Status shown above the footer, over the bottom of the scrolling body.
  final Widget? floating;

  static const _floatingClearance = 88.0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(builder: _layout),
        ),
      ),
    ),
  );

  Widget _layout(BuildContext context, BoxConstraints constraints) {
    final footer = _footer(context);
    final content = _content(context);
    if (constraints.maxHeight < 420 ||
        MediaQuery.textScalerOf(context).scale(16) > 24) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            content,
            if (floating != null) _floatingStatus(),
            if (footer != null) footer,
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _scrollingBody(content)),
        if (footer != null) footer,
      ],
    );
  }

  Widget _scrollingBody(Widget content) => Stack(
    children: [
      Positioned.fill(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: floating == null ? 0 : _floatingClearance,
          ),
          child: content,
        ),
      ),
      Positioned(left: 0, right: 0, bottom: 0, child: _floatingStatus()),
    ],
  );

  Widget _floatingStatus() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: _slideIn,
      child: floating ?? const SizedBox.shrink(),
    ),
  );

  static Widget _slideIn(Widget child, Animation<double> animation) =>
      FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, .25),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );

  Widget _content(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SetupStepHeader(
        step: step,
        title: title,
        subtitle: subtitle,
        action: headerAction,
        onBack: showBack ? onBack ?? () => Navigator.maybePop(context) : null,
      ),
      if (banner != null) banner!,
      Padding(padding: bodyPadding, child: body),
    ],
  );

  Widget? _footer(BuildContext context) {
    final action = primary;
    if (action == null && footerLink == null) {
      return null;
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              if (action != null)
                AppSheetActions(primary: action, secondary: secondary),
              if (footerLink != null)
                TextButtonTheme(
                  data: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurfaceVariant,
                      textStyle: theme.textTheme.labelMedium?.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  child: Center(child: footerLink!),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
