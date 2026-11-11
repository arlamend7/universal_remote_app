import 'package:remote_core/remote_core.dart';
import 'package:remote_driver_runtime/remote_driver_runtime.dart';

/// Validated package content. Distribution sources authenticate it before use.
final class DriverPackage {
  DriverPackage(Map<String, String> files)
    : files = Map.unmodifiable(files),
      bundle = DriverBundle.parse(files);

  final Map<String, String> files;
  final DriverBundle bundle;

  DriverIdentity get identity => bundle.manifest.identity;
}
