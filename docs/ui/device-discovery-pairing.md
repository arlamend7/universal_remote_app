# Device discovery and pairing redesign

The design brief is the visual reference for this branch. The application uses the active color scheme, typography and controls from its existing theme.

| Context | Existing source | Reuse |
| --- | --- | --- |
| Devices | `DevicesViewModel`, `DeviceTile`, `DeviceCategoryBadge` | Keep the Devices tab and reuse the tile surface and badge in results. |
| Discovery | `DiscoveryController`, `DiscoveryViewModel`, `DiscoveryProfiles` | Keep streaming observations, cancellation, address updates, saved-device matching and catalog refresh. |
| Diagnostics | `ProtocolDiscoveryStatus`, `DiscoveryDetails`, safe diagnostic fields | Display actual status and expand details on demand. |
| Manual IP | `DeviceEditorViewModel`, `ManualAddressPage`, provider manual setup | Discovery pushes the full-page step 2 Connect by IP; its tune button holds name and legacy/advanced settings. It is offered only on discovery (the welcome page has no IP shortcut); the remote's Add TV keeps the `editDevice` modal. |
| Connection and pairing | `ConnectionController`, `PairingCodeReceiver`, `PairingProgressCard` | Observe the active connection and route commands through the same controller. |
| Remote controls | `RemoteItemRegistry.search`, `RemoteItemDefinition` | Use resolved capability evidence and existing category metadata. |
| Navigation | `AppRoutes`, `MainShell`, `openRemoteEditor` | Return to the existing dashboard or editor. |

Opened from the app shell, Search for devices replaces Preparation, so Back on discovery returns to the shell. On the first connection, Preparation has no Back button and stays below discovery. While a search runs, discovery shows a floating status above the footer.

Device setup uses English copy. Local-network authorization and catalog refresh are distinct, so a failed catalog request leaves local discovery available. Preparation checks the device’s network connection and displays the Wi-Fi name when the operating system makes it available.

## Physical device verification

Automated tests cover the UI and connection workflow with test providers. Verify discovery and pairing on a physical phone and TV separately. Use a signed iOS build and check that local-network access is enabled. Try discovery, code entry or approval on the TV, manual IP, and the remote dashboard. See [platform permissions](../security.md) for signing and local-network setup.
