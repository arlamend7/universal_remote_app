/// Removes comments and string contents while preserving source positions.
/// This is a lexical structure check, not a replacement for Dart analysis.
final class DartSourceSanitizer {
  String mask(String source) {
    final result = StringBuffer();
    var index = 0;
    while (index < source.length) {
      final end = _ignoredEnd(source, index);
      if (end == index) {
        result.write(source[index]);
        index++;
        continue;
      }
      result.write(
        source.substring(index, end).replaceAll(RegExp(r'[^\n]'), ' '),
      );
      index = end;
    }
    return result.toString();
  }

  int _ignoredEnd(String source, int index) {
    if (source.startsWith('//', index)) {
      return _lineEnd(source, index);
    }
    if (source.startsWith('/*', index)) {
      return _commentEnd(source, index);
    }
    if (source[index] == "'" || source[index] == '"') {
      return _stringEnd(source, index);
    }
    return index;
  }

  int _lineEnd(String source, int index) {
    final end = source.indexOf('\n', index);
    return end < 0 ? source.length : end;
  }

  int _commentEnd(String source, int start) {
    var depth = 1;
    var index = start + 2;
    while (index < source.length && depth > 0) {
      if (source.startsWith('/*', index)) {
        depth++;
        index += 2;
        continue;
      }
      if (source.startsWith('*/', index)) {
        depth--;
        index += 2;
        continue;
      }
      index++;
    }
    return index;
  }

  int _stringEnd(String source, int start) {
    final quote = source[start];
    final delimiter = source.startsWith(quote * 3, start) ? quote * 3 : quote;
    var index = start + delimiter.length;
    while (index < source.length) {
      if (source[index] == r'\') {
        index += 2;
        continue;
      }
      if (source.startsWith(delimiter, index)) {
        return index + delimiter.length;
      }
      index++;
    }
    return source.length;
  }
}
