import 'package:flutter/material.dart';

IconData gridControlIcon(String? name, IconData fallback) => switch (name) {
  'tv' => Icons.tv_outlined,
  'apps' => Icons.apps,
  'volume' => Icons.volume_up_outlined,
  'home' => Icons.home_outlined,
  'power' => Icons.power_settings_new,
  'input' => Icons.input,
  'music' => Icons.music_note_outlined,
  'star' => Icons.star_outline,
  'play' => Icons.play_arrow,
  _ => fallback,
};
