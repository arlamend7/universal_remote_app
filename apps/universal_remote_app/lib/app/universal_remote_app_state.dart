import 'dart:async';

import 'package:flutter/material.dart';

import '../routes/app_routes.dart';
import '../shared/themes/app_themes.dart';
import 'universal_remote_app.dart';

class UniversalRemoteAppState extends State<UniversalRemoteApp>
    with WidgetsBindingObserver {
  late final AppRoutes routes;
  @override
  void initState() {
    super.initState();
    routes = AppRoutes(widget.dependencies);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _cancelBackgroundDiscovery(state);
    unawaited(widget.dependencies.connection.lifecycle(state));
  }

  void _cancelBackgroundDiscovery(AppLifecycleState state) {
    if (state != AppLifecycleState.paused &&
        state != AppLifecycleState.hidden) {
      return;
    }
    widget.dependencies.discovery.cancel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routes.dispose();
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([
      widget.dependencies.settings.theme,
      widget.dependencies.settings.accent,
    ]),
    builder: _application,
  );
  Widget _application(BuildContext context, Widget? child) {
    final settings = widget.dependencies.settings;
    final accent = settings.accent.value;
    return MaterialApp.router(
      title: 'Universal Remote',
      debugShowCheckedModeBanner: false,
      themeMode: settings.theme.value,
      theme: AppThemes.build(Brightness.light, accent),
      darkTheme: AppThemes.build(Brightness.dark, accent),
      routerConfig: routes.router.config,
    );
  }
}
