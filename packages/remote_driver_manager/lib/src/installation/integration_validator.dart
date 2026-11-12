import 'integration_package.dart';

/// Runtime-level validation (engines, mappings, capabilities) applied to a
/// package before it can be installed. Throws [FormatException] to reject.
typedef IntegrationValidator = void Function(IntegrationPackage package);
