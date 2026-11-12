import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';

import 'session_countdown.dart';
import 'session_time_sheet.dart';

class SessionTimeSheetState extends State<SessionTimeSheet> {
  String? _error;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: widget.session, builder: _sheet);

  Widget _sheet(BuildContext context, Widget? child) {
    final session = widget.session;
    final expired = session.expired;
    final nearEnd = session.warningDue || session.remaining.inSeconds <= 60;
    return AppSheet(
      title: expired
          ? 'Session ended'
          : nearEnd
          ? 'Session almost over'
          : 'Session time',
      heightFactor: .50,
      horizontalInset: 16,
      footer: _actions(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          SessionCountdown(session: session, builder: _clock),
          Text(
            expired
                ? 'You can still use your remote and connect to TVs. Watch an ad to add 30 minutes to your session.'
                : 'Watch a rewarded ad to add 30 minutes to your session.',
            textAlign: TextAlign.center,
          ),
          if (!session.canExtend && !session.requesting)
            const Text(
              'Extensions are available again after your balance falls to 30 minutes and the cooldown ends.',
              textAlign: TextAlign.center,
            ),
          if (_error case final error?)
            Text(error, textAlign: TextAlign.center),
          _privacyOptions(),
        ],
      ),
    );
  }

  Widget _clock(BuildContext context, String time) => Text(
    time,
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.displaySmall
        ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
  );

  Widget _actions() => AppSheetActions(
    secondary: OutlinedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Not now'),
    ),
    primary: FilledButton(
      onPressed: widget.session.canExtend ? _extend : null,
      child: Text(
        widget.session.requesting ? 'Loading ad…' : 'Watch ad · +30 min',
        textAlign: TextAlign.center,
      ),
    ),
  );

  Widget _privacyOptions() => ValueListenableBuilder(
    valueListenable: widget.session.privacyOptionsRequired,
    builder: (_, required, _) => required
        ? TextButton(
            onPressed: widget.session.requesting ? null : _openPrivacyOptions,
            child: const Text('Ad privacy options'),
          )
        : const SizedBox.shrink(),
  );

  Future<void> _openPrivacyOptions() async {
    try {
      await widget.session.showPrivacyOptions();
    } on Exception {
      if (mounted) {
        setState(
          () => _error = 'Ad privacy options are unavailable. Try again.',
        );
      }
    }
  }

  bool _canPresent() => mounted && ModalRoute.isCurrentOf(context) == true;

  Future<void> _extend() async {
    setState(() => _error = null);
    final earned = await widget.session.requestExtension(
      canPresent: _canPresent,
    );
    if (!_canPresent()) {
      return;
    }
    if (earned) {
      Navigator.pop(context);
      return;
    }
    setState(() => _error = 'No time was added. You can try again.');
  }
}
