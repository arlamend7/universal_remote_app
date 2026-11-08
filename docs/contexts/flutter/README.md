# Flutter context

- [Device management review](device-management-review.md): modal discovery,
  identity reconciliation, settings separation, power and stable status feedback.

- [Modular grid controller](modular-grid-controller.md): per-TV grids, widget library,
  groups, runtime controls and preservation of classic layouts.

- [macOS startup and discovery fixes](macos-startup-discovery.md): preferences,
  explicit legacy import and multi-interface SSDP verification.
- [Project structure](project-structure.md): ownership and navigation through source.
- [Readability rules](../architecture/readability-rules.md): guard clauses, nesting,
  one type per file, and the automated checks.

The composition approach follows Kap Games. Its code was inspected as a reference;
Kap Games itself was not modified. Universal Remote has its own domain boundaries,
protocol packages, and persistence adapters.
