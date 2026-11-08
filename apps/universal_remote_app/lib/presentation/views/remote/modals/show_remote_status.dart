import 'package:flutter/material.dart';

import 'package:remote_ui/remote_ui.dart';

import '../viewmodels/remote_viewmodel.dart';
import '../widgets/remote_status_content.dart';

Future<void> showRemoteStatus(BuildContext context, RemoteViewModel model) =>
    showAppSheet<void>(
      context,
      title: 'Device connection',
      child: RemoteStatusContent(
        model: model,
        onReviewCertificate: () => model.reviewCertificate(context),
        onEdit: () => model.edit(context),
      ),
    );
