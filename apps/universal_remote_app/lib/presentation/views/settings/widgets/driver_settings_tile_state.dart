import 'package:flutter/material.dart';

import 'driver_settings_tile.dart';

class DriverSettingsTileState extends State<DriverSettingsTile> {
  bool _installing = false;
  bool _completed = false;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
    valueListenable: widget.model.dependencies.driverUpdatesAvailable,
    builder: _tile,
  );

  Widget _tile(BuildContext context, bool available, Widget? child) => ListTile(
    leading: widget.icon,
    title: const Text('Drivers'),
    subtitle: _installing || _completed || available ? Text(_status()) : null,
    trailing: AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _indicator(available),
    ),
    onTap: _installing || _completed
        ? null
        : available
        ? _install
        : () => widget.openExplorer(context),
  );

  String _status() {
    if (_installing) {
      return 'Downloading updates…';
    }
    return _completed ? 'Updates downloaded' : 'Updates available';
  }

  Widget _indicator(bool available) {
    if (_installing) {
      return const SizedBox.square(
        key: ValueKey('downloading'),
        dimension: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final icon = _completed
        ? Icons.check
        : available
        ? Icons.download_outlined
        : Icons.chevron_right;
    return Icon(
      icon,
      key: ValueKey(icon),
      color: _completed || available
          ? Theme.of(context).colorScheme.primary
          : null,
    );
  }

  Future<void> _install() async {
    if (_installing || _completed) {
      return;
    }
    setState(() => _installing = true);
    final (completed, message) = await widget.model.installDriverUpdates();
    if (!mounted) {
      return;
    }
    setState(() {
      _completed = completed;
      _installing = false;
    });
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
    if (!completed) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (mounted) {
      setState(() => _completed = false);
    }
  }
}
