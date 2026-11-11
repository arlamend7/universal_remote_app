import 'dart:convert';
import 'dart:io';

import 'package:remote_driver_runtime/remote_driver_runtime.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length != 2 || arguments.first != '--enable-local-drivers') {
    stderr.writeln('Usage: validate_driver --enable-local-drivers DIRECTORY');
    exitCode = 64;
    return;
  }
  try {
    const source = LocalDriverSource(enabled: true);
    final files = await source.files(Directory(arguments.last));
    final bundle = DriverBundle.parse(files);
    stdout.writeln(
      jsonEncode({'manifest': bundle.manifest.toJson(), 'files': files}),
    );
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 65;
  } on FileSystemException {
    stderr.writeln('Unable to read the driver directory.');
    exitCode = 66;
  }
}
