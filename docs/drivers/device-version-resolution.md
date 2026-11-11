# Device software evidence and resolution

A driver's release, a compatibility-profile revision, and the runtime version are independent of the TV's OS, firmware, software and build values. Preserve each reported value and the provenance of the report. A model name is not a version. Manufacturer build strings are opaque unless a comparison strategy defines their ordering.

Before authentication, use available discovery evidence and an explicitly compatible bootstrap profile. Unknown software evidence cannot satisfy a restrictive version range. After authentication, query the supported device information endpoint, merge the new evidence, and run compatibility resolution again. Apply bindings at a safe session boundary and preserve pairing credentials when the physical software changes.

The baseline exposes LG and Roku software details and Android Remote v2 protocol evidence through its existing integrations. Samsung firmware and exact Android OS version are currently unknown. See the [provider audits](parity/tv-api.md) for the underlying evidence and migration targets.
