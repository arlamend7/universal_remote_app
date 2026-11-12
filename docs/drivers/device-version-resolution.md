# Device software evidence and resolution

A driver's release, a compatibility-profile revision, and the runtime version are independent of the TV's OS, firmware, software and build values. Preserve each reported value and the provenance of the report. A model name is not a version. Manufacturer build strings are opaque unless a comparison strategy defines their ordering.

Before authentication, use available discovery evidence and an explicitly compatible bootstrap profile. Unknown software evidence cannot satisfy a restrictive version range. After authentication, query the supported device information endpoint, merge the new evidence, and run compatibility resolution again. Apply bindings at a safe session boundary and preserve pairing credentials when the physical software changes.

The baseline exposes LG and Roku software details and Android Remote v2 protocol evidence through its existing integrations. Samsung firmware and exact Android OS version are currently unknown. See the [provider audits](parity/tv-api.md) for the underlying evidence and migration targets.

## Schema-2 integrations (generic resolution)

`IntegrationResolver` (manager, `lib/src/selection`) replaces platform-named
comparators with each integration's declared `versionScheme`:

1. **Bootstrap (before authentication).** Candidates are the integrations of the
   device's provider family (development integrations only when the build
   allows them), filtered by model when a model is known. A previous
   assignment wins; otherwise the highest `priority` (then ID) is chosen with
   its `bootstrap` profile. Firmware is never assumed before pairing.
2. **Identified (after authentication).** The session's software
   (`operatingSystemVersion`, `firmwareVersion`, `hardwareModel`/`model`) is
   compared with every family member's `compatibility`. The current integration
   stays if it matches; otherwise the best matching one is selected (a single,
   credential-preserving handoff). If nothing matches — including unknown
   software — the bootstrap choice stays. The profile is the first `identified`
   profile whose ranges match, else the bootstrap profile.

LG is split into `lg.webos.22-plus` (`osVersion >=7`, priority 10) and
`lg.webos.legacy` (`osVersion <7`). The SSAP engine derives the webOS version
from `product_name` (`webOSTV 7.0` → `7.0`) when the integration declares
`osVersionPrefix`; firmware (`major_ver.minor_ver`) stays separate. The
`webOS 22 = webOSTV 7.x` mapping is not yet confirmed on hardware.

Discovery, manual setup, connection policy and wake are declared per
integration in `discovery.json` and `device.json`, and the generic
`IntegrationProviderSource` builds provider definitions from them. Parity
tests compare the declarative identifiers and manual setup with the legacy
providers on the same inputs.
