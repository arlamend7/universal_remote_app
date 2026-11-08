# Universal Remote architecture migration

The attached architecture brief and the decisions recorded in this workspace guide
this migration. The separate design conversation was unavailable.

## Inventory and baseline

| Area | Existing implementation | Migration decision |
| --- | --- | --- |
| Workspace | Flutter 3.47.5 and Dart 3.13.4. App plus core, network and LG packages. | Keep package boundaries and constructor injection. |
| Discovery and pairing | Provider registry, cancellable discovery, SSDP, LG SSAP sessions, TLS pinning, capability evidence and wake learning. | Keep the connection workflow and protocol implementations. |
| Remote | Typed capability controllers, shared volume and activity observers, classic and grid layouts. | Reuse observers and commands when migrating to typed category definitions. |
| Editor | Shared draggable/resizable item shell, collision and arrangement logic, View/Edit modes, generated catalog and configurable shortcuts. | Preserve saved controls and incrementally replace the catalog and item rendering. |
| Storage | Device profiles in native preferences, classic/grid layouts in versioned profile metadata, credentials in secure platform storage. | Extend profile decoding additively. Keep existing dashboard formats during this slice. |
| Dependencies | SDK, local workspace packages, pinned route_definer, approved secure storage and test dependencies. | Retain the current graph. |

Baseline analysis passed. All 56 package/architecture tests and 69 app tests passed.

## Migration order

1. Preserve category and last resolved capability data in saved profiles. Drive the
   two-column catalog from the active session or saved eligibility and preserve
   existing controls when capabilities change.
2. Build on the existing shortcut editor for ordered collections and cached options.
3. Introduce typed category device contracts and compiled item definitions alongside
   the current renderer. Migrate a complete control family at a time across
   actions, information, inputs and collections before removing legacy paths.
4. Consolidate the item shell, then implement rotation, independent orientation and
   per-element styling together with collision and persistence tests.
5. Migrate dashboard storage only after existing layouts can round-trip through
   the new model. Leave future provider implementations outside this migration.

## Implemented in this slice

- The existing discovery registry now publishes deduplicated snapshots as each
  provider finishes. Providers still return batches. Streaming individual SSDP
  hits inside a provider remains a later protocol change.
- Saved profiles include category and capability IDs. Existing LG rows infer TV
  from the provider ID and keep their profile metadata, including both layout
  formats. Unknown category and capability names are handled during decoding.
- The grid catalog consumes live resolved evidence or the last saved resolution.
  It distinguishes adjustable volume from readable volume, admits local controls
  across categories, and omits controls that require unavailable integrations.
  Driver-known operations remain eligible where a read-only probe is unavailable.
- Catalog cards are a two-column grid with equal-sized, inert previews. Search
  matches normalized names, families, categories and authored descriptions.
- Shortcut configuration caches choices within the current editor and connection,
  supports reordering, and indicates entries missing from the latest loaded list.
  Saved shortcut IDs are preserved. Runtime stale-entry detection remains pending.

## Simplification following the updated scope

- The classic renderer, classic editor, and classic layout services were removed.
  Remote and Devices retain the same main shell, and LG control still uses the
  existing provider. Devices without an active grid use one starter grid.
- Editor, catalog, rendering, and the shared item shell now live under
  `presentation/remote_ui`. `UniversalRemoteItem` provides the editing chrome
  and rotation. Live controls render without edit handles.
- The initial compiled TV definitions are used for volume actions, reactive
  volume information, slider input, and installed-app collections. The
  `TvRemoteDevice` contract delegates to the existing typed capability layer.
  Remaining widget families continue through their existing specialized renderers.
- Individual items can rotate in quarter turns. Grid geometry swaps footprints
  for odd quarter turns and checks content dimensions and collisions. Version 2
  payloads without a rotation field decode at zero. Groups remain unrotated.
- Active modular grids still load. Classic-only profiles use the starter grid.
  The profile decoder preserves ordinary metadata and secure pairing is unchanged.

Remaining work includes the full typed Standard/TV/AC registry, migrating the
remaining item families, independent element orientation, general per-element
styling and configuration, runtime stale-entry detection, a dedicated dashboard
repository, and per-device streaming inside provider discovery.

## Architecture restart

The second pass makes the item model a local workspace package. The main shell
and LG provider stay in place.

| Area | Before | Current implementation |
| --- | --- | --- |
| Device contracts | One device controller and a TV dashboard adapter | Separate TV and AC controller contracts in `remote_core`. LG implements the TV contract. The AC contract and temperature item are tested with a fake device. |
| Item registration | Metadata catalog plus independent renderer and eligibility switches | `remote_ui` resolves persisted kinds through Standard, TV and AC registrations. The same record drives category and capability filtering and selects the renderer. |
| Elements | Typed examples for volume and apps | Compiled TV actions, information, inputs and collections drive navigation, media, volume, app/input/channel shortcuts, touchpad and keyboard. Screen-specific interactions retain their app bindings. |
| Discovery | Results when providers finished | LG publishes individual SSDP advertisements through the existing cancellable discovery pipeline. Providers that return batches continue to work. |
| Editor | Grid geometry and quarter-turn rotation | Shared package item shell, rotation, independent orientation for the two-button volume control, item appearance, volume-element overrides and typed touchpad/keyboard configuration. |
| Persistence | Grid JSON embedded in device metadata | Versioned dashboard repository backed by ordinary platform preferences. Legacy active grids are copied at startup. Unknown definition IDs keep their grid position. Pairing secrets remain in secure storage. |
| Collections | Cached options and ordered selections in the editor | Typed app/input/channel options. LG app shortcuts missing from the last successful app list stay visible and disabled. |

### Remaining differences from the full brief

- Specialized renderers remain for compound controls. They now live in
  `packages/remote_ui` with the editor, catalog, preview and layout. The app
  provides a `RemotePanel` and dashboard storage through `RemoteEditorHost`.
  Registered element lookups supply control callbacks and collection options.
- Independent orientation and per-element styling are supported for the volume
  controls described above. General orientation, style overrides for every
  element, group rotation and independent content rotation remain open.
- The repository currently stores one dashboard per device. Standalone dashboard
  IDs, mixed-device dashboards and dashboard-level theme overrides remain open.
- Climate target temperature is implemented against the typed interface. There
  is no production AC provider. Climate mode, fan speed and swing have contracts
  but no catalog controls. Runtime stale-item handling currently covers LG apps.
- The keyboard sends text once and can optionally submit. Incremental editing
  sessions, replacement and backspace controls remain open.
- Tests exercise simulated LG sessions and local sockets. This migration has not
  been exercised on physical TV or AC hardware.
