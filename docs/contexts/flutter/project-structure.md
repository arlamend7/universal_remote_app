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
    remote/                       commands, volume/current-content observation
    remote_layout/                per-TV module models and profile-backed layouts
    remote_grid/                  widget catalog, grid geometry and per-TV activation
    settings/                     persisted theme and diagnostic preferences
    storage/                      application storage contract
  data/
    devices/                      profile mapping/repository and LG manual factory
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
- remote_lg_webos/src: devices/session orchestration, connection/options/errors,
  pairing/manifest, capability controllers and resolution, command channel, pointer
  lifecycle/framing, providers/discovery, and SSAP protocol subcontexts for message
  models, pending requests, subscriptions, and session coordination.

The public package entrypoints remain barrels. Internal files import the concrete
contract they need. Capability controllers no longer receive the entire LG device
controller or access its private fields: they use a command channel, pointer
connection, or immutable connection options.

## Where to make a change

| Change | Owning context |
| --- | --- |
| Add a TV metadata field | remote_core/src/devices/models; profile mapper if persisted |
| Change pairing authorization | remote_lg_webos/src/devices/services and pairing constants |
| Change SSAP request deadlines | remote_lg_webos/src/protocol/requests |
| Change subscriptions/unsubscribe | remote_lg_webos/src/protocol/subscriptions |
| Change LG volume serialization | remote_lg_webos/src/capabilities/volume |
| Change pointer framing/lifetime | remote_lg_webos/src/pointer |
| Change UI volume layout | presentation/views/remote/widgets/volume_card.dart |
| Change manual form validation | data/devices/factories/lg_manual_device_factory.dart |
| Change form state/errors | presentation/views/devices/viewmodels/device_editor_viewmodel.dart |
| Change navigation | routes/app_routes.dart |
| Change dependency wiring | app/app_bootstrap.dart |

Keep helpers near their owner. Move a component to shared presentation only when
it is actually reused. Do not create empty future-integration packages or duplicate
abstract layers simply to match a diagram.

## Minimal controller UI

Remote and Devices share the indexed main shell. The remote opens the saved
grid or a starter grid. Both run through the same renderer. The editor is opened
by `routes/open_remote_editor.dart`.

- `packages/remote_ui/lib/src/editor` owns the draft, gestures, and item settings.
- `packages/remote_ui/lib/src/catalog` owns the searchable two-column library.
- `packages/remote_ui/lib/src/rendering` owns live controls and their feedback.
- `packages/remote_ui` owns the shared `UniversalRemoteItem`, geometry, and typed
  definitions. `TvItems` and `AcItems` bind commands to separate device contracts.
- The app implements local persistence in `data/dashboards`. Shared dashboard
  state, validation, and migration live in `packages/remote_ui/lib/src/editor`.
- `presentation/widgets/grid` owns shared grid sizing and placement primitives.

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
  stored `RemoteDevice` profile, the item kind and axis; icons use the same
  context. There is no decoration element.
- `RemoteItemStyle` stores background, border (on/off, color, width) and corner
  radius; the appearance editor in the control settings sheet edits them.
- Editor: back arrow and check in the app bar, device name as title, one toolbar
  row (view/edit, add control, undo, redo, options) with the hint underneath,
  nine-dot resize handle inside each tile.
- `RemoteFeedback` (remote_ui/feedback) provides haptics and system click sounds;
  the app's "Sound and haptics" setting switches it on or off.
- App shell: `AppTopBar` hosts brand, theme mode (system/light/dark) and accent
  swatches; `AppThemes.build(brightness, accent)` uses the portfolio palette.
