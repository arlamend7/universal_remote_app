import 'dart:async';
import 'dart:io';

import 'package:remote_core/remote_core.dart';
import 'package:remote_network/remote_network.dart';

Map<String, Object> discoveryDiagnosticFields(ProtocolDiscoveryStatus report) {
  final error = report.failure?.error;
  final osCode = discoveryOsCode(error);
  final operation = error is DiscoveryOperationFailure ? error : null;
  return {
    if (report.providerId case final id?) 'providerId': id,
    'protocolId': report.protocolId.name,
    if (report.serviceType case final service?) 'serviceType': service,
    'status': report.status.name,
    'durationMs': report.duration.inMilliseconds,
    'deviceCount': report.deviceCount,
    if (report.observations.isNotEmpty) 'observations': report.observations,
    if (error != null) 'exceptionType': _exceptionType(error),
    'stage':
        operation?.stage ??
        (error is SsdpSocketFailure ? error.stage : 'discover'),
    if (operation?.errorDomain case final domain?) 'errorDomain': domain,
    if (error != null) 'code': discoveryFailureCode(error),
    if (osCode != null) 'osCode': osCode,
  };
}

Object? _cause(Object? error) => switch (error) {
  SsdpSocketFailure(:final cause) => cause,
  DiscoveryOperationFailure(:final cause) => cause,
  _ => error,
};

String _exceptionType(Object error) => _cause(error).runtimeType.toString();

int? discoveryOsCode(Object? error) {
  if (error is DiscoveryOperationFailure && error.osCode != null) {
    return error.osCode;
  }
  final cause = _cause(error);
  return switch (cause) {
    SocketException(:final osError) => osError?.errorCode,
    OSError(:final errorCode) => errorCode,
    _ => null,
  };
}

String discoveryFailureCode(Object error) {
  if (error case DiscoveryOperationFailure(code: final code?)) {
    return code;
  }
  final osCode = discoveryOsCode(error);
  return switch (error) {
    _ when _cause(error) is TimeoutException => 'responseTimeout',
    _ when const {1, 13}.contains(osCode) => 'networkBlocked',
    _ when const {50, 51, 65, 100, 101, 113}.contains(osCode) =>
      'networkUnreachable',
    SsdpSocketFailure(stage: 'noInterface') => 'noNetworkInterface',
    SsdpSocketFailure(stage: 'interfaces') => 'interfaceEnumerationFailed',
    SsdpSocketFailure(stage: 'interface') => 'multicastInterfaceFailed',
    SsdpSocketFailure(stage: 'bind') => 'socketBindFailed',
    SsdpSocketFailure(stage: 'send') => 'multicastSendFailed',
    SsdpSocketFailure(stage: 'receive') => 'socketReceiveFailed',
    DiscoveryOperationFailure() when _cause(error) is FormatException =>
      'invalidAdvertisement',
    DiscoveryOperationFailure() => 'mdnsOperationFailed',
    SocketException() => 'socketFailure',
    _ => 'providerException',
  };
}
