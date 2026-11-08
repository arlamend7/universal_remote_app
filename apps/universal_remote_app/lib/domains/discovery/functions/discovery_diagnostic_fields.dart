import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

Map<String, Object> discoveryDiagnosticFields(ProviderDiscoveryStatus report) {
  final error = report.failure?.error;
  final osCode = error is SocketException ? error.osError?.errorCode : null;
  return {
    'providerId': report.providerId,
    'status': report.status.name,
    'durationMs': report.duration.inMilliseconds,
    'deviceCount': report.deviceCount,
    if (report.observations.isNotEmpty) 'observations': report.observations,
    if (error != null) 'exceptionType': _exceptionType(error),
    'stage': error is SsdpSocketFailure ? error.stage : 'discover',
    if (error != null) 'code': _failureCode(error, osCode),
    if (osCode != null) 'osCode': osCode,
  };
}

String _exceptionType(Object error) =>
    (error is SsdpSocketFailure ? error.cause : error).runtimeType.toString();

String _failureCode(Object error, int? osCode) => switch (error) {
  TimeoutException() => 'responseTimeout',
  SocketException() when osCode == 1 || osCode == 13 => 'networkBlocked',
  SocketException() when const {51, 65, 101, 113}.contains(osCode) =>
    'networkUnreachable',
  SsdpSocketFailure(stage: 'noInterface') => 'noNetworkInterface',
  SsdpSocketFailure(stage: 'interface') => 'multicastInterfaceFailed',
  SsdpSocketFailure(stage: 'bind') => 'socketBindFailed',
  SsdpSocketFailure(stage: 'send') => 'multicastSendFailed',
  SsdpSocketFailure(stage: 'receive') => 'socketReceiveFailed',
  SocketException() => 'socketFailure',
  _ => 'providerException',
};
