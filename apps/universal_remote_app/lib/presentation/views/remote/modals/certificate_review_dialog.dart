import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

class CertificateReviewDialog extends StatelessWidget {
  const CertificateReviewDialog({
    super.key,
    required this.device,
    required this.certificate,
    required this.replacing,
  });
  final RemoteDevice device;
  final PeerCertificate certificate;
  final bool replacing;
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      replacing ? 'The TV certificate has changed' : 'Trust this TV?',
    ),
    content: _content(),
    actions: _actions(context),
  );
  Widget _content() =>
      SizedBox(width: 400, child: SingleChildScrollView(child: _details()));
  Widget _details() => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('${device.name} · ${device.endpoints.first.host}'),
      const SizedBox(height: 16),
      const Text(
        'Confirm this address on your TV. Continue only on a trusted network; the certificate alone does not prove TV identity.',
      ),
      if (replacing)
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            'An unexpected change may indicate a different device. Cancel unless you can verify it.',
          ),
        ),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Certificate details'),
        children: [
          SelectableText(
            '${certificate.subject}\n\nFingerprint (SHA-1):\n${certificate.fingerprint}\n\nCompare through a trusted source when available. Approval remembers this exact certificate for this TV; pairing still needs approval on the TV.',
          ),
        ],
      ),
    ],
  );
  List<Widget> _actions(BuildContext context) => [
    TextButton(
      onPressed: () => Navigator.pop(context, false),
      child: const Text('Cancel'),
    ),
    FilledButton(
      onPressed: () => Navigator.pop(context, true),
      child: Text(
        replacing ? 'Replace certificate and pair' : 'Trust and pair',
      ),
    ),
  ];
}
