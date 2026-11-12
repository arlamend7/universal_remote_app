import 'package:remote_core/remote_core.dart';

import 'device_assignment.dart';
import 'verified_object.dart';

/// Inventory record for one integration: which verified generation is
/// active, which one rollback restores, and which devices use it.
final class InstalledIntegration {
  InstalledIntegration({
    required this.identity,
    this.current,
    this.previous,
    this.staged,
    this.rejected,
    this.installedAt,
    this.updatedAt,
    this.lastUpdatedAt,
    this.enabled = true,
    Map<String, DeviceAssignment> assignments = const {},
  }) : assignments = Map.unmodifiable(assignments) {
    final hashes = [current, previous, staged, rejected].whereType<String>();
    if (!hashes.every(VerifiedObject.isHash) ||
        assignments.keys.any((id) => id.isEmpty || id.length > 256)) {
      throw const FormatException('Invalid integration inventory record.');
    }
  }

  factory InstalledIntegration.fromJson(Object? value) {
    final json = IntegrationJson.object(value, 'installation');
    IntegrationJson.keys(json, _fields, required: _required);
    final assignments = IntegrationJson.object(
      json['assignments'] ?? const <String, Object?>{},
      'assignments',
    );
    if (assignments.length > 4096 || json['enabled'] is! bool) {
      throw const FormatException('Invalid integration inventory record.');
    }
    return InstalledIntegration(
      identity: IntegrationIdentity(
        integrationId: IntegrationJson.identifier(json, 'integrationId'),
        providerId: IntegrationJson.identifier(json, 'providerId'),
      ),
      current: _hash(json['current']),
      previous: _hash(json['previous']),
      staged: _hash(json['staged']),
      rejected: _hash(json['rejected']),
      installedAt: _time(json['installedAt'], 'installedAt'),
      updatedAt: _time(json['updatedAt'], 'updatedAt'),
      lastUpdatedAt: _time(json['lastUpdatedAt'], 'lastUpdatedAt'),
      enabled: json['enabled']! as bool,
      assignments: {
        for (final entry in assignments.entries)
          entry.key: DeviceAssignment.fromJson(entry.value),
      },
    );
  }

  static const _required = {'integrationId', 'providerId', 'enabled'};
  static const _fields = {
    ..._required,
    'current',
    'previous',
    'staged',
    'rejected',
    'installedAt',
    'updatedAt',
    'lastUpdatedAt',
    'assignments',
  };

  final IntegrationIdentity identity;

  /// Active verified generation, or null while an assignment awaits install.
  final String? current;

  /// The generation [current] replaced; kept for rollback.
  final String? previous;

  /// A verified generation waiting until no session uses the integration.
  final String? staged;

  /// A catalog generation the user rolled back from; never auto-reinstalled.
  final String? rejected;
  final DateTime? installedAt, updatedAt, lastUpdatedAt;
  final bool enabled;
  final Map<String, DeviceAssignment> assignments;

  String get integrationId => identity.integrationId;

  /// Hashes that garbage collection must keep.
  Set<String> get referencedHashes => {?current, ?previous, ?staged};

  InstalledIntegration copyWith({
    String? current,
    String? previous,
    String? staged,
    String? rejected,
    DateTime? installedAt,
    DateTime? updatedAt,
    DateTime? lastUpdatedAt,
    bool? enabled,
    Map<String, DeviceAssignment>? assignments,
    bool clearPrevious = false,
    bool clearStaged = false,
    bool clearRejected = false,
  }) => InstalledIntegration(
    identity: identity,
    current: current ?? this.current,
    previous: clearPrevious ? null : previous ?? this.previous,
    staged: clearStaged ? null : staged ?? this.staged,
    rejected: clearRejected ? null : rejected ?? this.rejected,
    installedAt: installedAt ?? this.installedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    enabled: enabled ?? this.enabled,
    assignments: assignments ?? this.assignments,
  );

  Map<String, Object?> toJson() => {
    'integrationId': identity.integrationId,
    'providerId': identity.providerId,
    'current': ?current,
    'previous': ?previous,
    'staged': ?staged,
    'rejected': ?rejected,
    if (installedAt != null)
      'installedAt': IntegrationJson.formatTimestamp(installedAt!),
    if (updatedAt != null)
      'updatedAt': IntegrationJson.formatTimestamp(updatedAt!),
    if (lastUpdatedAt != null)
      'lastUpdatedAt': IntegrationJson.formatTimestamp(lastUpdatedAt!),
    'enabled': enabled,
    if (assignments.isNotEmpty)
      'assignments': {
        for (final entry in assignments.entries)
          entry.key: entry.value.toJson(),
      },
  };

  static String? _hash(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is! String || !VerifiedObject.isHash(value)) {
      throw const FormatException('Invalid inventory package hash.');
    }
    return value;
  }

  static DateTime? _time(Object? value, String field) =>
      value == null ? null : IntegrationJson.timestamp(value, field);
}
