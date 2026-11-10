import 'package:flutter/widgets.dart';

import 'reported_app_artwork_state.dart';

class ReportedAppArtwork extends StatefulWidget {
  const ReportedAppArtwork({
    super.key,
    required this.uri,
    required this.fallback,
  });

  final Uri uri;
  final Widget fallback;

  @override
  State<ReportedAppArtwork> createState() => ReportedAppArtworkState();
}
