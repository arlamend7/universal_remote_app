import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

import 'certificate_review_dialog.dart';

Future<bool> confirmTvCertificate(
  BuildContext context,
  RemoteDevice device,
  PeerCertificate certificate, {
  required bool replacing,
}) async =>
    await showDialog<bool>(
      context: context,
      builder: (_) => CertificateReviewDialog(
        device: device,
        certificate: certificate,
        replacing: replacing,
      ),
    ) ??
    false;
