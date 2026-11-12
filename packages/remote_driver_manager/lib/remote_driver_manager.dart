/// Integration catalog, content-addressed installation, compatibility
/// selection and provider registration for the driver runtime.
library;

export 'src/distribution/driver_http_source.dart';
export 'src/distribution/driver_signature_verifier.dart';
export 'src/catalog/catalog_integration.dart';
export 'src/catalog/integration_catalog.dart';
export 'src/catalog/signed_catalog_envelope.dart';
export 'src/installation/atomic_json_file.dart';
export 'src/installation/device_assignment.dart';
export 'src/installation/http_integration_package_source.dart';
export 'src/installation/installed_generation.dart';
export 'src/installation/installed_integration.dart';
export 'src/installation/integration_catalog_repository.dart';
export 'src/installation/integration_installer.dart';
export 'src/installation/integration_inventory.dart';
export 'src/installation/integration_metadata_keys.dart';
export 'src/installation/integration_object_store.dart';
export 'src/installation/integration_package.dart';
export 'src/installation/integration_package_source.dart';
export 'src/installation/integration_update_report.dart';
export 'src/installation/integration_update_service.dart';
export 'src/installation/integration_validator.dart';
export 'src/installation/legacy_driver_storage_migration.dart';
export 'src/installation/migrate_legacy_device_metadata.dart';
export 'src/installation/package_verifier.dart';
export 'src/installation/update_schedule.dart';
export 'src/installation/verified_object.dart';
export 'src/providers/integration_provider_source.dart';
export 'src/providers/provider_rule_source.dart';
export 'src/selection/integration_candidate.dart';
export 'src/selection/integration_resolver.dart';
export 'src/selection/integration_selection.dart';
export 'src/selection/managed_integration_planner.dart';
export 'src/installation/stored_zip_writer.dart';
export 'src/installation/unavailable_package_source.dart';
export 'src/service/integration_service.dart';
export 'src/installation/seed_bundle.dart';
