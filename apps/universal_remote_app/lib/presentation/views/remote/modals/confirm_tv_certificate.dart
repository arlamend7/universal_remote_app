import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';
import 'package:remote_ui/remote_ui.dart';

import 'certificate_review_dialog.dart';

Future<bool> confirmTvCertificate(
  BuildContext context,
  RemoteDevice device,
  PeerCertificate certificate, {
  required bool replacing,
}) async =>
    await showAppModal<bool>(
      context,
      builder: (_) => CertificateReviewDialog(
        device: device,
        certificate: certificate,
        replacing: replacing,
      ),
    ) ??
    false;
