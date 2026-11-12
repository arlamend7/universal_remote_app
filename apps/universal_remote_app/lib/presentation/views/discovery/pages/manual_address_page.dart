import 'package:flutter/material.dart';

import '../../../../app/app_dependencies.dart';
import 'manual_address_state.dart';

/// Setup step 2 alternative: connect to a TV by its IP address.
///
/// Pops with the connected device once pairing finishes.
class ManualAddressPage extends StatefulWidget {
  const ManualAddressPage({
    super.key,
    required this.dependencies,
    required this.onSearch,
  });

  final AppDependencies dependencies;

  /// Runs after this page closes to return to network search.
  final VoidCallback onSearch;

  @override
  State<ManualAddressPage> createState() => ManualAddressState();
}
