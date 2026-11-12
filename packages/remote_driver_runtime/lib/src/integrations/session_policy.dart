import 'package:remote_core/remote_core.dart';

/// `connection.json#session`: generic session behaviour owned by the runtime.
final class SessionPolicy {
  const SessionPolicy({this.reconnectAttempts = 0, this.category});

  factory SessionPolicy.fromJson(Object? value) {
    if (value == null) {
      return const SessionPolicy();
    }
    final json = IntegrationJson.object(value, 'session');
    IntegrationJson.keys(json, const {'reconnectAttempts', 'category'});
    final category = json['category'];
    return SessionPolicy(
      reconnectAttempts: json['reconnectAttempts'] == null
          ? 0
          : IntegrationJson.integer(json, 'reconnectAttempts', maximum: 5),
      category: category == null ? null : _category(category),
    );
  }

  /// Automatic reconnections after an unexpected loss (1 s, 2 s, 4 s, …).
  final int reconnectAttempts;

  /// Device category decided from a session fact, when the protocol reports
  /// one (for example a set-top box versus a television).
  final ({FactCondition when, DeviceCategory then, DeviceCategory otherwise})?
  category;

  DeviceCategory? categoryFor(Map<String, String> facts) {
    final rule = category;
    if (rule == null) {
      return null;
    }
    return switch (rule.when.evaluate(facts)) {
      true => rule.then,
      false => rule.otherwise,
      null => null,
    };
  }

  static ({FactCondition when, DeviceCategory then, DeviceCategory otherwise})
  _category(Object value) {
    final json = IntegrationJson.object(value, 'category');
    IntegrationJson.keys(
      json,
      const {'when', 'then', 'otherwise'},
      required: const {'when', 'then', 'otherwise'},
    );
    return (
      when: FactCondition.fromJson(json['when']),
      then: _named(json['then']),
      otherwise: _named(json['otherwise']),
    );
  }

  static DeviceCategory _named(Object? value) => DeviceCategory.parse(value);
}
