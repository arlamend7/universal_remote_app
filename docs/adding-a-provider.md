# Adding an integration

1. Implement a `ProviderIdentifier` with a stable namespaced provider ID and
   exact `DiscoveryRequirements`. Reuse an existing SSDP or Bonjour search
   when the target fits. Accept evidence only for the service you support.
2. Return a `ProviderMatch` with the original observation and a validated
   `ConnectionProfile`. Mark uncertain compatibility as tentative. Keep
   authentication evidence distinct from protocol compatibility.
3. Implement the commands in a typed `RemoteBase`, `TVRemoteBase` or
   `ACRemoteBase` controller. Advertise capabilities using the existing
   evidence model. Pair and connect only when requested by the application.
4. Assemble a `ProviderDefinition` with the identifier and factory. Attach
   manual setup, connection policy or wake only if supported. Register the
   definition in `AppBootstrap`. Add a platform Bonjour declaration if the
   service requires one.
5. Test identification with raw evidence, manual setup, cancellation,
   authorization, controller creation and disposal. Test signed builds and
   real devices before reporting hardware support.

See the LG, Android TV and Roku identifiers for concrete examples.
`remote_network` owns Dart SSDP and mDNS, including the existing
`multicast_dns` dependency. iOS uses a service-driven Apple Bonjour adapter.
Android TV owns its certificate probe, pairing and Remote v2 controller.
Roku remains development-gated pending distribution authorization.
