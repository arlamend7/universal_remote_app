import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domains/session/services/active_session.dart';
import 'enums/countdown_precision.dart';
import 'session_countdown_state.dart';

class SessionCountdown extends StatefulWidget {
  const SessionCountdown({
    super.key,
    required this.session,
    required this.builder,
    this.visible,
    this.precision = CountdownPrecision.minutes,
  });

  final ActiveSession session;
  final ValueListenable<bool>? visible;
  final CountdownPrecision precision;
  final Widget Function(BuildContext, String) builder;

  @override
  State<SessionCountdown> createState() => SessionCountdownState();
}
