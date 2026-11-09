import 'dart:async';

import '../device.dart';
import '../discovery.dart';
import '../errors/discovery_operation_failure.dart';
import 'discovery_status.dart';
import 'protocol_discovery_status.dart';
import 'device_identifier_resolver.dart';
import 'discovery_observation.dart';
import 'discovery_protocol.dart';
import 'discovery_registry.dart';
import 'provider_identifier.dart';
import 'provider_match.dart';

final class DiscoveryManager {
  DiscoveryManager(this.registry, Iterable<ProviderIdentifier> identifiers)
    : identifiers = List.unmodifiable(identifiers) {
    if (this.identifiers.map((identifier) => identifier.id).toSet().length !=
        this.identifiers.length) {
      throw ArgumentError('Discovery identifiers must be unique.');
    }
  }

  final DiscoveryRegistry registry;
  final List<ProviderIdentifier> identifiers;
  final _resolver = const DeviceIdentifierResolver();

  /// Emits a merged snapshot as each provider identifies or updates a device.
  Stream<List<RemoteDevice>> watch({
    Duration timeout = const Duration(seconds: 8),
    DiscoveryCancellation? cancellation,
    void Function(ProtocolDiscoveryStatus)? onStatus,
    void Function(DiscoveryObservation)? onUnresolved,
  }) => Stream.multi((stream) {
    final token = cancellation ?? DiscoveryCancellation();
    var finished = false;
    stream.onCancel = () {
      if (!finished) {
        token.cancel();
      }
    };
    unawaited(
      discover(
        timeout: timeout,
        cancellation: token,
        onDevices: stream.add,
        onStatus: onStatus,
        onUnresolved: onUnresolved,
      ).then(
        (_) {
          finished = true;
          stream.close();
        },
        onError: (Object error, StackTrace stack) {
          finished = true;
          stream.addError(error, stack);
          stream.close();
        },
      ),
    );
  });

  Future<DiscoveryResult> discover({
    Duration timeout = const Duration(seconds: 8),
    DiscoveryCancellation? cancellation,
    void Function(List<RemoteDevice>)? onDevices,
    void Function(ProtocolDiscoveryStatus)? onStatus,
    void Function(DiscoveryObservation)? onUnresolved,
  }) async {
    if (timeout <= Duration.zero) {
      throw ArgumentError('Discovery timeout must be positive.');
    }
    final parent = cancellation ?? DiscoveryCancellation();
    if (parent.isCancelled) {
      return DiscoveryResult([], []);
    }
    final matches = <ProviderMatch>[];
    void publish(ProviderMatch match) {
      if (matches.any(
        (other) =>
            other.profile.id == match.profile.id &&
            !_resolver.same(other.profile.device, match.profile.device),
      )) {
        onUnresolved?.call(match.evidence);
        return;
      }
      _resolver.add(matches, match);
      onDevices?.call(_devices(matches));
    }

    final reports = await Future.wait([
      for (final identifier in identifiers)
        for (final entry in identifier.requirements.targets.entries)
          for (final service
              in entry.value.map((value) => value.toLowerCase()).toSet())
            _search(
              identifier,
              entry.key,
              service,
              parent,
              timeout,
              publish,
              onStatus,
              onUnresolved,
            ),
    ]);
    return DiscoveryResult(reports, matches.map(_resolver.resolve));
  }

  List<RemoteDevice> _devices(List<ProviderMatch> matches) =>
      List.unmodifiable(matches.map((match) => match.profile.device));

  Future<ProtocolDiscoveryStatus> _search(
    ProviderIdentifier identifier,
    DiscoveryProtocol protocol,
    String service,
    DiscoveryCancellation parent,
    Duration timeout,
    void Function(ProviderMatch) publish,
    void Function(ProtocolDiscoveryStatus)? onStatus,
    void Function(DiscoveryObservation)? onUnresolved,
  ) async {
    final elapsed = Stopwatch()..start();
    final token = DiscoveryCancellation();
    final matches = <ProviderMatch>[];
    DiscoveryFailure? failure;
    onStatus?.call(
      ProtocolDiscoveryStatus(
        protocolId: protocol,
        provider: identifier.identity,
        providerId: identifier.id,
        serviceType: service,
        status: DiscoveryStatus.searching,
      ),
    );
    final scan = _scan(protocol, service, token, (observation) async {
      final ProviderMatch? match;
      try {
        match = await _identify(identifier, observation, token);
      } catch (error) {
        token.record('identifier.failed');
        failure ??= DiscoveryFailure(
          protocol,
          DiscoveryOperationFailure(
            'identify',
            error,
            code: 'identificationFailed',
          ),
        );
        return;
      }
      if (parent.isCancelled || token.isCancelled) {
        return;
      }
      if (match == null) {
        token.record('observation.unresolved');
        onUnresolved?.call(observation);
        return;
      }
      _resolver.add(matches, match);
      publish(match);
    });
    try {
      await Future.any([scan.timeout(timeout), parent.whenCancelled]);
    } catch (error) {
      failure = DiscoveryFailure(protocol, error);
    } finally {
      token.cancel();
      await _waitForCleanup(scan);
    }
    final report = ProtocolDiscoveryStatus(
      protocolId: protocol,
      provider: identifier.identity,
      providerId: identifier.id,
      serviceType: service,
      status: _status(parent.isCancelled, matches.length, failure),
      duration: elapsed.elapsed,
      deviceCount: matches.length,
      failure: parent.isCancelled ? null : failure,
      observations: token.observations,
    );
    onStatus?.call(report);
    return report;
  }

  Future<void> _waitForCleanup(Future<void> scan) async {
    try {
      await scan.timeout(const Duration(milliseconds: 500));
    } catch (_) {
      // A broken adapter cannot hold the search or network lock indefinitely.
    }
  }

  Future<void> _scan(
    DiscoveryProtocol protocol,
    String service,
    DiscoveryCancellation token,
    Future<void> Function(DiscoveryObservation) observe,
  ) async {
    final search = registry[protocol];
    if (search == null) {
      throw const DiscoveryOperationFailure(
        'protocol.start',
        'Protocol unavailable',
        code: 'discoveryUnavailable',
      );
    }
    await search(service, token, observe);
  }

  Future<ProviderMatch?> _identify(
    ProviderIdentifier identifier,
    DiscoveryObservation observation,
    DiscoveryCancellation token,
  ) async {
    if (token.isCancelled) {
      return null;
    }
    token.record('observation.received');
    final match = await identifier.identify(observation, token);
    if (match == null ||
        !match.confirmed ||
        match.providerId != identifier.id) {
      return null;
    }
    return match;
  }

  DiscoveryStatus _status(
    bool cancelled,
    int count,
    DiscoveryFailure? failure,
  ) {
    if (cancelled) {
      return DiscoveryStatus.cancelled;
    }
    if (failure != null) {
      return count == 0
          ? DiscoveryStatus.failed
          : DiscoveryStatus.partialSuccess;
    }
    return count == 0 ? DiscoveryStatus.empty : DiscoveryStatus.success;
  }
}
