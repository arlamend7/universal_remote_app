final _threeParts = RegExp(r'^[0-9]{1,4}\.[0-9]{1,4}\.[0-9]{1,4}$');

/// Compare only the three numeric fields reported for this platform value.
int? compareThreePartDeviceVersion(String left, String right) {
  if (!_threeParts.hasMatch(left) || !_threeParts.hasMatch(right)) {
    return null;
  }
  final lhs = left.split('.').map(int.parse).toList();
  final rhs = right.split('.').map(int.parse).toList();
  for (var index = 0; index < lhs.length; index++) {
    final difference = lhs[index].compareTo(rhs[index]);
    if (difference != 0) {
      return difference;
    }
  }
  return 0;
}
