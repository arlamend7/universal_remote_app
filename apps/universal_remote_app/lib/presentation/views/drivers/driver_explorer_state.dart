import 'package:flutter/material.dart';

import 'driver_explorer_page.dart';
import 'driver_provider_page.dart';
import 'models/driver_provider_summary.dart';
import 'viewmodels/driver_explorer_viewmodel.dart';

class DriverExplorerState extends State<DriverExplorerPage> {
  late final _model = DriverExplorerViewModel(widget.drivers);

  @override
  void initState() {
    super.initState();
    _model.load();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Drivers')),
    body: SafeArea(
      child: ListenableBuilder(
        listenable: Listenable.merge([
          _model.loading,
          _model.providers,
          _model.failed,
        ]),
        builder: (context, _) => _body(context),
      ),
    ),
  );

  Widget _body(BuildContext context) {
    if (_model.loading.value) {
      return const Center(child: CircularProgressIndicator());
    }
    final providers = _model.providers.value;
    if (providers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _model.failed.value
                ? 'The saved driver catalog could not be verified.'
                : 'No verified driver catalog is available.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    final checked = _model.checkedAt.value;
    return ListView(
      children: [
        if (checked != null)
          ListTile(
            title: const Text('Last catalog refresh'),
            subtitle: Text(
              MaterialLocalizations.of(context)
                  .formatMediumDate(checked.toLocal()),
            ),
          ),
        for (final provider in providers) _provider(context, provider),
      ],
    );
  }

  Widget _provider(BuildContext context, DriverProviderSummary provider) =>
      ListTile(
        title: Text(provider.name),
        subtitle: Text(
          '${provider.platform} · ${provider.integrations.length} '
          'integration${provider.integrations.length == 1 ? '' : 's'} · '
          '${provider.installed} installed',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DriverProviderPage(provider: provider),
          ),
        ),
      );
}
