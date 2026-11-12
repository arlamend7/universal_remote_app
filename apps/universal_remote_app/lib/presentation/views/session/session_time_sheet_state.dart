import 'package:flutter/material.dart';
import 'package:remote_ui/remote_ui.dart';

import '../../../domains/session/services/active_session.dart';
import 'session_countdown.dart';
import 'session_reward_highlight.dart';
import 'session_time_sheet.dart';

class SessionTimeSheetState extends State<SessionTimeSheet> {
  String? _error;
  static final _rewardDuration = '${ActiveSession.extension.inHours} hours';
  static final _interstitialMinutes =
      ActiveSession.interstitialInterval.inMinutes;

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: widget.session, builder: _sheet);

  Widget _sheet(BuildContext context, Widget? child) {
    final session = widget.session;
    final expired = session.expired;
    final nearEnd = session.warningDue || session.remaining.inSeconds <= 60;
    return AppSheet(
      title: nearEnd && !expired ? 'Ad-free time almost over' : 'Ad-free Pass',
      centerTitle: true,
      heightFactor: .65,
      horizontalInset: 16,
      footer: _footer(context),
      child: _body(context),
    );
  }

  Widget _body(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 12,
    children: [
      widget.session.expired
          ? SessionRewardHighlight(duration: _rewardDuration)
          : SessionCountdown(session: widget.session, builder: _clock),
      _statusCard(
        context,
        icon: Icons.ondemand_video_outlined,
        title: 'Fewer interruptions',
        description:
            'Full-screen ads may appear every $_interstitialMinutes minutes of active app use. ',
      ),
      _statusCard(
        context,
        icon: Icons.settings_remote,
        title: 'Your remote always works',
        description: 'Keep controlling your TV and connecting devices.',
      ),
    ],
  );

  Widget _clock(BuildContext context, String time) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          'AD-FREE TIME LEFT',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          time,
          style: theme.textTheme.displayMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }

  Widget _statusCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.primary,
          child: Icon(icon),
        ),
        title: Text(title),
        titleTextStyle: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        subtitle: Text(description),
      ),
    );
  }

  Widget _footer(BuildContext context) {
    final theme = Theme.of(context);
    final session = widget.session;
    final message = !session.canExtend && !session.requesting
        ? 'You can renew during the final minute.'
        : 'Watch one ad now and enjoy $_rewardDuration without automatic full-screen ads.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        //_rewardNote(theme, message),
        if (_error case final error?) Text(error, textAlign: TextAlign.center),
        _actions(),
        _privacyOptions(),
      ],
    );
  }

  Widget _rewardNote(ThemeData theme, String message) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    spacing: 8,
    children: [
      Icon(Icons.more_time, size: 18, color: theme.colorScheme.primary),
      Flexible(
        child: Text(
          message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );

  Widget _actions() => AppSheetActions(
    secondary: OutlinedButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Not now'),
    ),
    primary: FilledButton.icon(
      onPressed: widget.session.canExtend ? _extend : null,
      icon: const Icon(Icons.play_arrow_rounded),
      label: Text(
        widget.session.requesting ? 'Loading ad…' : 'Watch ad',
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
    setState(() => _error = 'No ad-free time was added. You can try again.');
  }
}
