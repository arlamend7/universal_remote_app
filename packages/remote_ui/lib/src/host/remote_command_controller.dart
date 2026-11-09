import 'package:flutter/foundation.dart';
import 'package:remote_core/remote_core.dart';

import '../feedback/remote_feedback.dart';
import 'volume_observer.dart';

final class RemoteCommandController {
  RemoteCommandController({
    required this.onFailure,
    required this.volume,
    required this.error,
    required this.generation,
    required this.onUpdated,
  });
  final void Function(String code) onFailure;
  final VolumeObserver volume;
  final ValueNotifier<String?> error;
  final int Function() generation;
  final void Function() onUpdated;
  final busy = ValueNotifier(false);
  bool _disposed = false;
  Future<void> execute(
    Future<void> Function() command, {
    bool refreshVolume = false,
  }) async {
    if (_disposed || busy.value) {
      return;
    }
    final current = generation();
    busy.value = true;
    error.value = null;
    try {
      await command();
      if (refreshVolume) {
        await _refresh(current);
      }
    } catch (exception) {
      _failed(exception, current);
      if (refreshVolume) {
        await _refresh(current);
      }
    } finally {
      _finished();
    }
  }

  Future<void> _refresh(int current) async {
    if (_disposed || current != generation()) {
      return;
    }
    await volume.refresh();
  }

  void _failed(Object exception, int current) {
    if (_disposed || current != generation()) {
      return;
    }
    error.value = exception is RemoteException
        ? exception.message
        : 'The operation failed. Please try again.';
    RemoteFeedback.failure();
    onUpdated();
    onFailure(exception is RemoteException ? exception.code : 'unknown');
  }

  void _finished() {
    if (_disposed) {
      return;
    }
    busy.value = false;
  }

  void dispose() {
    _disposed = true;
    busy.dispose();
  }
}
