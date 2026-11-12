/// Distribution channel of a published integration.
enum IntegrationChannel {
  stable('stable'),

  /// Only offered by builds that explicitly allow development integrations.
  development('development');

  const IntegrationChannel(this.id);
  final String id;

  static IntegrationChannel parse(Object? value) {
    final channel = values.where((candidate) => candidate.id == value);
    if (channel.isEmpty) {
      throw const FormatException('Unknown integration channel.');
    }
    return channel.single;
  }
}
