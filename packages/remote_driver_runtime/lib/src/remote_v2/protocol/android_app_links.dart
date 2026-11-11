final _packageId = RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z0-9_]+)+$');

/// The link to send for an app target, or null when the target is not allowed.
/// A bare Android package id launches through a market link; a supported app
/// link (vnd.youtube:// or HTTPS without credentials) is sent unchanged.
String? androidAppLink(String target) {
  if (target.length > 512) {
    return null;
  }
  if (_packageId.hasMatch(target)) {
    return 'market://launch?id=$target';
  }
  final uri = Uri.tryParse(target);
  final https =
      uri != null &&
      uri.scheme == 'https' &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;
  return target == 'vnd.youtube://' || https ? target : null;
}
