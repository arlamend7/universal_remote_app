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

The current app has no app-string localization catalog. New journey copy needs an English and Portuguese catalog, with English fallback for other locales. Local-network authorization and catalog refresh are distinct. A failed catalog request must leave local discovery available. The platform network adapters do not currently expose a Wi-Fi SSID.
