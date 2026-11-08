import 'package:flutter/material.dart';

import '../viewmodels/remote_viewmodel.dart';

class RemoteStatusContent extends StatelessWidget {
  const RemoteStatusContent({
    super.key,
    required this.model,
    required this.onReviewCertificate,
    required this.onEdit,
  });
  final RemoteViewModel model;
  final Future<void> Function() onReviewCertificate, onEdit;
  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: model.sessionChanges, builder: _body);
  Widget _body(BuildContext context, Widget? child) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(model.status, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      Text(
        model.offline
            ? model.statusExplanation
            : model.error ?? 'The TV is connected.',
      ),
      const SizedBox(height: 20),
      if (model.canReviewCertificate)
        FilledButton(
          onPressed: model.busy ? null : () => _review(context),
          child: const Text('Review TV certificate and pair'),
        ),
      if (model.offline)
        FilledButton(
          onPressed: model.busy ? null : () => _connect(context),
          child: const Text('Retry connection'),
        ),
      if (model.offline)
        TextButton(
          onPressed: model.busy ? null : () => _edit(context),
          child: const Text('Connection settings'),
        ),
    ],
  );
  void _review(BuildContext context) {
    Navigator.pop(context);
    onReviewCertificate();
  }

  void _edit(BuildContext context) {
    Navigator.pop(context);
    onEdit();
  }

  void _connect(BuildContext context) {
    Navigator.pop(context);
    model.retry();
  }
}
