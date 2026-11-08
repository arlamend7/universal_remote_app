import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import '../../remote/viewmodels/remote_viewmodel.dart';

class PairingProgressCard extends StatelessWidget {
  const PairingProgressCard({super.key, required this.model});
  final RemoteViewModel model;
  String get _title => switch (model.state) {
    DeviceConnectionState.pairing => 'Approve the connection on your TV',
    DeviceConnectionState.reconnecting => 'Waiting for your TV to start…',
    _ => 'Connecting securely…',
  };
  @override
  Widget build(BuildContext context) => SafeArea(child: _scroll(context));
  Widget _scroll(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(28),
    child: _body(context),
  );
  Widget _body(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.tv_outlined, size: 40),
      const SizedBox(height: 20),
      const SizedBox.square(
        dimension: 28,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      const SizedBox(height: 24),
      Text(
        _title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 12),
      Text(
        model.state == DeviceConnectionState.reconnecting
            ? 'The remote will connect automatically when the TV is ready.'
            : 'Keep the TV on and accept its connection request.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 20),
      TextButton(
        onPressed: model.disconnect,
        child: const Text('Cancel connection'),
      ),
    ],
  );
}
