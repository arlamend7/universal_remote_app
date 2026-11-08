import 'package:flutter/material.dart';

class ContentPage extends StatelessWidget {
  const ContentPage({super.key, required this.children, this.maxWidth = 760});
  final List<Widget> children;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Center(child: _content());
  Widget _content() => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: ListView(padding: const EdgeInsets.all(24), children: children),
  );
}
