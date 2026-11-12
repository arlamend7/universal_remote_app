# Device discovery and pairing redesign

The design brief is the visual reference for this branch. The application uses the active color scheme, typography and controls from its existing theme.

| Context | Existing source | Reuse |
| --- | --- | --- |
| Devices | `DevicesViewModel`, `DeviceTile`, `DeviceCategoryBadge` | Keep the Devices tab and reuse the tile surface and badge in results. |
| Discovery | `DiscoveryController`, `DiscoveryViewModel`, `DiscoveryProfiles` | Keep streaming observations, cancellation, address updates, saved-device matching and catalog refresh. |
| Diagnostics | `ProtocolDiscoveryStatus`, `DiscoveryDetails`, safe diagnostic fields | Display actual status and expand details on demand. |
| Manual IP | `editDevice` and provider manual setup | Open the existing editor from preparation and discovery. |
| Connection and pairing | `ConnectionController`, `PairingCodeReceiver`, `PairingProgressCard` | Observe the active connection and route commands through the same controller. |
| Remote controls | `RemoteItemRegistry.search`, `RemoteItemDefinition` | Use resolved capability evidence and existing category metadata. |
| Navigation | `AppRoutes`, `MainShell`, `openRemoteEditor` | Return to the existing dashboard or editor. |

Device setup uses English copy. Local-network authorization and catalog refresh are distinct, so a failed catalog request leaves local discovery available. Preparation checks the device’s network connection and displays the Wi-Fi name when the operating system makes it available.

## Physical device verification

Automated tests cover the UI and connection workflow with test providers. Verify discovery and pairing on a physical phone and TV separately. Use a signed iOS build and check that local-network access is enabled. Try discovery, code entry or approval on the TV, manual IP, and the remote dashboard. See [platform permissions](../security.md) for signing and local-network setup.
