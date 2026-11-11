/// Compatibility and lifecycle services for managed remote drivers.
library;

export 'src/resolution/driver_candidate.dart';
export 'src/resolution/driver_match.dart';
export 'src/resolution/driver_rejection.dart';
export 'src/resolution/driver_rejection_reason.dart';
export 'src/resolution/driver_resolution.dart';
export 'src/resolution/driver_resolver.dart';
export 'src/resolution/driver_compatibility_resolver.dart';
export 'src/lifecycle/driver_installation.dart';
export 'src/lifecycle/driver_manager.dart';
export 'src/lifecycle/driver_package.dart';
export 'src/lifecycle/driver_package_repository.dart';
export 'src/lifecycle/driver_package_storage.dart';
export 'src/lifecycle/cached_driver_catalog.dart';
export 'src/distribution/driver_catalog.dart';
export 'src/distribution/driver_catalog_repository.dart';
export 'src/distribution/driver_http_source.dart';
export 'src/distribution/driver_release.dart';
export 'src/distribution/driver_signature_verifier.dart';
export 'src/distribution/http_driver_package_repository.dart';
export 'src/connection/managed_driver_service.dart';
export 'src/connection/managed_tv_controller.dart';
export 'src/lifecycle/driver_update_service.dart';
export 'src/lifecycle/local_driver_package_repository.dart';
