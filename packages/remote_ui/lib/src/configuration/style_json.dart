/// Validates one stored ARGB color; anything out of range is dropped.
int? parseStyleColor(Object? value) =>
    value is int && value >= 0 && value <= 0xffffffff ? value : null;

/// Validates one stored number and clamps it to [min]..[max].
double parseStyleNumber(
  Object? value,
  double min,
  double max,
  double fallback,
) => value is num && value.isFinite
    ? value.toDouble().clamp(min, max)
    : fallback;
