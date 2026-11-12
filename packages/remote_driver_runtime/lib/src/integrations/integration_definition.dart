import 'dart:convert';

import 'package:remote_core/remote_core.dart';

import '../engines/contracts/protocol_engine.dart';
import '../engines/contracts/protocol_engine_registry.dart';
import 'compiled_mapping.dart';
import 'operation_table.dart';

/// A package's JSON compiled against the engines of this runtime.
///
/// Compilation fails when the engine or any required operation kind is
/// missing, a mapping leaves the engine's safe vocabulary, a capability has
/// no executable operation set, or the manifest misstates its contents.
final class IntegrationDefinition {
  IntegrationDefinition._({
    required this.manifest,
    required this.engine,
    required this.connection,
    required this.capabilities,
    required Map<String, CompiledMapping> mappings,
    required Map<String, Map<String, CompiledMapping>> overrides,
    required this.files,
  }) : _mappings = mappings,
       _overrides = overrides;

  factory IntegrationDefinition.compile(
    Map<String, String> files,
    ProtocolEngineRegistry registry,
  ) {
    final manifest = IntegrationManifest.fromJson(
      _json(files, 'manifest.json'),
    );
    final missing = registry.missing(manifest.runtime);
    if (missing.isNotEmpty) {
      throw FormatException(
        'This runtime cannot execute ${manifest.identity.integrationId}: '
        'missing ${missing.join(', ')}.',
      );
    }
    final engine = registry.engine(manifest.engine);
    final mappings = _compileAll(
      registry,
      manifest,
      _json(files, 'mappings.json'),
    );
    final overrides = {
      for (final profile in manifest.profiles)
        profile.id: _compileAll(
          registry,
          manifest,
          profile.mappingOverrides,
          profileId: profile.id,
        ),
    };
    final capabilities = _capabilities(_json(files, 'capabilities.json'));
    _checkCapabilities(manifest, capabilities, mappings);
    return IntegrationDefinition._(
      manifest: manifest,
      engine: engine,
      connection: engine.compileConnection(
        _json(files, 'connection.json', optional: true),
      ),
      capabilities: capabilities,
      mappings: mappings,
      overrides: overrides,
      files: Map.unmodifiable(files),
    );
  }

  final IntegrationManifest manifest;
  final ProtocolEngine engine;

  /// The validated `connection.json` section passed to the engine session.
  final Map<String, Object?> connection;

  /// Capability declarations in their declared (probe) order.
  final List<CapabilityDeclaration> capabilities;
  final Map<String, CompiledMapping> _mappings;
  final Map<String, Map<String, CompiledMapping>> _overrides;
  final Map<String, String> files;

  IntegrationIdentity get identity => manifest.identity;

  /// Integration defaults with [profile]'s validated overrides applied.
  OperationTable operations(CompatibilityProfile profile) =>
      OperationTable({..._mappings, ...?_overrides[profile.id]});

  CompatibilityProfile profile(String id) => manifest.profiles.firstWhere(
    (profile) => profile.id == id,
    orElse: () => manifest.bootstrapProfile,
  );

  /// A JSON document from the package other than the compiled ones.
  Map<String, Object?>? document(String path) =>
      files.containsKey(path) ? _json(files, path) : null;

  static Map<String, CompiledMapping> _compileAll(
    ProtocolEngineRegistry registry,
    IntegrationManifest manifest,
    Map<String, Object?> json, {
    String? profileId,
  }) {
    final result = <String, CompiledMapping>{};
    for (final entry in json.entries) {
      final mapping = OperationMapping.fromJson(entry.key, entry.value);
      if (!manifest.runtime.operations.contains(mapping.kind)) {
        throw FormatException(
          '${mapping.kind} is used but not declared in requiredRuntime.',
        );
      }
      result[entry.key] = CompiledMapping(
        mapping,
        registry.compile(manifest.engine, mapping),
        profileId: profileId,
      );
    }
    return result;
  }

  static List<CapabilityDeclaration> _capabilities(Map<String, Object?> json) =>
      [
        for (final entry in json.entries)
          CapabilityDeclaration.fromJson(entry.key, entry.value),
      ];

  static void _checkCapabilities(
    IntegrationManifest manifest,
    List<CapabilityDeclaration> declarations,
    Map<String, CompiledMapping> mappings,
  ) {
    final declared = {
      for (final declaration in declarations) declaration.capability,
    };
    if (declared.length != manifest.capabilities.length ||
        !declared.containsAll(manifest.capabilities)) {
      throw const FormatException(
        'manifest.json capabilities must equal capabilities.json.',
      );
    }
    for (final declaration in declarations) {
      final unknown = declaration.operations.where(
        (operation) => !RuntimeOperations.isMappable(operation),
      );
      if (unknown.isNotEmpty) {
        throw FormatException('Unknown runtime operation ${unknown.first}.');
      }
      if (declaration.select(mappings.containsKey) == null) {
        throw FormatException(
          '${declaration.capability.name} has no executable operation set.',
        );
      }
      final probe = declaration.verification?.operation;
      if (probe != null && !mappings.containsKey(probe)) {
        throw FormatException(
          '${declaration.capability.name} verification is not mapped.',
        );
      }
    }
  }

  static Map<String, Object?> _json(
    Map<String, String> files,
    String path, {
    bool optional = false,
  }) {
    final text = files[path];
    if (text == null && optional) {
      return const {};
    }
    if (text == null) {
      throw FormatException('Integration package is missing $path.');
    }
    final value = jsonDecode(text);
    if (value is! Map<String, Object?>) {
      throw FormatException('$path must be a JSON object.');
    }
    return value;
  }
}
