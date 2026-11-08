# Modular controller grid

The Remote/Devices navigation, theme and compact device rows are retained.
Each TV has its own optional four-column controller. Open **⋯ → Customize remote**.
The editor starts with the saved grid or the same starter grid used by the live
remote. **Done** saves the draft for that TV. **Cancel** discards the draft.

## Editing

- Customization opens a separate full page using the current app theme.
- **View** shows the draft with the saved remote's renderer and labeled sample data:
  Live TV, channel 42 / National Geographic HD, volume 35, app/input/channel
  shortcuts and connected status. Sample values are not saved or sent to a TV.
  **Edit** overlays editing controls. Switching modes retains the unsaved draft.
  Previews are read-only, including keyboard focus; they never send TV commands.
- The live remote and View mode fit their available safe-area height without a
  scrolling page. Empty trailing grid rows do not consume space. Normal layouts
  adapt their row heights; unusually dense layouts scale down while preserving
  control proportions. Fewer controls produce larger physical targets.
- Connection feedback lives in the header's status button rather than reserving
  a blank message row. Content starts eight pixels below the header.
- **Add control** opens a searchable two-column library of compatible controls.
  Each card uses the same preview dimensions. Adding a control closes the library.
- Drag immediately with a mouse, or hold and drag on touch. Drops snap to cells;
  occupied neighbors move to free positions. Dragging is distinct from resizing.
- Tap a control to change its name, style, shortcuts and size. Width choices and
  taller/shorter buttons replace coordinate fields. Pull its corner to resize.
  Individual items rotate in quarter turns. A 90° or 270° rotation swaps the
  footprint before collision checks. Minimum sizes and group bounds still apply.
- Volume variants include a 1×2 rocker, 1×3 rocker with level, 4×1 slider, vertical
  slider, horizontal rocker, dial, display, independent buttons and presets.
- App, input and channel shortcuts use IDs reported by the connected TV. Choose
  one shortcut or several for a strip/grid/carousel. Use the arrows next to a
  saved shortcut to reorder it. Recent apps means apps
  launched through this application, not the TV's complete history.
- Custom groups contain independently positioned controls using the same grid.
  An optional title reserves the first row. Resize the group to make room;
  nested groups are disallowed. **Apply group** updates only the parent draft;
  **Done** persists the whole controller.
- Undo/redo cover additions, edits, moves, rotations, removals and duplication.
  Layout options include starting over or extending the canvas.

Editor frames, cell lines and selection tools disappear in the saved remote.
Runtime controls use the existing theme and typed capabilities. Controls unavailable
in the current connection explain their status.

## Catalog and availability

The catalog contains 77 choices across audio, navigation, keys, apps, inputs,
channels, information, media, utilities and groups. Implemented controls include
touchpad movement/click/scroll, numeric and special keys, media transport, focused
TV text entry, channel selection, current app/channel feedback, power/wake,
connection management and a local sleep timer.

Eight entries explicitly require further integration: previous track, next track,
playback timeline, artwork/episode metadata, current input, voice, game mode and
Watch companion. The catalog hides these definitions.

Protocol implementation is not hardware verification. Firmware, active app,
permissions and pointer transport support determine behavior. Added text/channel
permissions may require **Re-pair** on older authorizations. Text entry requires a
focused TV field. Sleep runs locally while the app is active and cancels on
disconnect/device changes; it is not a native TV timer or background guarantee.

## Ownership and persistence

- `packages/remote_ui`: immutable models, typed registry, catalog and grid geometry.
- `packages/remote_ui/lib/src/editor`: draft, settings, and drag canvas.
- `packages/remote_ui/lib/src/catalog`: capability-aware library and previews.
- `packages/remote_ui/lib/src/widgets`: shared `UniversalRemoteItem` shell.
- `packages/remote_ui/lib/src/rendering`: frame-free controls and reactive feedback.
- `packages/remote_ui/lib/src/items`: built-in Standard, TV and AC controls.
  Each Dart entry declares its display metadata, category, and any required
  capabilities and elements. The catalog reads those entries from the registry.
  Every definition has one `layout` (`definitions/layouts`). `LinearLayout`
  derives its size from element slots and default position; other layouts own
  their size and only the settings they need. A `LinearLayout(adaptive: true)`
  (the volume and channel rockers) takes its direction from the item's shape:
  resize it wide for a horizontal row (less on the left) or tall for a column.
  Its minimum is that the long side holds every element. A definition's `id` is the
  persisted identity of a placed item; an unknown saved id resolves to the
  unavailable placeholder and is saved back unchanged. A definition declares
  its own `settings` (toggle, number, slider) and the editor builds its form
  from them, so the editor never checks item ids. A `RemoteItemCategory`
  marked `alternatives` (volume, mute, channel arrows, directional pad with arrow-only,
  single keys, media, pinned apps or inputs, activity) holds different looks of one control; the editor's
  Style picker lists only that category, each with the same sample preview as
  the library. Other categories just group unrelated controls.
  Elements are plain data: each `RemoteAction` declares its own icon, label
  and command, and similar controls simply repeat that small declaration.
- `presentation/widgets/grid`: shared geometry for editing and runtime.
- `packages/remote_ui/lib/src/host/device_sleep_controller.dart`: session-owned timer.

The `dashboards.v1` preference stores active grids separately from device profiles.
Items without a rotation field load at 0°. Profiles without a saved grid and
invalid grids use the starter grid.
Validation bounds item counts, dimensions, group depth and collisions.

## Validation

Validated November 6, 2026 with Flutter 3.47.5 / Dart 3.13.4:

- Formatting, analysis, readability checks and dependency audit.
- 51 package/architecture tests and 61 app tests, covering mouse/touch reordering,
  all catalog renderers, group drafts, persistence/rollback, repeat gestures,
  sleep ownership, mode switching, corner resizing, JSON consistency and typed protocol frames.
- Phone-fit tests cover 320×640, 390×844, 430×932 and 844×390, including larger text,
  visible/tappable controls, sample-data isolation and accessible power transitions.
- macOS debug, Android ARM64 debug and iOS simulator debug builds.

Actual Flutter captures are in `artifacts/design/implemented-v1/10-grid-editor.png`,
`11-widget-library.png` and `12-grid-runtime.png`. They show automated fixtures;
physical TV functionality remains unverified.

The newer full-page captures are `30-simple-editor.png`,
`31-simple-control-settings.png` and `32-view-draft.png` in the same directory.

Current phone-sized captures are `39-phone-classic.png`, `40-phone-grid.png` and
`41-sample-phone-preview.png`.
