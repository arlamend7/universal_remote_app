# Provider inventory (after migration)

| Provider ID | Integration(s) | Engine | Compatibility | Channel | Parity |
|---|---|---|---|---|---|
| `lg.webos` | `lg.webos.22-plus` (priority 10), `lg.webos.legacy` | `ssap` | webOS ≥ 7 / < 7 from `product_name` | stable | generic golden, standard + conditional scenarios |
| `android.tv` | `android.tv.remote-v2` | `android-remote-v2` | unrestricted; OS/firmware unknown | stable | generic golden |
| `samsung.tizen` | `samsung.tizen.supported` | `samsung-channel` | unrestricted; model/firmware unknown | stable | generic golden |
| `roku.ecp` | `roku.ecp.supported` | `roku-ecp` | unrestricted; Roku OS version reported | development | generic golden |
| `example.smarttv` | `example.json-websocket` | `json-websocket` | fixture | development | engine tests |

Every TV capability the legacy controllers supported is mapped and passes the
recorded wire-level parity goldens (`docs/drivers/parity/`). All behaviour is
fixture-verified; physical TV verification is still required
(`docs/hardware-checklist.md`).
