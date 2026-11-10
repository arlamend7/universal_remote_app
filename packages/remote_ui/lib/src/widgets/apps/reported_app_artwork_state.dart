import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'load_tv_artwork.dart';
import 'reported_app_artwork.dart';

class ReportedAppArtworkState extends State<ReportedAppArtwork> {
  late final _bytes = loadTvArtwork(widget.uri);

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List?>(
    future: _bytes,
    builder: (_, snapshot) {
      final bytes = snapshot.data;
      if (bytes == null || bytes.isEmpty) {
        return widget.fallback;
      }
      return Image.memory(
        bytes,
        width: 36,
        height: 36,
        cacheWidth: 96,
        cacheHeight: 96,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => widget.fallback,
      );
    },
  );
}
