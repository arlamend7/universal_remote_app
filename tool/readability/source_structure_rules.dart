import 'dart_source_sanitizer.dart';

/// Checks the user's structural rules without introducing a lint package.
final class SourceStructureRules {
  static const _control = {
    'if',
    'for',
    'while',
    'do',
    'try',
    'catch',
    'finally',
    'switch',
  };
  static const _groupedCoreContracts = {
    'packages/remote_core/lib/src/remote_base.dart',
    'packages/remote_core/lib/src/tv_remote_base.dart',
    'packages/remote_core/lib/src/ac_remote_base.dart',
    'packages/remote_core/lib/src/device.dart',
    'packages/remote_core/lib/src/provider.dart',
    'packages/remote_core/lib/src/discovery.dart',
  };
  static final _tokens = RegExp(r'[a-zA-Z_$][\w$]*|[{}();]');
  List<String> inspect(String path, String source) {
    final masked = DartSourceSanitizer().mask(source);
    final issues = <String>[];
    final types = RegExp(r'\b(?:class|enum|mixin)\s+\w+').allMatches(masked);
    if (types.length > 1 && !_groupedCoreContracts.contains(path)) {
      issues.add('$path: declare only one class, enum, or mixin per file.');
    }
    if (!path.contains('/lib/')) {
      return issues;
    }
    issues.addAll(_controlFlow(path, masked));
    issues.addAll(_boundaries(path, source));
    issues.addAll(_providerIds(path, source));
    return issues;
  }

  /// Provider IDs belong in driver data; generic library code must not
  /// branch on them. Protocol engines may name their own protocol only.
  static final _providerId = RegExp(
    r'''['"](lg\.webos|android\.tv|samsung\.tizen|roku\.ecp)['"]''',
  );

  List<String> _providerIds(String path, String source) {
    if (path.contains('/test/') ||
        path.startsWith('packages/remote_driver_runtime/lib/src/engines/')) {
      return const [];
    }
    return [
      for (final match in _providerId.allMatches(source))
        _location(
          path,
          source,
          match.start,
          'provider ID ${match.group(1)} belongs in driver data, not code.',
        ),
    ];
  }

  List<String> _controlFlow(String path, String source) {
    final issues = <String>[];
    final parentheses = <String>[];
    final blocks = <bool>[];
    var previous = '';
    var closedOwner = '';
    for (final token in _tokens.allMatches(source)) {
      final value = token.group(0)!;
      if (value == 'else') {
        issues.add(
          _location(
            path,
            source,
            token.start,
            'use an early return instead of else.',
          ),
        );
      }
      if (value == '(') {
        parentheses.add(previous);
      }
      if (value == ')' && parentheses.isNotEmpty) {
        closedOwner = parentheses.removeLast();
      }
      if (value == '{') {
        blocks.add(_control.contains(previous == ')' ? closedOwner : previous));
        _checkDepth(path, source, token.start, blocks, issues);
      }
      if (value == '}' && blocks.isNotEmpty) {
        blocks.removeLast();
      }
      previous = value;
    }
    return issues;
  }

  void _checkDepth(
    String path,
    String source,
    int offset,
    List<bool> blocks,
    List<String> issues,
  ) {
    if (blocks.where((control) => control).length <= 2) {
      return;
    }
    issues.add(
      _location(
        path,
        source,
        offset,
        'extract an operation; control-flow nesting exceeds two levels.',
      ),
    );
  }

  List<String> _boundaries(String path, String source) {
    final imports = RegExp("import ['\"]([^'\"]+)['\"]")
        .allMatches(source)
        .map((match) => match[1]!);
    final forbidden = imports
        .where((uri) => _forbiddenImport(path, uri))
        .toList();
    return forbidden
        .map((uri) => '$path: invalid dependency direction: $uri')
        .toList();
  }

  bool _forbiddenImport(String path, String uri) {
    if (path.startsWith('packages/')) {
      if (uri.startsWith('package:universal_remote_app/')) {
        return true;
      }
      if (path.startsWith('packages/remote_ui/')) {
        // Element definitions own icon and reading metadata; feedback owns
        // haptic cues. Widgets still own rendering.
        if (uri.startsWith('package:flutter') &&
            (path.startsWith('packages/remote_ui/lib/src/elements/') ||
                path.startsWith('packages/remote_ui/lib/src/items/') ||
                path.startsWith('packages/remote_ui/lib/src/feedback/'))) {
          return false;
        }
        return uri.startsWith('package:flutter') &&
            !path.startsWith('packages/remote_ui/lib/src/widgets/') &&
            !path.startsWith('packages/remote_ui/lib/src/editor/') &&
            !path.startsWith('packages/remote_ui/lib/src/catalog/') &&
            !path.startsWith('packages/remote_ui/lib/src/rendering/') &&
            !path.startsWith('packages/remote_ui/lib/src/host/');
      }
      return uri.startsWith('package:flutter') ||
          uri.startsWith('package:remote_ui/');
    }
    if (!path.contains('/domains/')) {
      return false;
    }
    return uri.contains('/data/') || uri.contains('/presentation/');
  }

  String _location(String path, String source, int offset, String message) =>
      '$path:${'\n'.allMatches(source.substring(0, offset)).length + 1}: $message';
}
