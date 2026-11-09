import 'package:xml/xml.dart';

String? rokuSerial(XmlElement info) {
  final serial = info.getElement('serial-number')?.innerText.trim();
  if (info.name.local != 'device-info' ||
      serial == null ||
      !RegExp(r'^[a-z0-9-]+$', caseSensitive: false).hasMatch(serial)) {
    return null;
  }
  return serial;
}
