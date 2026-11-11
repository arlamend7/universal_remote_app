# Readability rules

These rules implement the user's request and take precedence over older examples.

1. One class per file, including widgets, State classes and test doubles. Enums and
   mixins also get their own files. Functions/constants can have focused files;
   public package entrypoints only export their supported API.
2. Name folders after business/protocol contexts. Within a context, use models,
   contracts, repositories, services, viewmodels, viewports, widgets, forms or
   modals when those roles exist. Do not add empty directories as architecture.
3. Use early returns for cancellation, invalid input, unavailable capabilities,
   stale sessions and completed work. Do not wrap the happy path inside a positive
   condition or follow a returning guard with an else branch.
4. Keep executable control-flow blocks at no more than two nested levels inside
   methods. Extract a named operation when a loop, try block, callback, or condition
   makes a sequence harder to follow. Keep widget constructor trees shallow by
   naming their visual sections and extracting context widgets.
5. A method should describe one operation. A session coordinator may call named
   steps such as open, authorize, resolve, observe and close rather than implementing
   every step in one large try block. Prefer explicit domain names to abbreviations.
6. Inject narrow collaborators. Volume commands use a command channel; navigation
   uses a pointer connection. Domain profile services depend on a repository
   contract, and data code implements it. Do not pass the whole device owner just
   to reach private fields or nest a chain of unrelated collaborators.
7. Keep mutation and resource ownership localized. Pending requests own their
   completion/deadline; subscriptions own their stream/deadline/unsubscribe;
   device sessions own subscriptions and disposal. Use immutable values and
   defensive collection copies where appropriate.
8. Apply DDD and object-calisthenics principles where they clarify this system.
   Do not mechanically wrap every string or collection, remove useful getters,
   or introduce pass-through classes without a concrete responsibility.

For example, flatten a cancellation path:

```dart
if (!isCurrentSession) {
  return;
}
await saveAuthorization();
await resolveCapabilities();
```

Prefer a screen assembled from named components to a long nested widget literal:

```dart
ContentPage(children: [
  RemoteHeader(model: model),
  NavigationPad(model: model),
  VolumeCard(model: model),
  ApplicationInputActions(model: model),
]);
```

## Enforcement

Run from the repository root:

```sh
dart run tool/check_structure.dart
dart analyze
dart test test packages/remote_core/test packages/remote_network/test packages/remote_driver_runtime/test packages/remote_driver_manager/test
```

The SDK-only structure check enforces one type per file outside the grouped
core contracts, detects control-flow blocks
nested beyond two levels and else branches in production library code, and checks
pure-Dart/domain dependency directions. It masks comments/string literals before
structural checks. It is a lightweight lexical guard, not a full semantic parser
or proof of DDD quality. Dart analysis and review remain necessary. Test setup and
assertion bodies are exempt from control-flow depth limits; test doubles still
follow one type per file.

CI also checks formatting, dependency provenance/pins, widget regressions, and an
Android debug build. No additional analyzer/lint dependency was introduced: the
attempt to declare analyzer directly was rejected by automatic approval review,
so the persisted structure tool uses only Dart SDK libraries.
