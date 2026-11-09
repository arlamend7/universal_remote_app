import 'package:flutter/material.dart';

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({super.key, required this.retry});
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => MaterialApp(home: _page());
  Widget _page() => Scaffold(body: Center(child: _content()));
  Widget _content() =>
      Padding(padding: const EdgeInsets.all(32), child: _message());
  Widget _message() => Column(
    mainAxisSize: MainAxisSize.min,
    spacing: 16,
    children: [
      const Icon(Icons.lock_outline, size: 48),
      const Text(
        'App settings could not be loaded. Close and reopen the app, then retry.',
      ),
      FilledButton(onPressed: retry, child: const Text('Retry')),
    ],
  );
}
