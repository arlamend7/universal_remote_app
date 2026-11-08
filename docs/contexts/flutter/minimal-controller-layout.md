# Minimal controller layout

The app now implements the approved two-page prototype in
`artifacts/design/minimal-full-v1`. The only navigation destinations are Remote
and Devices. Preferences, device details, connection forms, TV apps, inputs,
pairing and layout editing use sheets/dialogs. The initial appearance is dark;
existing saved theme choices, including System, remain respected.

## Everyday use

Devices uses compact rows with a name, status indicator and overflow menu.
View details reveals address, manufacturer/model, connection state and reported
current app. Customize remote, rename, connection settings, re-pair, disconnect,
capability evidence and forgetting are accessible without making each list row
larger. Advanced transport/certificate/wake fields stay collapsed by default.

Remote uses the selected device header, a current-activity strip, circular
navigation, Home/Back and compact volume controls. Apps and Inputs use TV-reported
identifiers. Offline recovery remains actionable; certificate review is offered
only for TLS failures. Pairing is a focused sheet with actual connection state
and Cancel. It opens only from the visible Remote route and closes when pairing
ends. No artificial search delay or percentage is added.

The last successfully connected TV reopens as the selected remote. Startup does
not connect automatically or query protected credentials just to render this UI.
The user can Retry or choose another TV. A stable profile ID owns the layout,
not its current IP address.

## Per-device layouts

Open Remote → overflow → Customize remote, or Devices → overflow → Customize
remote. Drag the module handles to reorder; use each module's menu to choose
Compact/Wide or Remove. Add controls restores removed modules or adds channel
controls. Reset changes the draft to defaults. Done persists; Cancel discards.
An empty layout is allowed and leaves the header/menu available for recovery.

`domains/remote_layout` contains immutable module/layout models and the injected
DeviceLayoutsController. It stores the versioned JSON layout in the existing
ordinary profile metadata (`remoteLayout.v1`). This introduces no native record,
plugin, dependency, secret, or Keychain startup read. Saves preserve newer profile
names/certificates. Forgetting the profile also removes its layout.

The editor's viewmodel owns the draft and save/error state. Widget State owns
its lifetime. The existing AppBootstrap/AppDependencies constructor injection and
ValueNotifier/ListenableBuilder pattern remains in use. Each class/type has its
own file; protocols stay pure Dart.

## Current app and channel

The pure Dart core now exposes CurrentContentCapability and ChannelCapability.
The LG adapter reads/subscribes to the foreground app and resolves its title from
the TV's installed-app list. Live TV optionally adds the current channel name and
number. Foreground updates and a bounded ten-second refresh keep the display
current; feedback stops with the session and stale replies are rejected.

No program title, playback position, streaming progress or activity is invented.
Unknown feedback is displayed as unavailable and does not revoke navigation or
volume. Channel commands are offered only while live TV is reported; unsupported
or denied commands are translated to safe errors. Their initial evidence is
driver-known, not falsely described as hardware-verified.

The registration manifest requests READ_CURRENT_CHANNEL as well as the existing
READ_RUNNING_APPS/CONTROL_INPUT_TV permissions. Existing authorizations may need
an explicit Re-pair before a TV grants new feedback permissions. Firmware can
still decline those queries. No TV commands were sent during this redesign.

Protocol facts were checked against LG's primary
[Connect SDK API documentation](https://connectsdk.com/en/latest/apis-and/and-webostvservice.html)
and its published endpoint definitions. No third-party implementation was copied.

## Verification and previews

Final checks passed: 79 tests (48 package/structure and 31 app tests), Dart
analysis, formatting, readability/boundaries, the unchanged 91-entry dependency
audit, and macOS debug / Android ARM64 debug / iOS simulator debug builds.

Tests cover per-TV isolation and persistence, draft cancellation, ordering,
compact sizing, metadata preservation, invalid/old layout data, current app and
channel parsing, feedback failures, stale-session replies, actual control
routing, compact details, modal navigation and restoring the last TV without
protected-storage reads. Responsive UI tests exercise 320×640 and 1200×800
layouts with enlarged text, in addition to the standard phone view.

The screenshots in `artifacts/design/implemented-v1` are renders of the actual
Flutter widgets with simulated TV data, not image-generated UI. They include
Devices, details, layout editing, module selection, preferences, desktop Remote,
the default Remote, and live-channel context. The optional test capture path
loads the local icon/font assets for legibility and is not an application feature.

To refresh these previews on this development machine:

```sh
cd apps/universal_remote_app
/Users/karoline/Code/Dependencs/flutter/bin/flutter test --no-pub test/design/redesign_test.dart --dart-define=WRITE_DESIGN_PREVIEWS=true
```

Hardware behavior remains unverified until exercised on a real TV.
