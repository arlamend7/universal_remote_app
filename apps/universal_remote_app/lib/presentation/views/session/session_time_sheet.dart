import 'package:flutter/material.dart';

import '../../../domains/session/services/active_session.dart';
import 'session_time_sheet_state.dart';

class SessionTimeSheet extends StatefulWidget {
  const SessionTimeSheet({super.key, required this.session});

  final ActiveSession session;

  @override
  State<SessionTimeSheet> createState() => SessionTimeSheetState();
}
