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
          children: [content, if (footer != null) footer],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: SingleChildScrollView(child: content)),
        if (footer != null) footer,
      ],
    );
  }

  Widget _content(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SetupStepHeader(
        step: step,
        title: title,
        subtitle: subtitle,
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
    final secondaryStyle =
        (theme.outlinedButtonTheme.style ?? const ButtonStyle()).copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return null;
            }
            return colors.surfaceContainerHigh;
          }),
        );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              if (action != null)
                OutlinedButtonTheme(
                  data: OutlinedButtonThemeData(style: secondaryStyle),
                  child: AppSheetActions(primary: action, secondary: secondary),
                ),
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
