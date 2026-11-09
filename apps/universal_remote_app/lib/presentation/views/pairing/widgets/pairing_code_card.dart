import 'package:flutter/material.dart';
import 'package:remote_core/remote_core.dart';

import 'pairing_code_card_state.dart';

class PairingCodeCard extends StatefulWidget {
  const PairingCodeCard({
    super.key,
    required this.receiver,
    required this.deviceName,
    required this.onCancel,
  });

  final PairingCodeReceiver receiver;
  final String deviceName;
  final VoidCallback onCancel;

  @override
  State<PairingCodeCard> createState() => PairingCodeCardState();
}
