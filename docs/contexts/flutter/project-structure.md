# Universal Remote source structure

This is the current code-navigation guide. The layout follows Kap Games' preferred
app/routes/presentation/domains/data/shared destinations without importing its
unrelated game features or legacy folders.

```text
apps/universal_remote_app/lib/
  main.dart                       startup and protected-storage fallback
  app/                            composition root, dependencies, root app lifetime
  routes/                         route_definer definitions and navigation decisions
  presentation/
    containers/main/              application scaffold and navigation bar
    views/<context>/
      *_page.dart                 thin screen entry point
      viewmodels/                 presentation actions and derived UI state
      viewports/                  screen composition
      widgets/                    context-owned visual components
      forms/                      context-owned form fields
      modals/                     context-owned dialogs and dialog State
    widgets/                      genuinely shared layout and dialog components
  domains/
    connection/                   selection, sessions, connection lifecycle
    devices/                      profiles, repository contract, profile identity
    diagnostics/                  controlled diagnostic events
    discovery/                    cancellable discovery coordination
    settings/                     persisted theme and diagnostic preferences
    storage/                      application storage contract
  data/
    dashboards/                   local dashboard repository
    devices/                      profile mapping and repository
    network/                      multicast and wake adapters
    pairing/                      protected credential repository
    storage/                      native preferences and secure-storage adapters
  shared/themes/                  app theme definitions
```

Dependency direction is explicit: bootstrap wires data adapters into domain
services; views consume those injected services through viewmodels. Domain code
imports its repository/storage contracts, not concrete data repositories or UI.
The repository contract in domains/devices is implemented by the native-preference profile
repository under data/devices. main.dart does not validate connection forms.

A page builds a viewport. The viewport composes context widgets. UI event work
lives in its viewmodel; domain services contain no widget tree. Widget and State
classes have separate files. All dependencies are constructor-injected; there is
no Riverpod, global container, or service locator.

## Package contexts

- remote_core/src: devices, capabilities (with volume/navigation/etc. subcontexts),
  discovery, providers, pairing and errors. Public consumers use remote_core.dart.
- remote_network/src: transport contracts/state, WebSocket implementation, SSDP
  models/search sessions, and Wake-on-LAN functions. No manufacturer framing.
- remote_driver_runtime/src/engines/<engine>: one compiled protocol engine per folder (operations, decoders, procedures, session); src/integrations: JSON compilation and capability resolution; src/controller: the generic TV controller; src/devices: declarative discovery, manual setup, connection policy and wake.
  controllers, and connection policy. Protocol sessions live in the sibling
  SSAP, Remote v2, Samsung and ECP contexts.

The public package entrypoints remain barrels. Internal files import the concrete
contract they need. Capability controllers no longer receive the entire LG device
controller or access its private fields: they use a command channel, pointer
connection, or immutable connection options.

## Where to make a change

| Change | Owning context |
| --- | --- |
| Add a TV metadata field | remote_core/src/device.dart; profile mapper if persisted |
| Change pairing authorization | remote_driver_runtime/src/engines/ssap (ssap_engine_session.dart) and src/ssap/constants |
| Change SSAP request deadlines | remote_driver_runtime/src/ssap/requests |
| Change subscriptions/unsubscribe | remote_driver_runtime/src/ssap/subscriptions |
| Change LG volume serialization | drivers/providers/lg-webos/*/mappings.json (decoder: src/engines/ssap/decoders) |
| Change pointer framing/lifetime | remote_driver_runtime/src/engines/ssap/pointer |
| Change a control's look or command | remote_ui/src/items (definition) and rendering/primitives |
| Change manual form validation | drivers/providers/<provider>/<family>/device.json (src/devices/setup) and device_editor_viewmodel.dart |
| Change form state/errors | presentation/views/devices/viewmodels/device_editor_viewmodel.dart |
| Change navigation | routes/app_routes.dart |
| Change dependency wiring | app/app_bootstrap.dart |

Keep helpers near their owner. Move a component to shared presentation only when
it is actually reused. Do not create empty future-integration packages or duplicate
abstract layers simply to match a diagram.

## Minimal controller UI

Remote, Devices and Settings share the indexed main shell. The remote opens the saved
grid or a starter grid. Both run through the same renderer. The editor is opened
by `routes/open_remote_editor.dart`.

- `packages/remote_ui/lib/src/editor` owns the draft, gestures, and item settings.
- `packages/remote_ui/lib/src/catalog` owns the searchable two-column library.
- `packages/remote_ui/lib/src/rendering` owns live controls and their feedback.
  `element_renderer.dart` resolves a definition's layout; `primitives/` draws
  elements by type (action button, info, slider, collection, dial, touch surface).
- `packages/remote_ui` owns the shared `UniversalRemoteItem`, geometry, and typed
  definitions. `TvItems` and `AcItems` bind commands to separate device contracts.
- The app implements local persistence in `data/dashboards`. Shared dashboard
  state, validation, and migration live in `packages/remote_ui/lib/src/editor`.
- `packages/remote_ui/lib/src/widgets/grid` owns shared grid sizing and placement primitives.

Editor and live items share the shell and content renderer. Catalog and View
previews cannot issue commands. `GridArrangement` displaces neighbors on resize
or rotation, and fitted grids keep the active remote inside its viewport.

`DeviceWakeLearner` runs after a successful connection. It prefers the session's
optional `DeviceWakeAddressSource`, then the injected platform neighbor resolver.
`SavedDevicesController.updateExisting` serializes profile edits and checks the
current record before saving learned data. `SessionCredentialStore` handles
macOS in-memory credential reuse and disposal without changing protected storage.

`presentation/views/discovery` owns the discovery modal and its viewmodel;
`remote_core/lib/src/discovery.dart` reconciles identities through the app’s
profile storage callbacks. Device capability presentation belongs to `views/devices`, while
`views/settings` contains global preferences. The remote connection sheet replaces
inline offline action sections. See the [management review](device-management-review.md).

## Remote element model and editor

- `remote_ui/elements`: `RemoteAction`, `RemoteInput`, `RemoteCollection` and
  `RemoteInfo`. Info elements return a `RemoteReading` (title, subtitle, leading
  widget) from a `RemoteElementContext` that carries the full `RemotePanel`, the
  stored `RemoteDevice` profile, the item's saved settings and build context.
  An action's icon, label, enabled state and command come from one `builder`.
- `RemoteItemStyle` stores background, border (on/off, color, width) and corner
  radius; the appearance editor in the control settings sheet edits them.
- Editor: back arrow and check in the app bar, device name as title, one toolbar
  row (view/edit, add control, undo, redo, options) with the hint underneath,
  nine-dot resize handle inside each tile.
- `RemoteFeedback` (remote_ui/feedback) provides haptics and system click sounds;
  the app's "Sound and haptics" setting switches it on or off.
- App shell: the Settings page holds theme mode (system/light/dark), accent
  swatches and feedback; `AppThemes.build(brightness, accent)` uses the portfolio
  palette.
