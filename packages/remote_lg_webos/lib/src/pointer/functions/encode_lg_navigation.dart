import 'package:remote_core/remote_core.dart';

/// Pointer commands end in a blank line, independently of SSAP JSON framing.
String encodeLgNavigation(NavigationKey key) =>
    'type:button\nname:${key.name.toUpperCase()}\n\n';
