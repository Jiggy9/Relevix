enum InterpolationMethod {
  exact,
  interpolated,
  averaged,
  nearest,
}

class InterpolationResult {
  final double value;
  final InterpolationMethod method;
  final String description;

  const InterpolationResult({
    required this.value,
    required this.method,
    this.description = '',
  });

  String get methodLabel {
    switch (method) {
      case InterpolationMethod.exact:
        return 'Exact Match';
      case InterpolationMethod.interpolated:
        return 'Interpolated';
      case InterpolationMethod.averaged:
        return 'Averaged';
      case InterpolationMethod.nearest:
        return 'Nearest Value';
    }
  }

  @override
  String toString() =>
      'InterpolationResult(value: $value, method: $methodLabel)';
}
