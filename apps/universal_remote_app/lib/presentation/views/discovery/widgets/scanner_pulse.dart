import 'package:flutter/material.dart';

import 'scanner_pulse_state.dart';

/// A dot with an expanding ring, shown while the network scan runs.
class ScannerPulse extends StatefulWidget {
  const ScannerPulse({super.key, this.size = 28});

  final double size;

  @override
  State<ScannerPulse> createState() => ScannerPulseState();
}
