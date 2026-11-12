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
    spacing: 12,
    children: [
      Text(model.status, style: Theme.of(context).textTheme.titleMedium),
      Text(
        model.offline
            ? model.statusExplanation
            : model.error ?? 'The TV is connected.',
      ),
      if (model.canReviewCertificate)
        FilledButton(
          onPressed: model.busy ? null : () => _review(context),
          child: const Text('Review TV certificate and pair'),
        ),
      if (model.offline) _retryAction(context),
      if (model.offline)
        OutlinedButton(
          onPressed: model.busy ? null : () => _edit(context),
          child: const Text('Connection settings'),
        ),
    ],
  );

  Widget _retryAction(BuildContext context) {
    final retry = model.busy ? null : () => _connect(context);
    const label = Text('Retry connection');
    if (model.canReviewCertificate) {
      return OutlinedButton(onPressed: retry, child: label);
    }
    return FilledButton(onPressed: retry, child: label);
  }

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
