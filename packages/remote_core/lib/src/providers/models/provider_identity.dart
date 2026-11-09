enum ProviderIdentity {
  lgWebOs('lg.webos', 'LG webOS'),
  androidTv('android.tv', 'Google TV / Android TV'),
  roku('roku.ecp', 'Roku'),
  custom('', 'Custom provider');

  const ProviderIdentity(this.storageId, this.label);

  final String storageId;
  final String label;
}
