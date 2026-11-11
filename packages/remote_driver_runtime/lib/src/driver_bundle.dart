import 'dart:convert';

import 'package:remote_core/remote_core.dart';

import 'driver_command.dart';
import 'driver_discovery_rules.dart';
import 'driver_exchange.dart';

/// A validated directory or archive's content, independent of its transport.
final class DriverBundle {
  DriverBundle._(
    this.manifest,
    this.discovery,
    this.capabilities,
    this.commands,
    this.exchanges,
    this.bindings,
  );

  factory DriverBundle.parse(Map<String, String> files) {
    if (files.length > maximumFiles || files.values.any(_oversized)) {
      throw const FormatException('Driver bundle exceeds its content limits.');
    }
    final manifest = DriverManifest.fromJson(_object(files, 'manifest.json'));
    final discovery = DriverDiscoveryRules.fromJson(
      _object(files, 'discovery.json'),
    );
    final declared = _object(files, 'capabilities.json');
    final capabilities = manifest.capabilities.asNameMap().map(
      (name, capability) => MapEntry(capability, _commandIds(declared[name])),
    );
    if (capabilities.length != declared.length) {
      throw const FormatException('Capabilities must match the manifest.');
    }
    final ids = capabilities.values.expand((value) => value).toSet();
    final bindings = _bindings(files, ids, manifest);
    final exchanges = _exchanges(files, manifest);
    final exchangeIds = ids.where(
      (id) =>
          exchanges[id]?.operation == DriverOperation.webSocketRequest &&
          !files.containsKey('commands/$id.json'),
    );
    final oneShotIds = ids.difference({
      ...?bindings?.commands.keys,
      ...exchangeIds,
    });
    final commands = _commands(files, oneShotIds, manifest);
    _validateSession(exchanges, commands);
    final expectedCount =
        3 + commands.length + exchanges.length + (bindings == null ? 0 : 1);
    if (files.length != expectedCount) {
      throw const FormatException(
        'The driver bundle contains unexpected files.',
      );
    }
    return DriverBundle._(
      manifest,
      discovery,
      Map.unmodifiable(capabilities),
      Map.unmodifiable(commands),
      Map.unmodifiable(exchanges),
      bindings,
    );
  }

  static const maximumFiles = 64;
  static const maximumFileBytes = 32768;

  final DriverManifest manifest;
  final DriverDiscoveryRules discovery;
  final Map<RemoteCapability, List<String>> capabilities;
  final Map<String, DriverCommand> commands;
  final Map<String, DriverExchange> exchanges;
  final DriverBindings? bindings;

  bool get requiresPersistentSession =>
      capabilities.values
          .expand((ids) => ids)
          .any(
            (id) => !commands.containsKey(id) && exchanges.containsKey(id),
          ) ||
      exchanges.containsKey('authenticate') ||
      exchanges.containsKey('pair') ||
      exchanges.containsKey('identify-software');

  static void _validateSession(
    Map<String, DriverExchange> exchanges,
    Map<String, DriverCommand> commands,
  ) {
    final auth = exchanges['authenticate'];
    final pair = exchanges['pair'];
    final identify = exchanges['identify-software'];
    if (identify != null &&
        identify.operation != DriverOperation.webSocketRequest) {
      throw const FormatException(
        'Invalid driver software identification workflow.',
      );
    }
    if ((auth != null &&
            auth.operation != DriverOperation.webSocketAuthenticate) ||
        (pair != null &&
            (auth == null ||
                pair.operation != DriverOperation.webSocketPair)) ||
        (auth != null && commands.isNotEmpty)) {
      throw const FormatException(
        'Invalid authenticated driver session workflows.',
      );
    }
  }

  static bool _oversized(String content) =>
      utf8.encode(content).length > maximumFileBytes;

  static DriverBindings? _bindings(
    Map<String, String> files,
    Set<String> ids,
    DriverManifest manifest,
  ) {
    final declared = manifest.runtime.operations.contains(
      DriverOperation.compiledBindings,
    );
    if (!declared && !files.containsKey('bindings.json')) {
      return null;
    }
    final values = _object(files, 'bindings.json');
    if (!declared ||
        values.isEmpty ||
        values.keys.any((key) => !ids.contains(key)) ||
        values.values.any(
          (value) =>
              value is! String ||
              value.isEmpty ||
              value.length > 128 ||
              value.trim() != value,
        )) {
      throw const FormatException('Invalid compiled driver bindings.');
    }
    return DriverBindings(values.cast<String, String>());
  }

  static Map<String, DriverCommand> _commands(
    Map<String, String> files,
    Set<String> ids,
    DriverManifest manifest,
  ) => {
    for (final id in ids)
      id: DriverCommand.parse(_file(files, 'commands/$id.json'), manifest),
  };

  static Map<String, DriverExchange> _exchanges(
    Map<String, String> files,
    DriverManifest manifest,
  ) => {
    for (final entry in files.entries.where(
      (file) => file.key.startsWith('workflows/'),
    ))
      _workflowId(entry.key): DriverExchange.parse(entry.value, manifest),
  };

  static String _workflowId(String path) {
    final match = _workflow.firstMatch(path);
    if (match == null || match.end != path.length) {
      throw const FormatException('Invalid driver workflow path.');
    }
    return match[1]!;
  }

  static List<String> _commandIds(Object? value) {
    if (value is! List<Object?> ||
        value.isEmpty ||
        value.length > 16 ||
        !value.every(_validId) ||
        value.toSet().length != value.length) {
      throw const FormatException('Invalid driver capability command list.');
    }
    return List.unmodifiable(value.cast<String>());
  }

  static bool _validId(Object? value) =>
      value is String && _id.firstMatch(value)?.end == value.length;

  static Map<String, Object?> _object(Map<String, String> files, String name) {
    final value = jsonDecode(_file(files, name));
    if (value is! Map<String, Object?>) {
      throw const FormatException('Expected a driver JSON object.');
    }
    return value;
  }

  static String _file(Map<String, String> files, String name) =>
      files[name] ?? (throw FormatException('Missing driver file: $name.'));

  static final _id = RegExp(r'^[a-z][a-z0-9_-]{0,63}$');
  static final _workflow = RegExp(r'^workflows/([a-z][a-z0-9_-]{0,63})\.json$');
}
