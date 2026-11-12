import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/network/services/preparation_network.dart';
import 'offline_network_page.dart';
import 'startup_network_prompt.dart';

class StartupNetworkPromptState extends State<StartupNetworkPrompt> {
  Timer? _retryTimer;
  BuildContext? _promptContext;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_checkOnLaunch());
      }
    });
  }

  Future<void> _checkOnLaunch() async {
    final network = await readPreparationNetwork(includeName: false);
    if (!mounted || network.transport != 'offline') {
      return;
    }
    final prompt = showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      transitionDuration: Duration.zero,
      pageBuilder: _page,
    );
    _retryTimer = Timer.periodic(const Duration(seconds: 2), (_) => _retry());
    try {
      await prompt;
    } finally {
      _stopChecking();
    }
  }

  Widget _page(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    _promptContext = context;
    return PopScope(
      canPop: false,
      child: OfflineNetworkPage(
        onRetry: _retry,
        onContinueOffline: _dismissPrompt,
      ),
    );
  }

  Future<void> _retry() async {
    if (_checking || !mounted) {
      return;
    }
    _checking = true;
    final network = await readPreparationNetwork(includeName: false);
    _checking = false;
    if (network.transport == 'wifi' || network.transport == 'ethernet') {
      _dismissPrompt();
    }
  }

  void _dismissPrompt() {
    final prompt = _promptContext;
    if (prompt == null ||
        !prompt.mounted ||
        ModalRoute.of(prompt)?.isCurrent != true) {
      return;
    }
    _stopChecking();
    Navigator.pop(prompt);
  }

  void _stopChecking() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _promptContext = null;
  }

  @override
  void dispose() {
    _stopChecking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
