import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const writeDesignPreviews = bool.fromEnvironment('WRITE_DESIGN_PREVIEWS');

Future<void> loadDesignFont() async {
  if (!writeDesignPreviews) {
    return;
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  final font = File('/System/Library/Fonts/Supplemental/Arial.ttf');
  if (!await font.exists()) {
    return;
  }
  final loader = FontLoader('Roboto')
    ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
  await loader.load();
}

Future<void> captureDesign(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!writeDesignPreviews) {
    return;
  }
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = Directory('../../artifacts/design/implemented-v1');
    await directory.create(recursive: true);
    await File('${directory.path}/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
