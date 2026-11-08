import 'dart:convert';
import 'dart:io';

/// A fixed executable and argument list: no shell, administrator access or scan.
final class NeighborCommandRunner {
  Future<String?> read(String host) async {
    final process = await Process.start('/usr/sbin/arp', ['-n', host]);
    final output = process.stdout.transform(utf8.decoder).join();
    final errors = process.stderr.drain<void>();
    final code = await process.exitCode.timeout(
      const Duration(seconds: 1),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
    await errors;
    final text = await output;
    return code == 0 ? text : null;
  }
}
