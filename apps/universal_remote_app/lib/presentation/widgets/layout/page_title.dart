import 'package:flutter/material.dart';

class PageTitle extends StatelessWidget {
  const PageTitle({super.key, required this.title, this.leading});

  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: leading ?? const SizedBox.shrink()),
      Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontSize: 18),
        ),
      ),
      const Spacer(),
    ],
  );
}
