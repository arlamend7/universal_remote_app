# Universal Remote

The active specification is docs/project-specification.md. User decisions override
its state-management section: use the Kap Games pattern (AppBootstrap.initialize,
AppDependencies, constructor injection, ValueNotifier/ListenableBuilder). No Riverpod.

The user explicitly approved flutter_secure_storage, Dart test and Flutter tests
and their required transitive dependencies for the expanded MVP. The original
DEVCOM policy is preserved in docs/dependency-policy.md as historical context.
Do not treat the original baseline audit as current authorization. The user
supplied a web-free route_definer update. Its verified Git revision
7546848c78ab81a208655ad7083f608942309b63 (4.0.0) is authorized for navigation;
its runtime dependencies are Flutter and meta only. Do not add other dependencies casually.

Keep protocol packages pure Dart. Widgets consume typed capability controllers.
No third-party implementation copying, credentials in logs, global TLS bypasses,
or silent downgrade to unencrypted transport. Hardware functionality is unverified
until exercised on a real TV. Changes to this project do not authorize changing
Kap Games; it is a reference for constructor-based dependency injection only.

SDKs: Flutter 3.47.5 / Dart 3.13.4 at
/Users/karoline/Code/Dependencs/flutter/bin/flutter.
Run formatting, analysis, package tests, widget tests and supported builds.

## Readability and structure

Follow Kap Games' app/routes/presentation/domains/data/shared responsibilities.
Organize each layer by its owning business context, with one class per file
(including State classes and test doubles). Put enums in separate enum files.
Prefer guard clauses and early returns. Limit imperative logic nesting to two
levels per method; extract named operations instead of nesting callbacks.
Use small presentation widgets so constructor nesting stays shallow as well.
Keep views declarative; put event orchestration in their viewmodels/services.
Use DDD and object-calisthenics principles to clarify real responsibilities,
not to create empty layers, pass-through classes, or a class for every primitive.
Add braces to control-flow statements. No broad grab-bag controller/model files.

Source navigation: docs/contexts/flutter/project-structure.md and MIND-MAP.md.
Readability checks: dart run tool/check_structure.dart.
Full conventions: docs/contexts/architecture/readability-rules.md.
