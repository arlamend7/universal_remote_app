enum DeviceCategory {
  television('television'),
  airConditioner('airConditioner'),
  mediaPlayer('mediaPlayer'),
  speaker('speaker'),
  light('light'),
  fan('fan'),
  projector('projector'),
  unknown('unknown');

  const DeviceCategory(this.id);
  final String id;

  static DeviceCategory? tryParse(Object? id) =>
      values.where((value) => value.id == id).firstOrNull;

  static DeviceCategory parse(Object? id) =>
      tryParse(id) ?? (throw const FormatException('Unknown DeviceCategory.'));
}
