import 'package:flutter/material.dart';

abstract final class DeviceStatusColors {
  static Color connected(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xff35d49d)
      : const Color(0xff007b55);

  static Color possiblyAwake(Brightness brightness) =>
      brightness == Brightness.dark
      ? const Color(0xffefb72c)
      : const Color(0xff8b6200);

  static Color unknown(Brightness brightness) => brightness == Brightness.dark
      ? const Color(0xff687584)
      : const Color(0xff626c77);
}
